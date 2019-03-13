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
        {adapter, meta} = Ecto.Repo.Registry.lookup(__MODULE__)
        adapter.get(meta, struct_name, id, opts)
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
  def dumpers(:string, type), do: [type]
  def dumpers(:integer, type), do: [type, &RiakEcto3.Dumpers.integer/1]
  def dumpers(:boolean, type), do: [type, &RiakEcto3.Dumpers.boolean/1]
  def dumpers(:float, type), do: [type, &RiakEcto3.Dumpers.float/1]
  def dumpers(:binary_id, type), do: [type, Ecto.UUID] # TODO is this correct?
  def dumpers(_primitive, type), do: [type]

  @impl Ecto.Adapter
  @doc """
  TODO double-check implementation
  """
  def ensure_all_started(config, app_restart_type) do
    with {:ok, from_driver} <- Application.ensure_all_started(:riak, app_restart_type), do:
    # We always return the adapter to force it to be restarted if necessary, because this is what `ecto_sql` also does.
    # See: https://github.com/elixir-ecto/ecto_sql/blob/master/lib/ecto/adapters/sql.ex#L420
    {:ok, (List.delete(from_driver, :riak) ++ [:riak])}
  end

  @impl Ecto.Adapter
  @doc """
  TODO double-check implementation
  """
  def init(config) do
    child_spec = %{id: Riak.Connection, start: {Riak.Connection, :start_link, []}}
    {:ok, child_spec, %{}}
  end

  @impl Ecto.Adapter
  @doc """
  TODO Properly implement
  """
  def loaders(primitive_type, ecto_type)
  def loaders(:string, type), do: [type]
  def loaders(:integer, type), do: [&RiakEcto3.Loaders.integer/1, type]
  def loaders(:boolean, type), do: [&RiakEcto3.Loaders.boolean/1, type]
  def loaders(:float, type), do: [&RiakEcto3.Loaders.float/1, type]
  def loaders(:binary_id, type), do: [Ecto.UUID, type]
  def loaders(_primitive, type), do: [type]

  def get(meta, struct_name, id, opts) do
    Riak.find(meta.pid, struct_name, id)
  end
end
