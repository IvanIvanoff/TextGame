defmodule Levenstein do
  @moduledoc """
    A module, containing some functions to calulate and work with leveinstain distance

    Levenshtein distance (LD) is a measure of the similarity between two strings,
    which we will refer to as the source string (s) and the target string (t).
    The distance is the number of deletions, insertions, or substitutions required
    to transform s into t
  """

  @doc """
    Returns a whole positive number which is the levenstein distance of the two strings
  """
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

  @doc """
    Test if two strings are similar based on their levenstein distance.
    Always return false if one of the strings is with length less than 3.
    Otherwise implement some additional logic for checking wheter or not they are
    similar
  """
  def are_similar?(str1, str1), do: true
  def are_similar?(str1, str2) when length(str1) < 4 or length(str2) < 4, do: false
  def are_similar?(str1, str2) do
    len1 = String.length(str1)
    len2 = String.length(str2)
    len_diff = len1 - len2 |> abs

    if(len_diff > 2) do
      false
    else
      case distance(str1,str2) do
        x when x < 2 -> true
        _ -> false
      end
    end
  end


  ##############################
  ########## PRIVATE ###########
  ##############################

  defp first_letter_check(one_letter, two_letter) do
    case one_letter == two_letter do
      true -> 0
      false -> 1
    end
  end
end
