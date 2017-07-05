defmodule ServerTest do
  use ExUnit.Case, async: false

  @server_name :tg_server
  setup do
    game_states = [{"What is the capital of Bulgaria?", "Sofia",[]},
                   {"What is three times three minus 8", "1",[]},
                   {"Who let the dogs out", "who",[]}]

    {:ok, server_pid} = Server.Worker.start_link(:"tg_server", game_states)

    {:ok, process: server_pid}
  end

  test "Test levenstein distance 0" do
    assert 0 == Levenstein.distance("Sample string", "Sample string")
  end

  test "Test levenstein distance not 0" do
    assert 0 != Levenstein.distance("Sample", "String")
  end

  test "Test levenstein distance exactly with empty string" do
    assert 5 == Levenstein.distance("abcde", "")
  end

  test "Test levenstein distance with non-empty strigs" do
    assert 4 == Levenstein.distance("Kircho", "Petarcho")
  end

  test "Test two strings are similiar" do
    assert false == Levenstein.are_similar?("Some string", "")
    assert true  == Levenstein.are_similar?(
      "Soffia",
      "Sofia")
  end

  test "Test Server.Worker ranking no players" do
    reply = GenServer.call({:global, @server_name}, :ranking)
    assert reply == []
  end

  test "Test Server.Worker ranking with players" do
    GenServer.call({:global, @server_name}, {:join, "Pesho"})

    assert [{"Pesho", 0}] == GenServer.call({:global, @server_name}, :ranking)
  end

  test "Test can join a game" do
    assert [] == GenServer.call({:global, @server_name}, :list_players)
    GenServer.call({:global, @server_name}, {:join, "Pesho"})
    assert ["Pesho"] == GenServer.call({:global, @server_name}, :list_players)

    GenServer.call({:global, @server_name}, {:join, "Zorro"})
    assert ["Pesho", "Zorro"] == GenServer.call({:global, @server_name}, :list_players)
  end

  test "Test can leave a game" do
    assert [] == GenServer.call({:global, @server_name}, :list_players)
    GenServer.call({:global, @server_name}, {:join, "Pesho"})
    GenServer.call({:global, @server_name}, {:leave, "Pesho"})
    assert [] == GenServer.call({:global, @server_name}, :list_players)
  end

  test "Test parser" do
    expected = [{"Ivan", "mn", ["tap"]},{"huehue","hue", []}]
    string = "{Ivan, mn, [tap]}, {huehue, hue, []}"
    assert expected == Parser.parse(string)
  end
end
