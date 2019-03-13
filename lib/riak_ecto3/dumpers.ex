defmodule RiakEcto3.Dumpers do
  def integer(int) do
    {:ok, Integer.to_string(int) |> Riak.CRDT.Register.new}
  end

  def boolean(false), do: {:ok, "false" |> Riak.CRDT.Register.new}
  def boolean(true), do: {:ok, "true" |> Riak.CRDT.Register.new}

  def float(float) do
    {:ok, Float.to_string(float) |> Riak.CRDT.Register.new}
  end

  def string(string) do
    {:ok, Riak.CRDT.Register.new(string)}
  end
end
