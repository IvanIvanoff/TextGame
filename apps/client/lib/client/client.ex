defmodule Client do
  @client :tg_client

  @doc """
    Connect to the game server
  """
  @spec question?() :: :successful_join | :name_taken
  def join() do
    GenServer.call(@client, :connect)
  end

  @doc """
    Disconnect from the game server
  """
  @spec leave() :: :not_joined | :successful_leave
  def leave() do
    GenServer.call(@client, :leave)
  end

  @doc """
    Query the current question.
  """
  @spec question?() :: bitstring()
  def question?() do
    GenServer.call(@client, :get_question)
  end

  @doc """
    Query the current score ranking.
  """
  @spec ranking() :: iodata()
  def ranking() do
    list = GenServer.call(@client, :ranking)
    IO.puts(IO.ANSI.blue())
    IO.puts("Ranking of all players that has played in this game:")
    IO.puts(IO.ANSI.green())
    list |> Enum.each(&print_tuple/1)
    IO.puts(IO.ANSI.reset())
  end

  @doc """
    Query a hint about the current question.
  """
  @spec hint() :: :ok
  def hint() do
    GenServer.cast(@client, :hint)
  end

  @doc """
    Display all players in the current game
  """
  @spec list_players() :: iodata()
  def list_players() do
    list = GenServer.call(@client, :list_players)

    IO.puts(IO.ANSI.blue())
    IO.puts("Players in the game:")
    IO.puts(IO.ANSI.green())
    list |> Enum.each(&IO.puts/1)
    IO.puts(IO.ANSI.reset())
  end

  @doc """
    Send a message to all players. If the message matches the answer to the
    current question, points are awarded to the sender.
  """
  @spec send(bitstring()) :: :ok
  def send(message) do
    GenServer.cast(@client, {:send_message, message})
  end

  ##############################
  ########## PRIVATE ###########
  ##############################

  defp print_tuple({name, score}) do
    IO.puts( "#{name} : #{score}")
  end
end
