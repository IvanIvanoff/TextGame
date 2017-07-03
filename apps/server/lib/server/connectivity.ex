defmodule Server.Connectivity do
  def lift_server(name,location) do
    case Node.alive? do
      true -> {:ok, true}
      false ->

        Node.start(:"#{name}@#{location}")
    end
  end
end
