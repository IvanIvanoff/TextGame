defmodule Server.Connectivity do
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
