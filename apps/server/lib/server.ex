defmodule Server.Application do
  use Application
  require Logger

  def start(_type, [server_name, server_location]) do
    import Supervisor.Spec, warn: false

    game_states = [{"What is the capital of Bulgaria?", "Sofia"},
                   {"What is three times three minus 8", "1"},
                   {"Who let the dogs out", "who"}]

    case Server.Connectivity.lift_server(server_name,server_location) do
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
