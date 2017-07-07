defmodule Server.Application do
  use Application
  require Logger

  def start(_type, _args) do
    Server.Supervisor.start_link()
  end
end
