defmodule LazyFor.Test do
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

  ##############################################################################
  ########### stolen from test/elixir/kernel/comprehension_test.exs ############
  ##############################################################################

  import ExUnit.CaptureIO
  require Integer

  defp nilly, do: nil

  ## Enum comprehensions (the common case)

  test "for comprehensions" do
    enum = 1..3
    assert Enum.to_list(stream(x <- enum, do: x * 2)) == [2, 4, 6]
  end

  test "for comprehensions with matching" do
    assert Enum.to_list(stream({_, x} <- 1..3, do: x * 2)) == []
  end

  test "for comprehensions with pin matching" do
    maps = [x: 1, y: 2, x: 3]
    assert Enum.to_list(stream({:x, v} <- maps, do: v * 2)) == [2, 6]
    x = :x
    assert Enum.to_list(stream({^x, v} <- maps, do: v * 2)) == [2, 6]
  end

  test "for comprehensions with guards" do
    assert Enum.to_list(stream(x when x < 4 <- 1..10, do: x)) == [1, 2, 3]
    assert Enum.to_list(stream(x when x == 3 when x == 7 <- 1..10, do: x)) == [3, 7]
  end

  test "for comprehensions with guards and filters" do
    assert Enum.to_list(
             stream(
               {var, _}
               when is_atom(var) <- [{:foo, 1}, {2, :bar}],
               var = Atom.to_string(var),
               do: var
             )
           ) == ["foo"]
  end

  test "for comprehensions with map key matching" do
    maps = [%{x: 1}, %{y: 2}, %{x: 3}]
    assert Enum.to_list(stream(%{x: v} <- maps, do: v * 2)) == [2, 6]
    x = :x
    assert Enum.to_list(stream(%{^x => v} <- maps, do: v * 2)) == [2, 6]
  end

  test "for comprehensions with filters" do
    assert Enum.to_list(stream(x <- 1..3, x > 1, x < 3, do: x * 2)) == [4]
  end

  test "for comprehensions with nilly filters" do
    assert Enum.to_list(stream(x <- 1..3, nilly(), do: x * 2)) == []
  end

  test "for comprehensions with errors on filters" do
    assert_raise ArgumentError, fn ->
      Enum.take(stream(x <- 1..3, hd(x), do: x * 2), 1)
    end
  end

  test "for comprehensions with variables in filters" do
    assert Enum.to_list(stream(x <- 1..3, y = x + 1, y > 2, z = y, do: x * z)) == [6, 12]
  end

  test "for comprehensions with two enum generators" do
    assert Enum.to_list(
             stream(
               x <- [1, 2, 3],
               y <- [4, 5, 6],
               do: x * y
             )
           ) == [4, 5, 6, 8, 10, 12, 12, 15, 18]
  end

  test "for comprehensions with two enum generators and filters" do
    assert Enum.to_list(
             stream(
               x <- [1, 2, 3],
               y <- [4, 5, 6],
               y / 2 == x,
               do: x * y
             )
           ) == [8, 18]
  end

  test "for comprehensions generators precedence" do
    assert Enum.to_list(stream({_, _} = x <- [foo: :bar], do: x)) == [foo: :bar]
  end

  test "for comprehensions where value is not used" do
    enum = 1..3

    assert capture_io(fn ->
             for x <- enum, do: IO.puts(x)
             nil
           end) == "1\n2\n3\n"
  end

  ## List generators

  test "list for comprehensions" do
    list = [1, 2, 3]
    assert Enum.to_list(stream(x <- list, do: x * 2)) == [2, 4, 6]
  end

  test "list for comprehensions with matching" do
    assert Enum.to_list(stream({_, x} <- [1, 2, a: 3, b: 4, c: 5], do: x * 2)) == [6, 8, 10]
  end

  test "list for comprehension matched to '_' on last line of block" do
    assert (if true_fun() do
              _ = for x <- [1, 2, 3], do: x * 2
            end) == [2, 4, 6]
  end

  defp true_fun(), do: true

  test "list for comprehensions with filters" do
    assert Enum.to_list(stream(x <- [1, 2, 3], x > 1, x < 3, do: x * 2)) == [4]
  end

  test "list for comprehensions with nilly filters" do
    assert Enum.to_list(stream(x <- [1, 2, 3], nilly(), do: x * 2)) == []
  end

  test "list for comprehensions with errors on filters" do
    assert_raise ArgumentError, fn ->
      Enum.take(stream(x <- [1, 2, 3], hd(x), do: x * 2), 1)
    end
  end

  test "list for comprehensions where value is not used" do
    enum = [1, 2, 3]

    assert capture_io(fn ->
             for x <- enum, do: IO.puts(x)
             nil
           end) == "1\n2\n3\n"
  end
end
