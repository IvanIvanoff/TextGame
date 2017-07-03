defmodule Client do
  @client :tg_client

  def lift() do
    server_name = System.get_env("TG_SERVER_NAME") || "tg_server"
    server_location = System.get_env("TG_SERVER_LOCATION") || "127.0.0.1"

    Client.Application.start(nil, [server_name, server_location])
    Process.sleep(500)
    connect()
  end

  @doc """
    Connect to the game server
  """
  def connect do
    GenServer.call(@client, :connect)
  end

  @doc """
    Disconnect from the game server
  """
  def disconnect do
    GenServer.call(@client, :disconnect)
  end

  @doc """
    Query the current question.
  """
  def question? do
    GenServer.call(@client, :get_question)
  end

  @doc """
    Query the current score ranking.
  """
  def ranking do
    GenServer.call(@client, :ranking)
  end

  @doc """
    Display all players in the current game
  """
  def list_players do
    list = GenServer.call(@client, :list_players)

    IO.puts("Players in the game:")
    IO.puts(IO.ANSI.green())
    list |> Enum.each(&IO.puts/1)
    IO.puts(IO.ANSI.reset())
  end

  @doc """
    Send a message to all players
  """
  def send(message) do
    GenServer.cast(@client, {:send_message, message})
  end
end
