defmodule SumMag do
  @moduledoc """
  SumMag: a meta-programming library for Pelemay and Cockatorice.
  """

  @doc """
      ## Examples
      iex> quote do end |> SumMag.parse(%{target: :pelemay})
      []

      iex> (quote do: def func(a), do: a) |> SumMag.parse(%{target: :pelemay})
      [[function_name: :func, is_public: true, args: [:a], do: [{:a, [], SumMagTest}], is_nif: false ]]

      iex> (quote do
      ...>    def func(list) do
      ...>      list
      ...>      |> Enum.map(& &1)
      ...>    end
      ...> end) |> SumMag.parse(%{target: :pelemay})
      [[function_name: :func, is_public: true, args: [:list], do: [{:|>, [context: SumMagTest, import: Kernel], [{:list, [], SumMagTest}, {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [], [{:&, [], [{:&, [], [1]}]}]}]}], is_nif: false ]]
  """
  def parse({:__block__, _e, []}, _env), do: []

  def parse({:def, _e, body}, env) do
    [
      [
        function_name: parse_function_name(body, env),
        is_public: true,
        args: parse_args(body, env),
        do: parse_do(body, env),
        is_nif: false
      ]
    ]
  end

  def parse({:defp, _e, body}, env) do
    [
      [
        function_name: parse_function_name(body, env),
        is_public: false,
        args: parse_args(body, env),
        do: parse_do(body, env),
        is_nif: false
      ]
    ]
  end

  @doc """
    ## Examples

    iex> [{:null, [context: Elixir], []}, [do: {:nil, [], Elixir}]] |> SumMag.parse_function_name(%{})
    :null

    iex> [{:func, [context: Elixir], [{:a, [], Elixir}]}, [do: {:a, [], Elixir}]] |> SumMag.parse_function_name(%{})
    :func

    iex> [{:add, [context: Elixir], [{:a, [], Elixir}, {:b, [], Elixir}]},[do: {:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]] |> SumMag.parse_function_name(%{})
    :add
  """
  def parse_function_name(body, _env), do: body |> hd |> elem(0)

  @doc """
    ## Examples

    iex> [{:null, [context: Elixir], []}, [do: {:nil, [], Elixir}]] |> SumMag.parse_args(%{})
    []

    iex> [{:func, [context: Elixir], [{:a, [], Elixir}]}, [do: {:a, [], Elixir}]] |> SumMag.parse_args(%{})
    [:a]

    iex> [{:add, [context: Elixir], [{:a, [], Elixir}, {:b, [], Elixir}]},[do: {:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]] |> SumMag.parse_args(%{})
    [:a, :b]
  """
  def parse_args(body, env) do
    body
    |> hd
    |> elem(2)
    |> convert_args(env)
  end

  @doc """
    ## Examples

    iex> [] |> SumMag.convert_args(%{})
    []

    iex> [{:a, [], Elixir}] |> SumMag.convert_args(%{})
    [:a]

    iex> [{:a, [], Elixir}, {:b, [], Elixir}] |> SumMag.convert_args(%{})
    [:a, :b]
  """
  def convert_args(arg_list, _env), do: arg_list |> Enum.map(&elem(&1, 0))

  @doc """
    ## Examples

    iex> [{:null, [context: Elixir], []}, [do: {:nil, [], Elixir}]] |> SumMag.parse_do(%{})
    [{:nil, [], Elixir}]

    iex> [{:func, [context: Elixir], [{:a, [], Elixir}]}, [do: {:a, [], Elixir}]] |> SumMag.parse_do(%{})
    [{:a, [], Elixir}]

    iex> [{:add, [context: Elixir], [{:a, [], Elixir}, {:b, [], Elixir}]},[do: {:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]] |> SumMag.parse_do(%{})
    [{:+, [context: Elixir, import: Kernel], [{:a, [], Elixir}, {:b, [], Elixir}]}]
  """
  def parse_do(body, env) do
    body
    |> tl
    |> hd
    |> hd
    |> parse_do_block(env)
  end

  defp parse_do_block({:do, do_body}, env), do: parse_do_body(do_body, env)

  defp parse_do_body({:__block__, _e, []}, _env), do: []

  defp parse_do_body({:__block__, _e, body_list}, env) do
    body_list
    |> Enum.map(
      &(&1
        |> parse_do_body(env)
        |> hd())
    )
  end

  defp parse_do_body(value, _env), do: [value]

  @doc """
    ## Examples

    iex> SumMag.increment_nif(%{num: 0})
    1

    iex> SumMag.increment_nif(%{num: 1})
    2
  """
  def increment_nif(%{num: num}) do
    num + 1
  end

  @doc """
    ## Examples

    iex> :func |> SumMag.concat_name_num(%{num: 1})
    :func_1

    iex> :fl |> SumMag.concat_name_num(%{num: 2})
    :fl_2
  """
  def concat_name_num(name, %{num: num}) do
    name |> Atom.to_string() |> Kernel.<>("_#{num}") |> String.to_atom()
  end

  @doc """
    ## Examples

    iex> :func |> SumMag.concat_name_nif(%{})
    :func_nif
  """
  def concat_name_nif(name, _env) do
    name |> Atom.to_string() |> Kernel.<>("_nif") |> String.to_atom()
  end

  @doc """
    ## Examples

    iex> :pelemay |> SumMag.concat_name_stub(%{})
    :pelemaystub
  """
  def concat_name_stub(name, _env) do
    name |> Atom.to_string() |> Kernel.<>("stub") |> String.to_atom()
  end

  @doc """
    ## Examples

    iex> SumMag.func_with_num([function_name: :func], %{num: 1})
    [function_name: :func_1]
  """
  def func_with_num(kl, env) do
    Keyword.put(kl, :function_name, kl[:function_name] |> SumMag.concat_name_num(env))
  end

  @doc """
    ## Examples

    iex> SumMag.get_func_info(%{nif: [function_name: :func]})
    [function_name: :func]
  """
  def get_func_info(%{nif: func_info}), do: func_info

  @doc """
    ## Examples

    iex> SumMag.merge_func_info(%{nif: [function_name: :func]}, [is_public: true])
    %{nif: [function_name: :func, is_public: true]}
  """
  def merge_func_info(env, keyword) do
    Map.put(env, :nif, Keyword.merge(get_func_info(env), keyword))
  end

  @doc """
  "defmacro do" take the following code.

  If you define a function:

  ```
  [ 
    do: {def, _line, [
      { :name, _line, arg },
      [
        do: main_process
      ]}
  ]
  ```      

  If you define functions:
  ```
  [ 
    do: {:__block__, [], [
      {def, _line, [{ :name, _line, arg },do: main_process
      ]}
  ]
  ```

        iex> quote do  
        ...>   def func do: "doctest"    
        ...> end  
        {:def, [context: SumMagTest, import: Kernel],
          [{:func, [context: SumMagTest], [[do: "doctest"]]}]}

        iiex> quote do
        ...>   defmmf do
        ...>     def func do: "doctest"
        ...>   end
        ...> end 
        
  """
  def melt_block(do: {:__block__, [], []}), do: []
  def melt_block(do: {:__block__, [], funcs}), do: funcs
  def melt_block(do: func), do: [func]
  def melt_block(other), do: other

  defp iced_block([func]), do: [do: func]
  defp iced_block(funcs), do: [do: {:__block__, [], funcs}]

  # @spec map(ast, element -> any))) :: ast
  def map(definitions, optimizer) when is_function(optimizer) do
    definitions
    |> melt_block
    |> Enum.map(&optimize_func(&1, optimizer))
    |> iced_block
  end

  defp optimize_func({def_key, meta, [arg_info, exprs]}, optimizer) do
    case def_key do
      :def -> {:def, meta, [arg_info, optimize_exprs(exprs, optimizer)]}
      :defp -> {:defp, meta, [arg_info, optimize_exprs(exprs, optimizer)]}
      _ -> raise ArgumentError
    end
  end

  defp optimize_exprs(exprs, optimizer) do
    exprs
    |> melt_block
    |> Enum.map(&apply_optimizer(&1, optimizer))
    |> iced_block
  end

  defp apply_optimizer(expr, optimizer) do
    expr
    |> Macro.unpipe()
    |> Enum.map(fn {expr, pos} ->
      {optimizer.(expr), pos}
    end)
    |> pipe
  end

  defp pipe(unpipe_list) do
    # Following code from `|>` definition

    [{h, _} | t] = unpipe_list

    fun = fn {x, pos}, acc ->
      Macro.pipe(acc, x, pos)
    end

    :lists.foldl(fun, h, t)
  end

  def quoted_var?({:&, _, [1]}) do
    true
  end

  def quoted_var?({atom, _meta, nil})
      when atom |> is_atom do
    true
  end

  def quoted_var?({atom, [], _context})
      when atom |> is_atom do
    true
  end

  def quoted_var?(other) when other |> is_number, do: true

  def quoted_var?(_other), do: false

  def quoted_vars?(left, right) do
    quoted_var?(left) && quoted_var?(right)
  end

  def divide_meta(ast) do
    ast
    |> Macro.prewalk([], fn
      {atom, meta, tree}, acc -> {{atom, tree}, acc ++ meta}
      other, acc -> {other, acc}
    end)
  end

  def delete_meta(ast) do
    ast
    |> Macro.prewalk(fn
      {atom, _meta, tree} -> {atom, tree}
      other -> other
    end)
  end
end
