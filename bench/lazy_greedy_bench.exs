defmodule LazyGreedy.Bench do
  use Benchfella
  import LazyFor

  @list Enum.to_list(1..1_000)

  bench "[GREEDY] simple comprehension" do
    for i <- @list, rem(i, 33) == 0, do: i * 2
  end

  bench "[LAZY] native stream" do
    @list
    |> Stream.map(&(&1 * 2))
    |> Stream.filter(&(rem(&1, 33) == 0))
    |> Enum.to_list()
  end

  bench "[LAZY] native stream with transform" do
    @list
    |> Stream.transform([], &{[&1 * 2], &2})
    |> Stream.filter(&(rem(&1, 33) == 0))
    |> Enum.to_list()
  end

  bench "[LAZY] simple comprehension" do
    Enum.to_list(stream(i <- @list, rem(i, 33) == 0, do: i * 2))
  end

  bench "[LAZY] simple comprehension with :take" do
    stream(i <- @list, rem(i, 33) == 0, take: :all, do: i * 2)
  end
end
