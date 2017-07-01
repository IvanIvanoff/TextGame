defmodule ServerTest do
  use ExUnit.Case

  test "Test levenstein distance 0" do
    assert 0 == Levenstein.distance("Sample string", "Sample string")
  end

  test "Test levenstein distance not 0" do
    assert 0 != Levenstein.distance("Sample", "String")
  end

  test "Test levenstein distance exactly with empty string" do
    assert 5 == Levenstein.distance("abcde", "")
  end

  test "Test levenstein distance with non-empty strigs" do
    assert 4 == Levenstein.distance("Kircho", "Petarcho")
  end

  test "Test two strings are similiar" do
    assert false == Levenstein.are_similar?("Some string", "")
    assert true  == Levenstein.are_similar?(
      "Soffia",
      "Sofia")
  end
end
