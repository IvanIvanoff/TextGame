defmodule Client.Worker do
  use GenServer
  require Logger

  @server_name Application.get_env(:client, :server_name, :tg_server)
  @reconnect_timeout Application.get_env(:client, :reconnect_timeout, 5000)

  def start_link(name, client_name \\ :tg_client) do
    GenServer.start_link(__MODULE__, name, name: client_name)
  end

  @doc """
    Returns the initial state of the client. It contains ref for the connection
  """
  def init(nick) do
    Logger.info("Client.Worker initializing")
    state = %{nick: nick, connection_ref: nil}
    case connect_to_server(state) do
      {:successful_join, new_state} -> {:ok, new_state}
       err -> err
    end
  end

  @doc """
    Do not crash. Process is monitored and :DOWN is received when it stops.
    TODO: Remove player from players, but not from ranking!
  """
  def handle_info({:DOWN, _ref, _process, _pid, _reason}, %{connection_ref: nil} = state) do
    Logger.info "MAN OVERBOARD"
    {:noreply, state}
  end

  @doc """
    The server, pointed to by ref, is down, try to reconnect
  """
  def handle_info({:DOWN, ref, _process, _pid,  _reason}, %{connection_ref: ref} = state) do
    Logger.info "MAN OVERBOARD.... I'LL BACK"
    {:noreply, try_reconnect(state)}
  end

  @doc """
    Try to connect to a server, but connection_ref IS nil. Call connect_to_server which
    will locate and connect to a game server
  """
  def handle_info(:try_reconnect, %{connection_ref: nil} = state) do
    {:successful_join, new_state} = connect_to_server(state)
    {:noreply, new_state}
  end

  @doc """
    Try to connect to server when connection_ref is NOT nil. Just call try_reconnect
  """
  def handle_info(:try_reconnect, state) do
    IO.puts "Trying to reconnect..."
    {:noreply, try_reconnect(state)}
  end

  @doc """
    Handle unexpected messages by just printing and ignoring them.
  """
  def handle_info(_msg, state) do
    Logger.info "Unknown message received. Ignoring it."
    {:noreply, state}
  end

  @doc """
    Connect to game server
  """
  def handle_call(:connect, _from, state) do
    {:successful_join, new_state} = connect_to_server(state)
    {:reply, :successful_join, new_state}
  end

  @doc """
    Queries about the current ranking in sorted order
  """
  def handle_call(:ranking, _, state) do
     reply = GenServer.call({:global, @server_name}, :ranking)
     {:reply, reply, state}
  end

  @doc """
    Leave the game room
  """
  def handle_call(:leave, _, %{nick: nick, connection_ref: nil} = state) do
    reply = GenServer.call({:global, @server_name}, {:leave, nick})
    {:reply, reply, state}
  end

  @doc """
    Leave the game room
  """
  def handle_call(:leave, _, %{nick: nick, connection_ref: ref} = state) do
    reply = GenServer.call({:global, @server_name}, {:leave, nick})
    Process.demonitor(ref)

    {:reply, reply, %{state | connection_ref: nil}}
  end

  @doc """
    Queries what is the current question
  """
  def handle_call(:get_question, _from, state) do
    reply = GenServer.call({:global, @server_name}, :get_question)

    {:reply, reply, state}
  end

  @doc """
    Queries a list of all players
  """
  def handle_call(:list_players, _from, state) do
    reply = GenServer.call({:global, @server_name}, :list_players)

    {:reply, reply, state}
  end

  @doc """
    Sends a message to the server
  """
  def handle_cast({:send_message, message}, %{nick: nick} = state) do
    GenServer.cast({:global, @server_name}, {:send_message, nick, message})

    {:noreply, state}
  end

  @doc """
    Queries the server about a hint, if any
  """
  def handle_cast(:hint, state) do
    GenServer.cast({:global, @server_name}, :hint)
    {:noreply, state}
  end

  @doc """
    Puts new messages to the screen
  """
  def handle_cast({:new_message, nick_name, message}, state) do
    IO.write(IO.ANSI.red())
    IO.puts("\n#{nick_name}> #{message}")
    IO.write(IO.ANSI.reset())

    {:noreply, state}
  end

  def terminate(reason, %{nick: nick}) do
    GenServer.call({:global, @server_name}, {:leave, nick})
    reason
  end

  ##############################
  ########## PRIVATE ###########
  ##############################

  defp connect_to_server(%{nick: nick} = state) do
    Logger.info("Connecting to server #{@server_name}")
    Process.sleep(1000) #testing purposes
    Client.Connectivity.connect_to_server_node()

    # Synchronizes the global name server with all nodes known to this node.
    # These are the nodes that are returned from erlang:nodes().
    # When this function returns, the global name server receives global information
    # from all nodes. This function can be called when new nodes are added to the network.
    :global.sync()

    reply =
      case :global.whereis_name(@server_name) do
        :undefined -> :server_unreachable
        pid when is_pid(pid) ->
          case server_alive?(pid) do
            true ->
              Logger.info("Server is alive")
              GenServer.call({:global, @server_name}, {:join, nick})
            false ->
              Logger.info("Server is not alive")
              :server_unreachable
          end
      end

    new_state =
      case reply do
        :successful_join ->
          ref = Process.monitor(:global.whereis_name(@server_name))
          %{state | connection_ref: ref}
        _ -> state
      end

  {reply, new_state}
  end

  defp try_reconnect(%{connection_ref: nil} = state), do: state

  defp try_reconnect(state) do
    Logger.info("Try reconnect")
    case connect_to_server(state) do
      {:successful_join, new_state} ->
        IO.puts("Connected to server.")
        new_state
      _ ->
        IO.puts("Unsuccessful connect. Trying to connect again...")
        Process.send_after(self(), :try_reconnect, @reconnect_timeout)
        state
    end
  end

  defp server_alive?(pid) do
    case Node.alive? do
      true ->
        {responses, _} = :rpc.multicall(Node.list(), Process, :alive?, [pid])
        responses |> Enum.any?(&(&1 == true))
      false -> Process.alive?(pid)
    end
  end
end
