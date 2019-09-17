defmodule LazyFor do
  @moduledoc """
  The stream-based implementation of `Kernel.SpecialForms.for/1`.

  Has the same syntax as its ancestor, returns a stream.

  Currently supports `Enum.t()` as an input. Examples are gracefully stolen
    from the ancestor’s docs.

  _Examples:_

      iex> import LazyFor
      iex> result = stream n <- [1, 2, 3, 4], do: n * 2
      iex> Enum.to_list(result)
      [2, 4, 6, 8]

      iex> users = [user: "john", admin: "meg", guest: "barbara"]
      iex> result = stream {type, name} when type != :guest <- users do
      ...>   String.upcase(name)
      ...> end
      iex> Enum.to_list(result)
      ["JOHN", "MEG"]
  """
  defmacrop a(), do: quote(do: {:acc, [], Elixir})

  defmacrop __s__(any \\ {:_, [], nil}),
    do: quote(do: {:., [], [{:__aliases__, [alias: false], [:Stream]}, unquote(any)]})

  defmacrop stransf(), do: quote(do: __s__(:transform))
  defmacrop sfilter(), do: quote(do: __s__(:filter))

  ##############################################################################

  defp reduce_clauses(clauses, block, acc \\ []) do
    clauses
    |> Enum.reverse()
    |> Enum.reduce({acc, block}, fn outer, {acc, inner} ->
      {acc, clause(outer, inner, acc)}
    end)
  end

  # simple comprehension, outer, guards
  defp clause(
         {:<-, _meta, [{:when, _inner_meta, [var, conditions]}, source]},
         {__s__(), _, _} = inner,
         acc
       ),
       do: do_stransf_clause(source, acc, do_fn_body(inner, var, conditions))

  # simple comprehension, inner, guards
  defp clause({:<-, _meta, [{:when, _inner_meta, [var, conditions]}, source]}, inner, acc),
    do: do_stransf_clause(source, acc, do_fn_body([inner], var, conditions))

  # simple comprehension, outer, no guards
  defp clause({:<-, _meta, [var, source]}, {__s__(), _, _} = inner, acc),
    do: do_stransf_clause(source, acc, do_fn_body(inner, var))

  # simple comprehension, inner, no guards
  defp clause({:<-, _meta, [var, source]}, inner, acc),
    do: do_stransf_clause(source, acc, do_fn_body([inner], var))

  # condition
  defp clause(guard, {__s__(), _, _} = inner, _acc),
    do: {sfilter(), [], [inner, {:fn, [], [{:->, [], [[{:_, [], Elixir}], guard]}]}]}

  defp clause(guard, inner, _acc),
    do: {sfilter(), [], [[inner], {:fn, [], [{:->, [], [[{:_, [], Elixir}], guard]}]}]}

  ##############################################################################

  defp do_stransf_clause(source, acc, fn_body),
    do: {stransf(), [], [source, acc, {:fn, [], fn_body}]}

  defp do_fn_body(inner, var), do: [{:->, [], [[var, a()], {inner, a()}]}]

  defp do_fn_body(inner, var, conditions) do
    [
      {:->, [], [[{:when, [], [var, a(), conditions]}], {inner, a()}]},
      {:->, [], [[{:_, [], Elixir}, a()], {[], a()}]}
    ]
  end

  ##############################################################################

  @clauses 42
  @args for i <- 1..(@clauses + 1),
            into: %{},
            do: {i, Enum.map(1..i, &Macro.var(:"arg_#{&1}", nil))}

  for i <- 1..@clauses do
    @doc false
    defmacro stream(unquote_splicing(@args[i]), do: block),
      do: with({_, s} <- reduce_clauses(unquote(@args[i]), block), do: s)
  end
end
