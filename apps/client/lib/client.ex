defmodule Client.Application do
  use Application

  def start(_type, _args) do
    with name when not is_nil(name) <- Client.Connectivity.name()
    do
      start_client(name)
    else
      _ -> {:error, "Can't connect to server or establish client."}
    end
  end

  defp start_client(name) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Client.Worker, [name, :tg_client])
    ]

    opts = [strategy: :one_for_one, name: Client.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
