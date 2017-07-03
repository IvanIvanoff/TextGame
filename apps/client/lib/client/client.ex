defmodule Client do
  def lift() do
    Client.Application.start(nil, ["127.0.0.1"])
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
end
