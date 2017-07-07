defmodule Server do

  def start do
    Server.Application.start(nil, [server_name,server_location])
  end
end
