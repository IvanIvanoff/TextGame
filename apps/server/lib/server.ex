defmodule Server.Application do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    game_states = GameProvider.get

    case Server.Connectivity.lift_server() do
      {:ok, _} ->
        Logger.info("TextGame Server is started!")
        children = [
          worker(Server.Worker, [:tg_server, game_states])
        ]

        opts = [strategy: :one_for_one, name: Server.Supervisor]
        Supervisor.start_link(children, opts)
      err -> {:error, err}
    end
  end
end
