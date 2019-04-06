defmodule RiakEcto3.Schema do
  defmacro __using__(_) do
    quote do
      # Because in Riak all keys are cast to strings
      # having this as default key type makes shooting your foot less likely
      use Ecto.Schema
      @primary_key {:id, :binary_id, autogenerate: false}
      @foreign_key_type :binary_id
    end
  end
end
