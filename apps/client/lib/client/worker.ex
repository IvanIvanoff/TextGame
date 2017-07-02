defmodule Client.Worker do
  use GenServer

  @server_name Application.get_env(:client, :server_name, :tg_server)
  @reconnect_timeout Application.get_env(:client, :reconnect_timeout, 5000)

  def start_link(nick, name) do
    GenServer.start_link(__MODULE__, nick, name: name)
  end

  def init(nick) do
    {:ok, %{nick: nick, connection_ref: nil}}
  end

  def handle_info({:DOWN, _, _, _, _}, %{connection_ref: nil} = state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, _, _,  _}, %{connection_ref: ref} = state) do
    {:noreply, retry_connect(state)}
  end

  def handle_info(:try_connect, %{connection_ref: nil} = state) do
    {:noreply, state}
  end

  def handle_info(:try_connect, state) do
    {:noreply, retry_connect(state)}
  end

  def handle_call(:connect, _from, state) do
    connect_to_server(state)
  end

  def handle_call(:leave, _, %{nick: nick, connection_ref: nil} = state) do
    reply = GenServer.call({:global, @server_name}, {:leave, nick})
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
        {:connected, _} ->
          ref = Process.monitor(:global.whereis_name(@server_name))
          %{state | connection_ref: ref}
        _ -> state
      end

    {:reply, reply, new_state}
  end

  defp retry_connect(%{connection_ref: nil} = state), do: state

  defp retry_connect(state) do
    case connect_to_server(state) do
      {_, {:connected, _}, new_state} ->
        IO.puts("Connected to server.")
        new_state
      _ ->
        IO.puts("Server down, diconnected. Trying to connect...")
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
