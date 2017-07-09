defmodule Server.Connectivity do
  require Logger

  @server_name Application.get_env(:server, :server_name, :tg_server)
  @server_location Application.get_env(:server, :server_location, "127.0.0.1")

  @doc """
    Starts the Node. Uses the environment variables TG_SERVER_NAME and
    TG_SERVER_LOCATION, or if missing uses the default values of "tg_server"
    and "127.0.0.1"
  """
  def lift_server() do
    case Node.alive? do
      true -> {:ok, true}
      false ->
        Logger.info("Lifting a server: #{@server_name}@#{@server_location}")
        Node.start(:"#{@server_name}@#{@server_location}")
    end
  end
end
