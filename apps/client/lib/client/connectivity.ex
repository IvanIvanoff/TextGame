defmodule Client.Connectivity do
  def name do
    case Node.alive? do
      true ->
        to_string(Node.self()) |> String.split("@") |> List.first
      false ->
        lift_client()
    end
  end

  def connect_to_server_node(server_location) do
    server_name = System.get_env("TG_SERVER_NAME") || "tg_server"

    Node.connect(:"#{server_name}@#{server_location}") ||
    Node.connect(:"#{server_name}_slave_one@#{server_location}") ||
    Node.connect(:"#{server_name}_slave_two@#{server_location}")
  end

  defp lift_client() do
    name = System.get_env("TG_CLIENT_NAME") || random_nick()
    location = System.get_env("TG_CLIENT_LOCATION") || "127.0.0.1"

    case Node.start(:"#{name}@#{location}") do
      {:ok, pid} when is_pid(pid) -> name
      _ -> nil
    end
  end

  defp random_nick do
    letters = ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

    (1..10)
    |> Enum.reduce([], fn(_, acc) -> [Enum.random(letters) | acc] end)
    |> Enum.join("")
  end
end
