defmodule Client do
  @client :tg_client

  @doc """
    Connect to the game server
  """
  def join do
    GenServer.call(@client, :connect)
  end

  @doc """
    Disconnect from the game server
  """
  def leave do
    GenServer.call(@client, :leave)
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

  def hint do
    GenServer.cast(@client, :hint)
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
