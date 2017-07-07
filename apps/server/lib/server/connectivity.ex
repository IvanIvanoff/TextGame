defmodule Server.Connectivity do

  @doc """
    Starts the Node. Uses the environment variables TG_SERVER_NAME and
    TG_SERVER_LOCATION, or if missing uses the default values of "tg_server"
    and "127.0.0.1"
  """
  def lift_server() do
    case Node.alive? do
      true -> {:ok, true}
      false ->
        server_name = System.get_env("TG_SERVER_NAME") || "tg_server"
        server_location = System.get_env("TG_SEVER_LOCATION") || "127.0.0.1"
        Node.start(:"#{server_name}@#{server_location}")
    end
  end
end
