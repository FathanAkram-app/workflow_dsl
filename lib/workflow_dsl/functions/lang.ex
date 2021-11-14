defmodule WorkflowDsl.Lang do

  alias WorkflowDsl.Storages
  alias WorkflowDsl.ListMapExprParser

  #require Logger

  # eval for math
  def eval(session, {:mul, [val0, val1]}), do: eval(session, val0) * eval(session, val1)
  def eval(session, {:div, [val0, val1]}), do: eval(session, val0) / eval(session, val1)
  def eval(session, {:sub, [val0, val1]}), do: eval(session, val0) - eval(session, val1)
  def eval(session, {:rem, [val0, val1]}), do: rem(eval(session, val0), eval(session, val1))
  def eval(session, {:flr, [val0, val1]}), do: floor(eval(session, val0) / eval(session, val1))
  def eval(session, {:vars, [val0, val1]}) do
    {:ok, names, _, _, _, _} = ListMapExprParser.parse_list_map(val0 <> val1)
    #Logger.log(:debug, "names: #{inspect names}")

    result =
    cond do
      Kernel.length(names) == 1 ->
        eval(session, {:vars, [val0 <> val1]})

      true ->
        # construct the key and the values
        #Logger.log(:debug, "start construct: #{inspect names}")

        Enum.reduce(names, nil, fn it, acc ->
          #Logger.log(:debug, "acc: #{inspect acc}, it: #{inspect it}")

          cond do
            acc == nil -> eval(session, it)
            is_list(acc) ->
              #Logger.log(:debug, "type: list")
              case Enum.at(acc, 0) do
                [_, _] ->
                  map = Enum.into(acc, %{}, fn [k, v] -> {k, v} end)
                  k = if not Map.has_key?(map, eval(session, it)), do: String.to_atom(eval(session, it)), else: eval(session, it)
                  map[k]
                _ ->
                  acc[eval(session, it)]
              end
            is_map(acc) ->
              #Logger.log(:debug, "type: map")
              key =
              case eval(session, it) do
                nil ->
                  {:vars, n} = it
                  Enum.join(n)
                k -> k
              end
              k = if not Map.has_key?(acc, key), do: String.to_atom(key), else: key
              acc[k]
            true ->
              #Logger.log(:debug, "type: default")
              eval(session, it)
          end
        end)
    end
    #Logger.log(:debug, "vars result: #{inspect result}")
    result
  end
  def eval(session, {:add, [val0, val1]}) do
    eval0 = eval(session, val0)
    eval1 = eval(session, val1)
    if is_binary(eval0) and is_binary(eval1), do: eval0 <> eval1, else: eval0 + eval1
  end
  def eval(_session, {:int, [val]}), do: val
  def eval(session, {:int, [_, var]}) do
    val = eval(session, var)
    if is_binary(val), do: String.to_integer(val), else: val
  end
  def eval(_session, {:double, [val]}), do: String.to_float(val)
  def eval(session, {:double, ["double", var]}) do
    val = eval(session, var)
    if is_binary(val), do: String.to_float(val), else: val
  end
  def eval(_session, {:str, [val]}), do: to_string(val)
  def eval(session, {:str, ["string", var]}) do
    val = eval(session, var)
    if is_binary(val), do: val, else: to_string(val)
  end
  def eval(_session, {:bool, [val]}), do: String.to_existing_atom(String.downcase(val))
  def eval(session, {:vars, [val]}) do
    var = Storages.get_var_by(%{"session" => session, "name" => val})
    case var do
      nil -> nil
      v -> :erlang.binary_to_term(v.value)
    end
  end
  def eval(session, {:neg_vars, [val]}) do
    -eval(session, val)
  end

  # implement eval for cond
  def eval(session, {:eq, [val0, val1]}) do
    eval(session, val0) == eval(session, val1)
  end
  def eval(session, {:neq, [val0, val1]}) do
    eval(session, val0) != eval(session, val1)
  end
  def eval(session, {:or, [val0, val1]}) do
    eval(session, val0) or eval(session, val1)
  end
  def eval(session, {:and, [val0, val1]}) do
    eval(session, val0) and eval(session, val1)
  end
  def eval(session, {:gt, [val0, val1]}) do
    eval(session, val0) > eval(session, val1)
  end
  def eval(session, {:gte, [val0, val1]}) do
    eval(session, val0) >= eval(session, val1)
  end
  def eval(session, {:lt, [val0, val1]}) do
    eval(session, val0) < eval(session, val1)
  end
  def eval(session, {:lte, [val0, val1]}) do
    eval(session, val0) <= eval(session, val1)
  end

end