defmodule Server.Connectivity do
  def lift_server() do
    case Node.alive? do
      true -> {:ok, true}
      false ->
        name = System.get_env("SERVER_NAME") || "tg_server"
        location = System.get_env("SEVER_LOCATION") || "10.101.3.78"
        Node.start(:"#{name}@#{location}")
    end
  end
end
