defmodule Parser do
  @moduledoc """
    Pass a string in the form "{question,answer}, {question2,answer2}..."
    and it will be converted to Elixir list of tuples.

    Did not found a nice library for that, so I wrote that myself. Poison converts
    to map, and I dont want that
  """

  @doc """
    TODO: Write comments, Vanyo.
  """
  def parse(str) do
    parse(str, "", "", [], :expect_bracket)
  end

  defp parse("",_,_,list,_), do: Enum.reverse(list)

  defp parse("{" <> rest, arg1, arg2, list, :expect_bracket) do
    parse(rest, arg1, arg2, list, :first)
  end

  defp parse(str, arg1, arg2, list, :expect_bracket) do
    t = String.slice(str, 1, :last)
    parse(t, arg1, arg2, list, :expect_bracket)
  end

  defp parse("," <> rest, arg1, arg2, list, :first) do
    parse(rest, arg1, arg2, list, :second)
  end

  defp parse("}" <> str, arg1, arg2, list, _) do
    list = [{
      String.reverse(arg1) |> String.trim,
      String.reverse(arg2) |> String.trim,
      }|list]
    parse(str, "", "", list, :expect_bracket)
  end

  defp parse(str, arg1, arg2, list, :first) do
    h = String.first(str)
    t = String.slice(str, 1, :last)

    arg1 = h <> arg1
    parse(t, arg1, arg2, list, :first)
  end

  defp parse(str, arg1, arg2, list, :second) do
    h = String.first(str)
    t = String.slice(str, 1, :last)

    arg2 = h <> arg2
    parse(t, arg1, arg2, list, :second)
  end
end
