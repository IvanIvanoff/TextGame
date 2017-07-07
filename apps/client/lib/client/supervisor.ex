defmodule Client.Supervisor do
  use Supervisor

  @doc """
    This function is called by `Server.Application.start/2` and its result is returned by it.
  """
  @spec start_link() :: Supervisor.on_start
  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    name = Client.Connectivity.name()

    children = [
      worker(Client.Worker, [name, :tg_client])
    ]

    opts = [strategy: :one_for_all]

    supervise(children, opts)
  end

end
