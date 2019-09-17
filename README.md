# LazyFor

![Scene in club lounge, by Thomas Rowlandson](https://raw.githubusercontent.com/am-kantox/lazy_for/master/stuff/1118px-British_club_scene.jpg)
> <small>Scene in club lounge, by [Thomas Rowlandson](https://en.wikipedia.org/wiki/Thomas_Rowlandson)</small>

## About

The stream-based implementation of [`Kernel.SpecialForms.for/1`](https://hexdocs.pm/elixir/master/Kernel.SpecialForms.html?#for/1).

Has the same syntax as its ancestor, returns a stream.

Currently supports `Enum.t()` as an input. Examples are gracefully stolen from the ancestor’s docs.

_Examples:_

```elixir
iex> import LazyFor
iex> # A list generator:
iex> result = stream n <- [1, 2, 3, 4], do: n * 2
iex> Enum.to_list(result)
[2, 4, 6, 8]

iex> # A comprehension with two generators
iex> result = stream x <- [1, 2], y <- [2, 3], do: x * y
iex> Enum.to_list(result)
[2, 3, 4, 6]

iex> # A comprehension with a generator and a filter
iex> result = stream n <- [1, 2, 3, 4, 5, 6], rem(n, 2) == 0, do: n
iex> Enum.to_list(result)
[2, 4, 6]

iex> users = [user: "john", admin: "meg", guest: "barbara"]
iex> result = stream {type, name} when type != :guest <- users do
...>   String.upcase(name)
...> end
iex> Enum.to_list(result)
["JOHN", "MEG"]
```

## Installation

```elixir
def deps do
  [
    {:lazy_for, "~> 0.1"}
  ]
end
```

## [Documentation](https://hexdocs.pm/lazy_for).

