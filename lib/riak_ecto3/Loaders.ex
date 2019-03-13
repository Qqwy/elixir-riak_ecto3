defmodule RiakEcto3.Loaders do
  def integer(string) do
    case Integer.parse(string) do
      {integer, ""} -> {:ok, integer}
      _ -> :error
    end
  end

  def boolean("false"), do: {:ok, false}
  def boolean("true"), do: {:ok, true}
  def boolean(_), do: :error

  def float(string) do
    case Float.parse(string) do
      {integer, ""} -> {:ok, integer}
      _ -> :error
    end
  end
end
