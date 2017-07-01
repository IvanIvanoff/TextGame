defmodule Server.Worker do
  use GenServer

  defmodule Game do
    defstruct states: [], players: %{}, ranking: %{}
  end

  def start_link(name) do
    GenServer.start_link(__MODULE__, nil, {:global, name})
  end

  def init(states) do
    {:ok, %Game{states: states}}
  end

  def join(name) do
    GenServer.call(__MODULE__, {:join, name})
  end

  def leave(name) do
    GenServer.call(__MODULE__, {:leave, name})
  end

  def name_taken?(name) do
    GenServer.call(__MODULE__, {:name_taken, name})
  end

  def ranking() do
    GenServer.call(__MODULE__, :ranking)
  end

  def send(name, message) do
    GenServer.cast(__MODULE__, {:send_message, name, message})
  end

  #########################

  def handle_call(
                  {:join, name}, {from, _},
                  %Game{players: players, ranking: ranking} = state) do
    case Map.has_key?(players, name) do
      true ->
        {:reply, :name_taken, state}
      false ->
        players = Map.put(players, name, node(from))
        ranking = Map.put(ranking, name, 0)
        {:reply, :successful_join, %Game{ state | players: players, ranking: ranking}}
    end
  end

  def handle_call({:leave, name}, {from, _}, %Game{players: players} = state) do
    case Map.has_key?(players, name) &&
    node(from) == Map.get(players, name) do
      true ->
        new_players = Map.delete(players, name)
        {:reply, :left, %Game{state | players: new_players}}
      false ->
        {:reply, :not_joined, state}
      end
  end

  def handle_call({:name_taken, name}, {from, _}, %Game{players: players} = state) do
    case Map.has_key?(players, name) &&
    node(from) == Map.get(players, name) do
      true ->
        {:reply, :taken, state}
      false ->
        {:reply, :not_taken, state}
      end
  end

  def handle_cast(
    {:send_message, name, message},
    %Game{ players: players,
           states: [{_, answer}|rest],
           ranking: ranking} = state) do

    # send the message to all players
    broadcast(Map.delete(players, name), name, message)

    case message == answer do
      true ->
        # Broadcast that the right answer is received
        broadcast(players, self(), "User #{name} gave the right answer '#{answer}'!")
        player_rank = Map.get(ranking, name)
        ranking = Map.put(ranking, name, player_rank+1)

        # Get the new question
        [{new_question, _}|_] = rest

        # Broadcast the new question
        broadcast(players, self(), "The new question is: '$#{new_question}'")

        {:noreply, %Game{state | ranking: ranking, states: rest}}
      false ->
        # send only to user if the answer is 'similar' to the desired one
        # what I define as 'similar' is another topic.
        if Levenstein.are_similar?( message, answer ) do
          {_, registered_node} = Map.get(players, name)
           send_message(registered_node, self(), "Your answer is close! Try again!")
        end

        {:noreply, state}
      end
  end

  ##################################################

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
    GenServer.cast({:tg_client, registered_node}, {:new_message, from, message})
  end
end
