defmodule LazyFor do
  @moduledoc """
  The stream-based implementation of `Kernel.SpecialForms.for/1`.

  Has the same syntax as its ancestor, returns a stream.

  Currently supports `Enum.t()` as an input. Examples are gracefully stolen
    from the ancestor’s docs.

  _Examples:_

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

      iex> Enum.to_list(stream <<c <- "a|b|c">>, c != ?|, do: c)
      ~c"abc"
  """

  import :elixir_errors
  @doc false
  def format_error(term), do: :elixir_expand.format_error(term)

  defmacrop a, do: quote(do: {:acc, [], Elixir})

  defmacrop __s__(any \\ {:_, [], nil}),
    do: quote(do: {:., [], [{:__aliases__, [alias: false], [:Stream]}, unquote(any)]})

  defmacrop stransf, do: quote(do: __s__(:transform))
  defmacrop sfilter, do: quote(do: __s__(:filter))

  ##############################################################################

  defp reduce_clauses(clauses, block, acc \\ [])

  defp reduce_clauses(
         clauses,
         [{:->, acc_meta, [[{acc_var_name, _, _} = acc_var], acc_ast]}],
         acc
       ) do
    acc_ast =
      Macro.postwalk(acc_ast, fn
        {^acc_var_name, _, ctx} = ast_node when is_atom(ctx) ->
          ast_node

        {var_name, var_meta, ctx} when is_atom(var_name) and is_atom(ctx) ->
          {{:., var_meta, [{:__aliases__, [alias: false], [:Keyword]}, :get]}, var_meta,
           [{:e, [], nil}, var_name]}

        ast_node ->
          ast_node
      end)

    [reducer] = [{:fn, acc_meta, [{:->, acc_meta, [[{:e, [], nil}, acc_var], acc_ast]}]}]

    {[], ast} =
      clauses
      |> Enum.reverse()
      |> Enum.reduce({acc, quote(do: binding())}, fn outer, {acc, inner} ->
        {acc, clause(outer, inner, acc)}
      end)

    {reducer, ast}
  end

  defp reduce_clauses(clauses, block, acc) do
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

  # expression
  defp clause({:=, meta, [var, expression]}, inner, acc),
    do: clause({:<-, meta, [var, [expression]]}, inner, acc)

  # TODO
  # stream <<r::8, g::8, b::8 <- pixels>>, do: {r, g, b}
  # {{:<<>>, _,
  #   [
  #     {:"::", _, [{:r, _, nil}, 8]},
  #     {:"::", _, [{:g, _, nil}, 8]},
  #     {:<-, _, [{:"::", _, [{:b, _, nil}, 8]}, {:pixels, _, nil}]}
  #   ]}, {:{}, _, [{:r, _, nil}, {:g, _, nil}, {:b, _, nil}]}}

  # binary string
  defp clause({:<<>>, outer_meta, [{:<-, meta, [{:<<>>, _, [var]}, source]}]}, inner, acc),
    do: clause({:<<>>, outer_meta, [{:<-, meta, [var, source]}]}, inner, acc)

  defp clause({:<<>>, _, [{:<-, meta, [var, source]}]}, inner, acc),
    do:
      clause(
        {:<-, meta, [var, {{:., [], [:erlang, :bitstring_to_list]}, [], [source]}]},
        inner,
        acc
      )

  # condition
  defp clause(guard, {__s__(), _, _} = inner, _acc),
    do: {sfilter(), [], [inner, {:fn, [], [{:->, [], [[{:_, [], Elixir}], guard]}]}]}

  defp clause(guard, inner, _acc),
    do: {sfilter(), [], [[inner], {:fn, [], [{:->, [], [[{:_, [], Elixir}], guard]}]}]}

  ##############################################################################

  defp do_stransf_clause(source, acc, fn_body),
    do: {stransf(), [], [source, acc, {:fn, [], fn_body}]}

  defp do_fn_body(inner, {var_name, _, ctx} = var) when is_atom(var_name) and is_atom(ctx),
    do: [{:->, [], [[var, a()], {inner, a()}]}]

  defp do_fn_body(inner, var),
    do: [
      {:->, [], [[var, a()], {inner, a()}]},
      {:->, [], [[{:_, [], Elixir}, a()], {[], a()}]}
    ]

  defp do_fn_body(inner, var, conditions),
    do: [
      {:->, [], [[{:when, [], [var, a(), conditions]}], {inner, a()}]},
      {:->, [], [[{:_, [], Elixir}, a()], {[], a()}]}
    ]

  ##############################################################################

  defp do_apply_opts({reducer, ast}, opts, caller) do
    ast =
      if opts[:uniq],
        do: {{:., [], [{:__aliases__, [alias: false], [:Stream]}, :uniq]}, [], [ast]},
        else: ast

    into = opts[:into]

    ast =
      if into,
        do: {{:., [], [{:__aliases__, [alias: false], [:Stream]}, :into]}, [], [ast, into]},
        else: ast

    ast =
      case opts[:take] do
        :all ->
          {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :to_list]}, [], [ast]}

        i when is_integer(i) ->
          {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :take]}, [], [ast, i]}

        _ ->
          ast
      end

    case opts[:reduce] do
      nil ->
        if reducer != [], do: IO.warn("Reducer requires `reduce:` option, skipped")
        ast

      acc ->
        if reducer == [] do
          file_error([line: caller.line], caller.file, __MODULE__, :for_with_reduce_bad_block)
        end

        quote(do: Enum.reduce(unquote(ast), unquote(acc), unquote(reducer)))
    end
  end

  @clauses Application.compile_env(:lazy_for, :clause_limit, 18)
  @args for i <- 1..(@clauses + 1),
            into: %{},
            do: {i, Enum.map(1..i, &Macro.var(:"arg_#{&1}", nil))}

  for i <- 1..@clauses do
    @doc false
    [last | rest] = :lists.reverse(@args[i])
    rest = :lists.reverse(rest)

    defmacro stream(unquote_splicing(rest), unquote(last), do: block)
             when not is_list(unquote(last)),
             do: with({_, s} <- reduce_clauses(unquote(@args[i]), block), do: s)
  end

  for i <- 2..@clauses do
    @doc false
    [last | rest] = :lists.reverse(@args[i])
    rest = :lists.reverse(rest)

    defmacro stream(unquote_splicing(rest), unquote(last), do: block)
             when is_list(unquote(last)) do
      unquote(rest) |> reduce_clauses(block) |> do_apply_opts(unquote(last), __CALLER__)
    end

    defmacro stream(unquote_splicing(rest), unquote(last)) do
      {block, opts} = Keyword.pop(unquote(last), :do)
      unquote(rest) |> reduce_clauses(block) |> do_apply_opts(opts, __CALLER__)
    end
  end
end
