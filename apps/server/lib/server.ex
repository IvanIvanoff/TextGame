defmodule Server do
  use Application
  require Logger

  def start(type, _args) do
    import Supervisor.Spec, warn: false

    Logger.info("TextGame Server is started in #{inspect(type)} mode!")

    game_states = [{"What is the capital of Bulgaria?", "Sofia"},
                   {"What is three times three minus 8", "1"},
                   {"Who let the dogs out", "who"}]

    case Server.Connectivity.lift_server() do
      {:ok, _} ->
        children = [
          worker(Server.Worker, [:tg_server, game_states])
        ]

        opts = [strategy: :one_for_one, name: Server.Supervisor]
        Supervisor.start_link(children, opts)

      err -> {:error, err}
    end
  end
end
