defmodule RiakEcto3.Loaders do
  def integer(riak_val) do
    case riak_val |> Integer.parse do
      {integer, ""} -> {:ok, integer}
      _ -> :error
    end
  end

  def boolean(riak_val) do
    case riak_val do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
      _ -> :error
    end
  end

  def float(riak_val) do
    case riak_val |> Float.parse do
      {integer, ""} -> {:ok, integer}
      _ -> :error
    end
  end

  def string(riak_val) do
     {:ok, riak_val}
  end

  def id(riak_val) do
    {:ok, riak_val}
  end
end
