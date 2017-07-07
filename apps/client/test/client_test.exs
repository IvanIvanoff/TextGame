defmodule ClientTest do
  use ExUnit.Case

  @server_name :tg_server
  setup do
    game_states = [{"What is the capital of Bulgaria?", "Sofia",["Begins with S"]},
                   {"What is three times three minus 8", "1",[]},
                   {"Who let the dogs out", "who",[]}]

    {:ok, server_pid} = Server.Worker.start_link(:"tg_server", game_states)

    {:ok, client_pid} = Client.Worker.start_link
    {:ok, process: server_pid}
  end

  test "Test Server.Worker gives hint" do
     GenServer.cast({:global, @server_name}, :hint)
  end
end
