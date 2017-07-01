defmodule Levenstein do
  def distance(str1, str1), do: 0
  def distance(str, ""), do: String.length(str)
  def distance("", str), do: String.length(str)
  def distance(str1, str2) do
    # ugly ugly.
    h1 = String.first(str1)
    h2 = String.first(str2)
    rest1 = String.slice(str1, 1, :end)
    rest2 = String.slice(str2, 1, :end)

    cost = first_letter_check(h1, h2)

    Enum.min([
      distance(rest1, h2<>rest2) + 1,
      distance(h1<>rest1, rest2) + 1,
      distance(rest1, rest2) + cost
    ])
  end

  def are_similar?(str1, str1), do: true
  def are_similar?(str1, str2) do
    len1 = String.length(str1)
    len2 = String.length(str2)
    len_diff =
      len1 - len2
      |> abs

    case len_diff do
      x when x > 3 -> false
      x when x < 2 and len1 <  7 -> true
      x when x < 3 and len1 >= 7 -> true
      _ -> false
      end
  end


  ###########
  defp first_letter_check(one_letter, two_letter) do
    case one_letter == two_letter do
      true -> 0
      false -> 1
    end
  end
end
