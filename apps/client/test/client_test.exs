defmodule ClientTest do
  use ExUnit.Case

  @server_name Application.get_env(:server, :server_name, :test_tg_server)

  setup do
    game_states = [{"What is the capital of Bulgaria?", "Sofia",["Begins with S"]},
                   {"What is three times three minus 8", "1",[]},
                   {"Who let the dogs out", "who",[]}]

    {:ok, server_pid} = Server.Worker.start_link(@server_name, game_states)
    {:ok, client_pid} = Client.Worker.start_link("Pesho")
    {:ok, process: server_pid}
  end

  test "Test Server.Worker gives hint" do
    GenServer.call({:global, @server_name}, {:join, "Pesho"})
    Client.send("Sofia")

    ranking = Client.ranking
    IO.inspect ranking
    assert [{"Pesho", 1}] == ranking
    #assert_receive({:new_message,_,msg}, 2_000)
  end

  test "Test Client can join" do
     #{:ok, client_pid} = Client.Worker.start_link("Pesho")
  end
end
