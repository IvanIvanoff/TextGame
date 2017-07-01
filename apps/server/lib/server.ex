defmodule Server do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    case Server.Connectivity.lift_server() do
      {:ok, _} ->
        children = [
          worker(Server.Worker, [:tg_server], [[]])
        ]

        opts = [strategy: :one_for_one, name: Server.Supervisor]
        Supervisor.start_link(children, opts)

      err -> {:error, err}
    end
  end
end
