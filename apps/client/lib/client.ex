defmodule Client do
  use Application

  def start(_type, [server_location]) do
    with name when not is_nil(name) <- Client.Connectivity.name(),
    true <- Client.Connectivity.connect_to_server_node(server_location) do
      start_client(name)
    else
      _ -> {:error, "Can't connect to server or establish client."}
    end
  end

  def lift() do
    start(nil, ["127.0.0.1"])
    Process.sleep(500)
    connect()
  end

  def connect do
    GenServer.call(:tg_client, :connect)
  end

  def disconnect do
    GenServer.call(:tg_client, :disconnect)
  end

  def question? do
    GenServer.call(:tg_client, :get_question)
  end

  def ranking do
    GenServer.call(:tg_client, :ranking) 
  end

  def list_players do
    list = GenServer.call(:tg_client, :list_players)

    IO.puts("tgs online:")
    IO.puts(IO.ANSI.green())
    list |> Enum.each(&IO.puts/1)
    IO.puts(IO.ANSI.reset())
  end

  def msg(message) do
    GenServer.cast(:tg_client, {:send_message, message})
  end

  defp start_client(nick) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Client.Worker, [nick, :tg_client])
    ]

    opts = [strategy: :one_for_one, name: Client.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
