defmodule Client.Worker do
  use GenServer
  require Logger

  @server_name Application.get_env(:client, :server_name, :tg_server)
  @reconnect_timeout Application.get_env(:client, :reconnect_timeout, 5000)

  def start_link(nick, name) do
    GenServer.start_link(__MODULE__, nick, name: name)
  end

  def init(nick) do
    state = %{nick: nick, connection_ref: nil}
    {:successful_join, new_state} = connect_to_server(state)
    {:ok, new_state}
  end

  def handle_info({:DOWN, _ref, _process, _pid, _reason}, %{connection_ref: nil} = state) do
    Logger.info "MAN OVERBOARD"
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, _process, _pid,  _reason}, %{connection_ref: ref} = state) do
    Logger.info "MAN OVERBOARD.... I'LL BACK"
    {:noreply, retry_connect(state)}
  end

  def handle_info(:try_connect, %{connection_ref: nil} = state) do
    {:noreply, state}
  end

  def handle_info(:try_connect, state) do
    IO.puts "Trying to reconnect..."
    {:noreply, retry_connect(state)}
  end

  def handle_info(_msg, state) do
    Logger.info "Unknown message received. Ignoring it."
    {:noreply, state}
  end

  def handle_call(:connect, _from, state) do
    {:successful_join, new_state} = connect_to_server(state)
    {:reply, :successful_join, new_state}
  end

  def handle_call(:leave, _, %{nick: nick, connection_ref: nil} = state) do
    reply = GenServer.call({:global, @server_name}, {:leave, nick})
    {:reply, reply, state}
  end

  def handle_call(:ranking, _, state) do
     reply = GenServer.call({:global, @server_name}, :ranking)
     {:reply, reply, state}
  end

  def handle_call(:leave, _, %{nick: nick, connection_ref: ref} = state) do
    reply = GenServer.call({:global, @server_name}, {:leave, nick})
    Process.demonitor(ref)

    {:reply, reply, %{state | connection_ref: nil}}
  end

  def handle_call(:get_question, _from, state) do
    reply = GenServer.call({:global, @server_name}, :get_question)

    {:reply, reply, state}
  end

  def handle_call(:list_players, _from, state) do
    reply = GenServer.call({:global, @server_name}, :list_players)

    {:reply, reply, state}
  end

  def handle_cast({:send_message, message}, %{nick: nick} = state) do
    GenServer.cast({:global, @server_name}, {:send_message, nick, message})

    {:noreply, state}
  end

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

  defp connect_to_server(%{nick: nick} = state) do
    Logger.info("Connecting to server #{@server_name}")

    Client.Connectivity.connect_to_server_node()
    :global.sync()

    reply =
      case :global.whereis_name(@server_name) do
        :undefined -> :server_unreachable
        pid when is_pid(pid) ->
          case server_alive?(pid) do
            true -> GenServer.call({:global, @server_name}, {:join, nick})
            false -> :server_unreachable
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

  defp retry_connect(%{connection_ref: nil} = state), do: state

  defp retry_connect(state) do
    case connect_to_server(state) do
      {:successful_join, new_state} ->
        IO.puts("Connected to server.")
        new_state
      _ ->
        IO.puts("Unsuccessful connect. Trying to connect again...")
        Process.send_after(self(), :try_connect, @reconnect_timeout)
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
