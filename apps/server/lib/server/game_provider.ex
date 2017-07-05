defmodule GameProvider do
require Logger

  def get do
    default_game = [{"What is the capital of Bulgaria?", "Sofia",["It begins with 'S'"]},
                   {"What is three times three minus 8", "1",[]},
                   {"Who let the dogs out", "who",[]}]

    game_url = System.get_env("TG_GAME_URL") || nil

    IO.puts game_url
    case game_url do
      nil ->
        Logger.info("No provided game url. Loading the default game")
        default_game
      _ ->
        case HTTPoison.get game_url do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            #TODO Yeah I know this is error prone as _____
            body |> Parser.parse
          {:ok, %HTTPoison.Response{status_code: 404}} ->
            IO.puts "Provided url not found!"
            []
          {:error, %HTTPoison.Error{reason: reason}} ->
            IO.inspect reason
            []
        end
    end
  end
end
