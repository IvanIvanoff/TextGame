defmodule Server do
  def start do
    server_name = System.get_env("TG_SERVER_NAME") || "tg_server"
    server_location = System.get_env("TG_SEVER_LOCATION") || "127.0.0.1"
    Server.Application.start(nil, [server_name,server_location])
  end
end
