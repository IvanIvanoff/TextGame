use Mix.Config

config :client,
       client_name:       :test_tg_client,
       client_location:   "127.0.0.1",
       server_name:       :test_tg_server,
       server_location:   "127.0.0.1",
       reconnect_timeout: 500
