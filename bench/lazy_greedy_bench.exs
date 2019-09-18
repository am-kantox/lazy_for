defmodule LazyGreedy.Bench do
  use Benchfella
  import LazyFor

  @list Enum.to_list(1..1_000)

  bench "[GREEDY] simple comprehension" do
    for i <- @list, rem(i, 33) == 0, do: i * 2
  end

  bench "[LAZY] simple comprehension" do
    Enum.to_list(stream(i <- @list, rem(i, 33) == 0, take: :all, do: i * 2))
  end

  bench "[LAZY] simple comprehension with :take" do
    stream(i <- @list, rem(i, 33) == 0, take: :all, do: i * 2)
  end
end
