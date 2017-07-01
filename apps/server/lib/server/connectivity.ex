defmodule Server.Connectivity do
  def lift_server() do
    case Node.alive? do
      true -> {:ok, true}
      false ->
        Node.start(:"server@127.0.0.1")
      #  name = System.get_env("SERVER_NAME") || "tgserver"
      #  location = System.get_env("SEVER_LOCATION") || "127.0.0.1"
      #  Node.start(:"#{name}@#{location}")
    end
  end
end
