defmodule LazyForTest do
  use ExUnit.Case
  import LazyFor
  doctest LazyFor

  test "works as simple comprehension" do
    result = stream(e <- [1, 2, 3], do: e * 2)
    assert Enum.take(result, 1) == [2]
    assert Enum.take(result, 1_000) == [2, 4, 6]
  end

  test "works as nested comprehension" do
    result = stream(e1 <- [1, 2, 3], e2 <- [10, 20], do: e1 * e2)
    assert Enum.take(result, 1) == [10]
    assert Enum.take(result, 1_000) == [10, 20, 20, 40, 30, 60]
  end

  test "works with guards" do
    result = stream(e1 when e1 != 2 <- [1, 2, 3], e2 <- [10, 20], do: e1 * e2)
    assert Enum.take(result, 1) == [10]
    assert Enum.take(result, 1_000) == [10, 20, 30, 60]
  end

  test "works with conditionals" do
    result =
      stream(
        e1 <- [1, 2, 3],
        e1 != 2,
        e2 <- [10, 20],
        rem(e2, 4) == 0,
        do: e1 * e2
      )

    assert Enum.to_list(result) == [20, 60]
  end

  test "works with chained conditionals" do
    result = stream(e1 <- [1, 2, 3], e1 > 1, rem(e1, 2) != 0, e2 <- [10, 20], do: e1 * e2)
    assert Enum.to_list(result) == [30, 60]
  end
end
