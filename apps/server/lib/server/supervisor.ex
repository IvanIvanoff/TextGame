defmodule Server.Supervisor do
  use Supervisor
  require Logger

  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    game_states = GameProvider.get

    case Server.Connectivity.lift_server() do
      {:ok, _} ->
        Logger.info("TextGame Server is started!")
        children = [
          worker(Server.Worker, [:tg_server, game_states])
        ]

        opts = [strategy: :one_for_one, name: Server.Supervisor]
        supervise(children, opts)
      err -> {:error, err}
    end
  end
end
