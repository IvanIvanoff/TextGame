use Mix.Config

config :server,
  repository_url: "git@github.com:IvanIvanoff/textgamestates.git",
  polling: true, poll_interval: 60_000,
  posts_folder: ".", assets_path: "assets", meta_divider: "<><><><><><><><>"
