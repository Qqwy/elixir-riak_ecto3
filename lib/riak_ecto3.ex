defmodule RiakEcto3 do
  @moduledoc """
  Riak KV 2.0 adapter for Ecto 3.
  Works by mapping Ecto Schemas to Riak Map-CRDTs.
  """

  @behaviour Ecto.Adapter

  @impl Ecto.Adapter
  defmacro __before_compile__(env) do
    IO.puts "Before Compile of RiakEcto3"

    quote do
      def get(struct_name, id, opts \\ []) do
        IO.puts "TODO: Implement Repo.get for Riak: (1) struct_name -> Riak bucket name. (2) id -> Riak key name!"
      end
    end
  end

  @impl Ecto.Adapter
  @doc """
  NOTE: Currently we are not using the connection pool to keep the implementation simple.
  This could be changed later since `Riak` provides one.
  """
  def checkout(adapter_meta, config, fun) do
    fun.()
  end

  @impl Ecto.Adapter
  @doc """
  TODO Properly implement
  """
  def dumpers(primitive_type, ecto_type)
  def dumpers(:binary_id, type), do: [type, Ecto.UUID]
  def dumpers(_primitive, type), do: [type]

  @impl Ecto.Adapter
  @doc """
  TODO double-check implementation
  """
  def ensure_all_started(config, app_restart_type) do
    {:ok, []}
  end

  @impl Ecto.Adapter
  @doc """
  TODO double-check implementation
  """
  def init(config) do
    {:ok, Supervisor.child_spec(Riak.Connection, [])}
  end

  @impl Ecto.Adapter
  @doc """
  TODO Properly implement
  """
  def loaders(primitive_type, ecto_type)
  def loaders(:binary_id, type), do: [Ecto.UUID, type]
  def loaders(_primitive, type), do: [type]
end
