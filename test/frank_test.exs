defmodule FrankTest do
  use ExUnit.Case
  doctest Frank

  test "greets the world" do
    assert Frank.hello() == :world
  end
end
