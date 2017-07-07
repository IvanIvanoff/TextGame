defmodule GameProvider do
require Logger

  @games_file "games.txt"

  @doc """
    The function returns a game, which is represented by a list of tuples.
    Each tuple contains a question, answer and a list of hints.

    The function inspects the enviorment variable TG_GAME_URL and if such is present
    it queries it and attempts to parse the result using the custom parser

    For now the funtion tries to parse the whole body of the response. Parsing starts
    with the first '{' seen.
  """
  def get do
    default_game = [{"What is the capital of Bulgaria?", "Sofia",["It begins with 'S'"]},
                   {"What is three times three minus 8", "1",[]},
                   {"Who let the dogs out", "who",[]}]

    game_url = random_game_url()
    case game_url do
      nil ->
        Logger.info("No provided game url. Loading the default game")
        default_game
      _ ->
        case HTTPoison.get game_url do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            body |> Parser.parse
          {:ok, %HTTPoison.Response{status_code: 404}} ->
            IO.puts "Provided url not found! Let's play the default game."
            default_game
          {:error, %HTTPoison.Error{reason: reason}} ->
            IO.inspect reason
            IO.puts "Let's play the default game."
            default_game
        end
    end
  end

  @doc """
    Reads the @games_file file in which every row is a link to a game
    The function splits the file by new lines (ONLY \n NOT \r\n) and selects
    a random game
  """
  def random_game_url() do
    case File.read(@games_file) do
      {:ok, file} ->
        # Take a random game from the file
        file |> String.split("\n") |> Enum.random()
      err -> err
    end
  end
end
