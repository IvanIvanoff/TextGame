defmodule Parser do
  @moduledoc """
    Pass a string in the form "{question,answer,[hint1, hint2, ....]}, {question2,answer2,[hint1, hint2, ....]}..."
    and it will be converted to Elixir list of tuples.

    Did not found a nice library for that, so I wrote that myself. Poison converts
    to map, and I dont want that.

    Also, parser generators or using ABNF grammars will take more time to research, write and debug than writing that
    little piece of $h!7 lib.

    ## Examples

    iex> Parser.parse("{test123, test456, [elem1,elem2]")
    [{"test123", "test456", ["elem1", "elem2"]}]
  """

  @doc """
    Parses string, containg a sequence of tuples, each containg three elements -
    two strings and a list
  """
  def parse(str) do
    parse(str, "", "", "", [], [], :expect_bracket)
  end

  defp parse("",_,_,_,_,list,_), do: Enum.reverse(list)

  defp parse("{" <> rest, arg1, arg2, hint, hints, list, :expect_bracket) do
    parse(rest, arg1, arg2, hint, hints, list, :first)
  end

  defp parse("}" <> str, arg1, arg2, _, hints, list, _) do
    list = [{
      String.reverse(arg1) |> String.trim,
      String.reverse(arg2) |> String.trim,
      Enum.reverse(hints)
      }|list]
    parse(str, "", "", "", [], list, :expect_bracket)
  end

  defp parse("[" <> rest, arg1, arg2, _hint, _hints, list, :expect_bracket) do
     parse(rest, arg1, arg2, "", [], list, :hints)
  end

  # So empty list of hints is parsed corectly
  defp parse("]" <> rest, arg1, arg2, "", hints, list, :hints) do
    parse(rest, arg1, arg2, "", hints, list, :expect_bracket)
  end

  defp parse("]" <> rest, arg1, arg2, hint, hints, list, :hints) do
    hints = [String.reverse(hint) |> String.trim |hints]
    parse(rest, arg1, arg2, "", hints, list, :expect_bracket)
  end

  defp parse("," <> rest, arg1, arg2, hint, hints, list, :first) do
    parse(rest, arg1, arg2, hint, hints, list, :second)
  end

  defp parse("," <> rest, arg1, arg2, hint, hints, list, :second) do
    parse(rest, arg1, arg2, hint, hints, list, :expect_bracket)
  end

  defp parse("," <> rest, arg1, arg2, hint, hints, list, :hints) do
    hints = [String.reverse(hint) |> String.trim |hints]
    parse(rest, arg1, arg2, "", hints, list, :hints)
  end

  defp parse(str, arg1, arg2, hint, hints, list, :expect_bracket) do
    rest = String.slice(str, 1, :last)
    parse(rest, arg1, arg2, hint, hints, list, :expect_bracket)
  end

  defp parse(str, arg1, arg2, hint, hints, list, :first) do
    h = String.first(str)
    t = String.slice(str, 1, :last)

    parse(t, h <> arg1, arg2, hint, hints, list, :first)
  end

  defp parse(str, arg1, arg2, hint, hints, list, :hints) do
    h = String.first(str)
    t = String.slice(str, 1, :last)

    parse(t, arg1, arg2, h <> hint, hints, list, :hints)
  end

  defp parse(str, arg1, arg2, hint, hints, list, :second) do
    h = String.first(str)
    t = String.slice(str, 1, :last)

    arg2 = h <> arg2
    parse(t, arg1, arg2, hint, hints, list, :second)
  end
end
