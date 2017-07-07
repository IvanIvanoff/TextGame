defmodule Server do
  def start do
    Server.Application.start(nil, [])
  end
end
