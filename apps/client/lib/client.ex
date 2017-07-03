defmodule Client.Application do
  use Application

  def start(_type, [server_location]) do
    with name when not is_nil(name) <- Client.Connectivity.name(),
    true <- Client.Connectivity.connect_to_server_node(server_location) do
      start_client(name)
    else
      _ -> {:error, "Can't connect to server or establish client."}
    end
  end

  defp start_client(nick) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Client.Worker, [nick, :tg_client])
    ]

    opts = [strategy: :one_for_one, name: Client.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
