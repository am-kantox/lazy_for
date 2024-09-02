# LazyFor [![Kantox ❤ OSS](https://img.shields.io/badge/❤-kantox_oss-informational.svg)](https://kantox.com/)  ![Test](https://github.com/am-kantox/lazy_for/workflows/Test/badge.svg)  ![Dialyzer](https://github.com/am-kantox/lazy_for/workflows/Dialyzer/badge.svg)  [![Coverage Status](https://coveralls.io/repos/github/am-kantox/lazy_for/badge.svg?branch=master)](https://coveralls.io/github/am-kantox/lazy_for?branch=master)

![Scene in club lounge, by Thomas Rowlandson](https://raw.githubusercontent.com/am-kantox/lazy_for/master/stuff/1118px-British_club_scene.jpg)

_Scene in club lounge, by [Thomas Rowlandson](https://en.wikipedia.org/wiki/Thomas_Rowlandson)_

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

iex> Enum.to_list(stream <<c <- "a b c">>, c != ?\s, do: c)
'abc'
```

## Installation

```elixir
def deps do
  [
    {:lazy_for, "~> 1.0"}
  ]
end
```

## Changelog

### `v1.1.0`

- `reduce:` optional argument is experimentally supported

### `v1.0.0`

- version bump

### `v0.3.0`

- optional arguments `:into`, `:uniq`, and `:take`
- remaining: `:reduce`

### `v0.2.0`

- assignments inside the pipeline
- support for binary comprehensions

## [Documentation](https://hexdocs.pm/lazy_for).

