defmodule RiakEcto3.Dumpers do
  def integer(int) do
    {:ok, Integer.to_string(int)}
  end

  def boolean(false), do: {:ok, "false"}
  def boolean(true), do: {:ok, "true"}

  def float(float) do
    {:ok, Float.to_string(float)}
  end
end
