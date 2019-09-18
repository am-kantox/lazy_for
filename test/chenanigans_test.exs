defmodule LazyFor.KeywordOptions.Test do
  use ExUnit.Case
  import LazyFor

  ##############################################################################
  ########### stolen from test/elixir/kernel/comprehension_test.exs ############
  ##############################################################################

  import ExUnit.CaptureIO
  require Integer

  defp to_bin(x) do
    <<x>>
  end

  # defp nilly, do: nil

  ##############################################################################
  ########### :uniq
  ##############################################################################

  test "for comprehensions with unique values" do
    list = [1, 1, 2, 3]
    assert Enum.to_list(stream(x <- list, uniq: true, do: x * 2)) == [2, 4, 6]
    assert Enum.to_list(stream(x <- list, uniq: true, into: [], do: x * 2)) == [2, 4, 6]

    assert Enum.to_list(stream(x <- list, uniq: true, into: %{}, do: {x, 1})) == [
             {1, 1},
             {2, 1},
             {3, 1}
           ]

    assert Enum.to_list(stream(<<x <- "abcabc">>, uniq: true, into: "", do: to_bin(x))) == [
             "a",
             "b",
             "c"
           ]

    Process.put(:into_cont, [])
    Process.put(:into_done, false)
    Process.put(:into_halt, false)

    stream x <- list, uniq: true, into: %Pdict{} do
      x * 2
    end
    |> Stream.run()

    assert Process.get(:into_cont) == [6, 4, 2]
    assert Process.get(:into_done)
    refute Process.get(:into_halt)

    assert_raise RuntimeError, "oops", fn ->
      Stream.run(stream(_ <- [1, 2, 3], uniq: true, into: %Pdict{}, do: raise("oops")))
    end

    assert Process.get(:into_halt)
  end

  test "for comprehensions with binary, enum generators and filters" do
    assert Enum.to_list(stream(<<x <- "!Q\"">>, <<y <- "BCD">>, y / 2 == x, do: x * y)) == [
             2178,
             2312
           ]
  end

  test "for comprehensions into list" do
    enum = 1..3
    assert Enum.to_list(stream(x <- enum, into: [], do: x * 2)) == [2, 4, 6]
  end

  test "for comprehensions into binary" do
    enum = 0..3

    assert Enum.to_list(
             stream x <- enum, into: "" do
               to_bin(x * 2)
             end
           ) == [<<0>>, <<2>>, <<4>>, <<6>>]

    assert Enum.to_list(
             stream x <- enum, into: "" do
               if Integer.is_even(x), do: <<x::size(2)>>, else: <<x::size(1)>>
             end
           ) == [<<0::size(2)>>, <<1::size(1)>>, <<2::size(2)>>, <<3::size(1)>>]
  end

  test "for comprehensions into dynamic binary" do
    enum = 0..3
    into = ""

    assert Enum.to_list(
             stream x <- enum, into: into do
               to_bin(x * 2)
             end
           ) == [<<0>>, <<2>>, <<4>>, <<6>>]

    assert Enum.to_list(
             stream x <- enum, into: into do
               if Integer.is_even(x), do: <<x::size(2)>>, else: <<x::size(1)>>
             end
           ) == [<<0::size(2)>>, <<1::size(1)>>, <<2::size(2)>>, <<3::size(1)>>]

    # into = <<7::size(1)>>

    # assert Enum.to_list(
    #          stream x <- enum, into: into do
    #            to_bin(x * 2)
    #          end
    #        ) == <<7::size(1), 0, 2, 4, 6>>

    # assert Enum.to_list(
    #          stream x <- enum, into: into do
    #            if Integer.is_even(x), do: <<x::size(2)>>, else: <<x::size(1)>>
    #          end
    #        ) == <<7::size(1), 0::size(2), 1::size(1), 2::size(2), 3::size(1)>>
  end

  test "for comprehensions with into" do
    Process.put(:into_cont, [])
    Process.put(:into_done, false)
    Process.put(:into_halt, false)

    for x <- 1..3, into: %Pdict{} do
      x * 2
    end

    assert Process.get(:into_cont) == [6, 4, 2]
    assert Process.get(:into_done)
    refute Process.get(:into_halt)
  end

  test "for comprehension with into leading to errors" do
    Process.put(:into_cont, [])
    Process.put(:into_done, false)
    Process.put(:into_halt, false)

    catch_error(
      for x <- 1..3, into: %Pdict{} do
        if x > 2, do: raise("oops"), else: x
      end
    )

    assert Process.get(:into_cont) == [2, 1]
    refute Process.get(:into_done)
    assert Process.get(:into_halt)
  end

  test "for comprehension with into, generators and filters" do
    Process.put(:into_cont, [])

    for x <- 1..3, Integer.is_odd(x), <<y <- "hello">>, into: %Pdict{} do
      x + y
    end

    assert IO.iodata_to_binary(Process.get(:into_cont)) == "roohkpmmfi"
  end

  test "for comprehensions of map into map" do
    enum = %{a: 2, b: 3}
    assert Enum.to_list(stream({k, v} <- enum, into: %{}, do: {k, v * v})) == [a: 4, b: 9]
  end

  test "for comprehensions with reduce, generators and filters" do
    acc =
      for x <- 1..3, Integer.is_odd(x), <<y <- "hello">>, reduce: %{} do
        acc -> Map.update(acc, x, [y], &[y | &1])
      end

    assert acc == %{1 => 'olleh', 3 => 'olleh'}
  end

  test "list for comprehensions into binary" do
    enum = [0, 1, 2, 3]

    assert Enum.to_list(
             stream x <- enum, into: "" do
               to_bin(x * 2)
             end
           ) == [<<0>>, <<2>>, <<4>>, <<6>>]

    assert Enum.to_list(
             stream x <- enum, into: "" do
               if Integer.is_even(x), do: <<x::size(2)>>, else: <<x::size(1)>>
             end
           ) == [<<0::size(2)>>, <<1::size(1)>>, <<2::size(2)>>, <<3::size(1)>>]
  end

  test "list for comprehensions into dynamic binary" do
    enum = [0, 1, 2, 3]
    into = ""

    assert Enum.to_list(
             stream x <- enum, into: into do
               to_bin(x * 2)
             end
           ) == [<<0>>, <<2>>, <<4>>, <<6>>]

    assert Enum.to_list(
             stream x <- enum, into: into do
               if Integer.is_even(x), do: <<x::size(2)>>, else: <<x::size(1)>>
             end
           ) == [<<0::size(2)>>, <<1::size(1)>>, <<2::size(2)>>, <<3::size(1)>>]

    # into = <<7::size(1)>>

    # assert Enum.to_list(
    #          stream x <- enum, into: into do
    #            to_bin(x * 2)
    #          end
    #        ) == <<7::size(1), 0, 2, 4, 6>>

    # assert Enum.to_list(
    #          stream x <- enum, into: into do
    #            if Integer.is_even(x), do: <<x::size(2)>>, else: <<x::size(1)>>
    #          end
    #        ) == <<7::size(1), 0::size(2), 1::size(1), 2::size(2), 3::size(1)>>
  end

  test "list for comprehensions with reduce, generators and filters" do
    acc =
      for x <- [1, 2, 3], Integer.is_odd(x), <<y <- "hello">>, reduce: %{} do
        acc -> Map.update(acc, x, [y], &[y | &1])
      end

    assert acc == %{1 => 'olleh', 3 => 'olleh'}
  end

  ## Binary generators

  test "binary for comprehensions" do
    bin = "abc"
    assert Enum.to_list(stream(<<x <- bin>>, do: x * 2)) == [194, 196, 198]
  end

  test "binary for comprehensions with inner binary" do
    bin = "abc"
    assert Enum.to_list(stream(<<(<<x>> <- bin)>>, do: x * 2)) == [194, 196, 198]
  end

  test "binary for comprehensions with two generators" do
    assert Enum.to_list(stream(<<x <- "!Q\"">>, <<y <- "BCD">>, y / 2 == x, do: x * y)) == [
             2178,
             2312
           ]
  end

  test "binary for comprehensions into list" do
    bin = "abc"
    assert Enum.to_list(stream(<<x <- bin>>, into: [], do: x * 2)) == [194, 196, 198]
  end

  test "binary for comprehensions into binary" do
    bin = <<0, 1, 2, 3>>

    assert Enum.to_list(
             stream <<x <- bin>>, into: "" do
               to_bin(x * 2)
             end
           ) == [<<0>>, <<2>>, <<4>>, <<6>>]

    assert Enum.to_list(
             stream <<x <- bin>>, into: "" do
               if Integer.is_even(x), do: <<x::size(2)>>, else: <<x::size(1)>>
             end
           ) == [<<0::size(2)>>, <<1::size(1)>>, <<2::size(2)>>, <<3::size(1)>>]
  end

  test "binary for comprehensions into dynamic binary" do
    bin = <<0, 1, 2, 3>>
    into = ""

    assert Enum.to_list(
             stream <<x <- bin>>, into: into do
               to_bin(x * 2)
             end
           ) == [<<0>>, <<2>>, <<4>>, <<6>>]

    assert Enum.to_list(
             stream <<x <- bin>>, into: into do
               if Integer.is_even(x), do: <<x::size(2)>>, else: <<x::size(1)>>
             end
           ) == [<<0::size(2)>>, <<1::size(1)>>, <<2::size(2)>>, <<3::size(1)>>]

    # into = <<7::size(1)>>

    # assert Enum.to_list(
    #          stream <<x <- bin>>, into: into do
    #            to_bin(x * 2)
    #          end
    #        ) == <<7::size(1), 0, 2, 4, 6>>

    # assert Enum.to_list(
    #          stream <<x <- bin>>, into: into do
    #            if Integer.is_even(x), do: <<x::size(2)>>, else: <<x::size(1)>>
    #          end
    #        ) == <<7::size(1), 0::size(2), 1::size(1), 2::size(2), 3::size(1)>>
  end

  # test "binary for comprehensions with literal matches" do
  #   # Integers
  #   bin = <<1, 2, 1, 3, 1, 4>>
  #   assert Enum.to_list(stream(<<1, x <- bin>>, into: "", do: to_bin(x))) == <<2, 3, 4>>

  #   assert Enum.to_list(stream(<<1, x <- bin>>, into: %{}, do: {x, x})) == %{
  #            2 => 2,
  #            3 => 3,
  #            4 => 4
  #          }

  #   bin = <<1, 2, 3, 1, 4>>
  #   assert Enum.to_list(stream(<<1, x <- bin>>, into: "", do: to_bin(x))) == <<2>>
  #   assert Enum.to_list(stream(<<1, x <- bin>>, into: %{}, do: {x, x})) == %{2 => 2}

  #   # Floats
  #   bin = <<1.0, 2, 1.0, 3, 1.0, 4>>
  #   assert Enum.to_list(stream(<<1.0, x <- bin>>, into: "", do: to_bin(x))) == <<2, 3, 4>>

  #   assert Enum.to_list(stream(<<1.0, x <- bin>>, into: %{}, do: {x, x})) == %{
  #            2 => 2,
  #            3 => 3,
  #            4 => 4
  #          }

  #   bin = <<1.0, 2, 3, 1.0, 4>>
  #   assert Enum.to_list(stream(<<1.0, x <- bin>>, into: "", do: to_bin(x))) == <<2>>
  #   assert Enum.to_list(stream(<<1.0, x <- bin>>, into: %{}, do: {x, x})) == %{2 => 2}

  #   # Binaries
  #   bin = <<"foo", 2, "foo", 3, "foo", 4>>
  #   assert Enum.to_list(stream(<<"foo", x <- bin>>, into: "", do: to_bin(x))) == <<2, 3, 4>>

  #   assert Enum.to_list(stream(<<"foo", x <- bin>>, into: %{}, do: {x, x})) == %{
  #            2 => 2,
  #            3 => 3,
  #            4 => 4
  #          }

  #   bin = <<"foo", 2, 3, "foo", 4>>
  #   assert Enum.to_list(stream(<<"foo", x <- bin>>, into: "", do: to_bin(x))) == <<2>>
  #   assert Enum.to_list(stream(<<"foo", x <- bin>>, into: %{}, do: {x, x})) == %{2 => 2}

  #   bin = <<"foo", 2, 3, 4, "foo", 5>>
  #   assert Enum.to_list(stream(<<"foo", x <- bin>>, into: "", do: to_bin(x))) == <<2>>
  #   assert Enum.to_list(stream(<<"foo", x <- bin>>, into: %{}, do: {x, x})) == %{2 => 2}
  # end

  # test "binary for comprehensions with variable size" do
  #   s = 16
  #   bin = <<1, 2, 3, 4, 5, 6>>

  #   assert Enum.to_list(stream(<<x::size(s) <- bin>>, into: "", do: to_bin(div(x, 2)))) ==
  #            <<129, 130, 131>>

  #   # Aligned
  #   bin = <<8, 1, 16, 2, 3>>

  #   assert Enum.to_list(stream(<<s, x::size(s) <- bin>>, into: "", do: <<x::size(s)>>)) ==
  #            <<1, 2, 3>>

  #   assert Enum.to_list(stream(<<s, x::size(s) <- bin>>, into: %{}, do: {s, x})) == %{
  #            8 => 1,
  #            16 => 515
  #          }

  #   # Unaligned
  #   bin = <<8, 1, 32, 2, 3>>
  #   assert Enum.to_list(stream(<<s, x::size(s) <- bin>>, into: "", do: <<x::size(s)>>)) == <<1>>
  #   assert Enum.to_list(stream(<<s, x::size(s) <- bin>>, into: %{}, do: {s, x})) == %{8 => 1}
  # end

  test "binary for comprehensions where value is not used" do
    bin = "abc"

    assert capture_io(fn ->
             for <<x <- bin>>, do: IO.puts(x)
             nil
           end) == "97\n98\n99\n"
  end

  test "binary for comprehensions with reduce, generators and filters" do
    bin = "abc"

    acc =
      for <<x <- bin>>, Integer.is_odd(x), <<y <- "hello">>, reduce: %{} do
        acc -> Map.update(acc, x, [y], &[y | &1])
      end

    assert acc == %{97 => 'olleh', 99 => 'olleh'}
  end
end
