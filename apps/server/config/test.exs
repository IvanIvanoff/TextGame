use Mix.Config

config :server,
       repository_url: "git@github.com:IvanIvanoff/textgamestates.git", polling: false, posts_folder: "posts",
       repository_provider: Blogit.RepositoryProviders.Memory,
meta_divider: "<><><><><><><><>"
