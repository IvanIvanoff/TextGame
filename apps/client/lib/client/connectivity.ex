defmodule Client.Connectivity do
  require Logger

  @client_location Application.get_env(:client, :client_location, "127.0.0.1")

  @server_name Application.get_env(:client, :server_name, :tg_server)
  @server_location Application.get_env(:client, :server_location, "127.0.0.1")

  @doc """
    Returns the node name. If the node is alive, return the part before '@'
    If the node is not alive call lift_client() which checks the environment
    variables TG_CLIENT_NAME and TG_CLIENT_LOCATION. If they do not exist generate
    a random 5 letter name and use localhost as location
  """
  @spec name() :: nil | bitstring()
  def name() do
    case Node.alive? do
      true ->
        Logger.info("Node #{self()} is alive!")
        to_string(Node.self()) |> String.split("@") |> List.first
      false ->
        lift_client()
    end
  end

  @doc """
    Connect the Node to the server Node. The server is configurated by the
    environment variables TG_SERVER_NAME and TG_SERVER_LOCATION. If they are missing
    default values "tg_server" and "127.0.0.1" are used.

    Note that the default values for the server coincide with the default values
    with which the server is started
  """
  @spec connect_to_server_node() :: boolean() | nil | bitstring()
  def connect_to_server_node() do
    if !Node.alive? do
      lift_client()
    end

    Logger.info("Try to connect to #{@server_name}@#{@server_location}")
    Node.connect(:"#{@server_name}@#{@server_location}")
  end

  defp lift_client() do
    client_name = Application.get_env(:client, :client_name) || random_name()
    Logger.info("Lifing #{client_name}@#{@client_location}")

    case Node.start(:"#{client_name}@#{@client_location}") do
      {:ok, pid} when is_pid(pid) -> client_name
      _ -> nil
    end
  end

  defp random_name() do
    letters = ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

    (1..5)
    |> Enum.reduce([], fn(_, acc) -> [Enum.random(letters) | acc] end)
    |> Enum.join("")
  end
end
