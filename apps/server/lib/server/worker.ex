defmodule Server.Worker do
  use GenServer
  require Logger

  @client :tg_client

  defmodule Game do
    defstruct states: [], players: %{}, ranking: %{}
  end

  @doc """
    Start supervisor
  """
  @spec start_link(bitstring(), list() ) :: GenServer.on_start
  def start_link(name, states) do
    GenServer.start_link(__MODULE__, states, name: {:global, name})
  end

  @doc """
    Initiate the game with the given states
  """
  def init(states \\ []) do
    {:ok, %Game{states: states}}
  end

  #########################

  def handle_info({:DOWN, _ref, _process, _pid,  _reason}, state) do
    Logger.info("Somebody left the game")
    #%Game{players: players} = state
    #IO.inspect  players |> Enum.find( fn{_key,value} -> value == node(pid) end) |> hd

    #{name,_} = players |> Enum.find( fn{_key,value} -> value == node(ref) end) |> hd
    #IO.inspect name
    #new_players = Map.delete(players, name)
    #{:noreply, %Game{state|players: new_players}}
    {:noreply, state}
  end

  @doc """
    Returns sorted list of tuples. Each tuple contains a player's name and its score.
    The list is sorted by the score.
  """
  def handle_call(:ranking, _, %Game{ranking: ranking} = state) do
    {:reply, sort_ranking(ranking), state}
  end

  @doc """
    Returns the current question, if any.
  """
  def handle_call(:get_question, _, %Game{states: []} = state) do
    {:reply, "No more questions", state}
  end

  @doc """
    Returns the current question, if any.
  """
  def handle_call(:get_question, _, %Game{states: [{question,_,_}|_]} = state) do
    {:reply, question, state}
  end

  @doc """
    Returns a list of the players' names
  """
  def handle_call(:list_players, _, %Game{players: players} = state) do
    list_players =
      Map.to_list(players)
      |> Enum.map( fn {x,_} -> x end )

    {:reply, list_players, state}
  end

  @doc """
    Returns string representation of the process' state
  """
  def handle_call(:state?, _, state) do
    st = IO.inspect state
    {:reply, st, state}
  end

  @doc """
    Adds a new player to the players map.
    If the name is already used, :name_taken atom is returned
    If the name is not taken, the player is added with 0 score and the current
    question is sent only to him or her. The atom :successful_join is returned
  """
  def handle_call({:join, name}, {from, _ref},
                  %Game{ players: players,
                         ranking: ranking,
                         states: [{question,_,_}|_]} = state) do
    node_from = node(from)

    # Receive :DOWN when the process dies.
    Process.monitor(from)

    # Handles the case that ate my time. When client's process was restarted nobody sent
    # :leave so when he or she tried to connect again :name_taken was returned
    case Map.has_key?(players, name) do
      true ->
        case Map.get(players,name) do
          ^node_from -> {:reply, :successful_join, state}
          _ -> {:reply, :name_taken, state}
        end

      false ->
        Logger.info( " Player #{name} has joined the game!" )
        players = Map.put(players, name, node_from)

        # Save the result of a player. If there exist such record do not override it
        if !Map.has_key?(ranking, name) do
          ranking = Map.put(ranking,name,0)
        end

        send_message(node(from), "GameServer", question)
        {:reply, :successful_join, %Game{ state | players: players, ranking: ranking}}
    end
  end

  # TODO: Add check so other host cannot disconnect another person
  @doc """
    Disconnects the player with the given name.
    If there is no such player, the atom :not_joined is returned
    Otherwise the player is deleted from the players' map and the atom :successful_leave
    is returned
  """
  def handle_call({:leave, name}, {from, _},
                  %Game{players: players,
                        ranking: ranking} = state) do
    case Map.has_key?(players, name) &&
    node(from) == Map.get(players, name) do
      true ->
        Logger.info( "Player #{name} has left the game!" )
        players = Map.delete(players, name)
        ranking = Map.delete(ranking, name)
        {:reply, :successful_leave, %Game{state | players: players, ranking: ranking}}
      false ->
        {:reply, :not_joined, state}
      end
  end

  @doc """
    Query if a given name is taken. Returns atoms :taken or :not_taken
  """
  def handle_call({:name_taken, name},
                  {from, _},
                  %Game{players: players} = state) do
    case Map.has_key?(players, name) &&
    node(from) == Map.get(players, name) do
      true ->
        {:reply, :taken, state}
      false ->
        {:reply, :not_taken, state}
      end
  end

  @doc """
    When the game states is a empty list, send_message only broadcasts the message
    to all active players.
  """
  def handle_cast( {:send_message, name, message},
                   %Game{ players: players,
                          states: []} = state) do
    broadcast(players, name, message)
    {:noreply, state}
  end

  @doc """
    Sends a message to all players, including the sender.
    Check if the message matches the answer to the question. If so so - a point is
    given to the player and the new question is broadcasted.

    Levenstein distance is used to check if the message is close to the real answer.
    If so, a message is sent only to the player, saying to him that he is close to
    the right answer.
  """
  def handle_cast( {:send_message, name, message},
                   %Game{ players: players,
                          states: [{_, answer, _}|rest],
                          ranking: ranking} = state) do

    Logger.info( "Player #{name} says '#{message}'")

    # send the message to all players
    broadcast(players, name, message)

    case message == answer do
      true ->
        # Broadcast that the right answer is received
        broadcast(players, "GameServer", "User #{name} gave the right answer '#{answer}'!")
        player_rank = Map.get(ranking, name)
        ranking = Map.put(ranking, name, player_rank+1)

        case length(rest) do
          0 ->
            IO.inspect get_winner(ranking)
            winner="Ivan"
            score=5
            broadcast(players, "GameServer", "The game is over! Winner is: #{winner} with score #{score} ")
            {:noreply, %Game{state | ranking: ranking, states: []}}
          _ ->
            # Get the new question
            [{new_question, _,_}|_] = rest

            # Broadcast the new question
            broadcast(players, "GameServer", "The new question is: '#{new_question}'")

            {:noreply, %Game{state | ranking: ranking, states: rest}}
        end
      false ->
        # send only to user if the answer is 'similar' to the desired one
        if Levenstein.are_similar?( message, answer ) do
          registered_node = Map.get(players, name)
          send_message(registered_node, "GameServer", "Your answer is close! Try again!")
        end

        {:noreply, state}
      end
  end

  @doc """
    Broadcast a hint regarding the current question, if any, to all active players
  """
  def handle_cast(:hint,
                  %Game{states: [{_,_,[]}|_],
                        players: players} = state) do

     broadcast(players, "GameServer", "There are no hints!")
     {:noreply, state}
  end

  @doc """
    Broadcast a hint regarding the current question, if any, to all active players
  """
  def handle_cast(:hint,
                  %Game{states: [{question,answer,[hint|hints]}|rest],
                        players: players} = state) do

     broadcast(players, "GameServer", "Hint: " <> hint)
     {:noreply, %Game{state | states: [{question,answer, hints}|rest]}}
  end

  ##############################
  ########## PRIVATE ###########
  ##############################

  defp broadcast(receivers, from, message) do
    receivers
    |> Enum.map( fn {_, registered_node} ->
      Task.async(fn ->
        send_message(registered_node, from, message)
      end)
    end)
    |> Enum.map(&Task.await/1)
  end

  defp send_message(registered_node, from, message) do
    GenServer.cast({@client, registered_node}, {:new_message, from, to_string(message) })
  end

  defp get_winner(ranking) when is_map(ranking) do
    sort_ranking(ranking) |> hd
  end

  defp sort_ranking(ranking) do
    Map.to_list(ranking)
    |> Enum.sort(fn {_, x}, {_, y} -> x > y end)
  end
end
