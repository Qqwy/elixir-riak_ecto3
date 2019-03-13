defmodule RiakEcto3.Loaders do
  def integer(riak_val) do
    case riak_val |> Riak.CRDT.Register.value |> Integer.parse do
      {integer, ""} -> {:ok, integer}
      _ -> :error
    end
  end

  def boolean(riak_val) do
    case riak_val |> Riak.CRDT.Register.value do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
      _ -> :error
    end
  end

  def float(riak_val) do
    case riak_val |> Riak.CRDT.Register.value |> Float.parse do
      {integer, ""} -> {:ok, integer}
      _ -> :error
    end
  end

  def string(riak_val) do
     {:ok, Riak.CRDT.Register.value(riak_val)}
  end
end
