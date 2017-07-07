defmodule Client.Application do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Client.Application.start called")
    Client.Supervisor.start_link()
  end

end
