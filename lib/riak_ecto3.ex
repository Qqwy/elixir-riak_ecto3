defmodule RiakEcto3 do
  @default_hostname "localhost"
  @default_port 8087

  @moduledoc """
  Riak KV 2.0 adapter for Ecto 3.
  Works by mapping Ecto Schemas to Riak Map-CRDTs.

  NOTE: To use, ensure the following has been executed on your Riak database:

      riak-admin bucket-type create your_database_name '{"props":{"datatype":"map"}}'
      riak-admin bucket-type activate your_database_name

  Here, `your_database_name` refers to any name you'd like the bucket type
  that RiakEcto3 will use to be called. This is the same name you should use
  in your configuration.

  ## Supported Configuration Options:

  - `database:` Name of the `bucket_type` to use for storing all data of this Repo.
     This should be a bucket_type that has the datatype set to `map`.
  - `hostname:` The hostname to connect to. Defaults to `#{@default_hostname}`.
  - `port:` The port to connect to. Defaults to `#{@default_port}`.

  ## Ecto

  RiakEcto3 currently does not use a pool (but this might change in the future).

  ## Queries

  RiakEcto3 only supports `get`.

  (In the future, hopefully we support simple 2i (secondary indexes) as well)

  ## Mix tasks

  ### Storage

  RiakEcto3 only supports the `mix ecto.create` task.
  This task will use `riak-admin` locally to create an appropriate bucket-type
  that uses the `map` CRDT.
  Be aware that `riak-admin` does not use any connection-settings, as it expects
  to be ran on the computer that (one of the nodes of) the database will reside on.

  The `mix ecto.drop` task is not supported, because Riak has no way to
  drop an existing bucket_type.


  """

  @behaviour Ecto.Adapter
  @behaviour Ecto.Adapter.Storage

  @impl Ecto.Adapter
  defmacro __before_compile__(env) do
    # IO.puts "Before Compile of RiakEcto3"

    quote do
      def get(schema_module, id, opts \\ []) do
        {adapter, meta} = Ecto.Repo.Registry.lookup(__MODULE__)
        adapter.get(__MODULE__, meta, schema_module, id, opts)
      end

      def insert(struct_or_changeset, opts \\ []) do
        {adapter, meta} = Ecto.Repo.Registry.lookup(__MODULE__)
        adapter.insert(__MODULE__, meta, struct_or_changeset, opts)
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
  def dumpers(:string, type), do: [type, &RiakEcto3.Dumpers.string/1]
  def dumpers(:id, type), do: [type, &RiakEcto3.Dumpers.integer/1]
  def dumpers(:integer, type), do: [type, &RiakEcto3.Dumpers.integer/1]
  def dumpers(:boolean, type), do: [type, &RiakEcto3.Dumpers.boolean/1]
  def dumpers(:float, type), do: [type, &RiakEcto3.Dumpers.float/1]
  def dumpers(:binary_id, type), do: [type, Ecto.UUID] # TODO is this correct?
  def dumpers(primitive, type) do
    IO.inspect({primitive, type})
    [type]
  end

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
  TODO configurable Riak location
  """
  def init(config) do
    hostname = Keyword.get(config, :hostname, @default_hostname)
    port = Keyword.get(config, :port, @default_port)
    child_spec = %{id: Riak.Connection, start: {Riak.Connection, :start_link, [String.to_charlist(hostname), port]}}
    {:ok, child_spec, %{}}
  end

  @impl Ecto.Adapter
  @doc """
  TODO Properly implement
  """
  def loaders(primitive_type, ecto_type)
  def loaders(:string, type), do: [&RiakEcto3.Loaders.string/1, type]
  def loaders(:id, type), do: [&RiakEcto3.Loaders.integer/1, type]
  def loaders(:integer, type), do: [&RiakEcto3.Loaders.integer/1, type]
  def loaders(:boolean, type), do: [&RiakEcto3.Loaders.boolean/1, type]
  def loaders(:float, type), do: [&RiakEcto3.Loaders.float/1, type]
  def loaders(:binary_id, type), do: [Ecto.UUID, type]
  def loaders(_primitive, type), do: [type]

  @doc """
  Implementation of Repo.get

  Returns `nil` if nothing is found. Returns the structure if something was found.
  Raises an ArgumentError using improperly.
  """
  def get(repo, meta, schema_module, id, opts) do
    source = schema_module.__schema__(:source)
    # {:ok, riak_id} = dump_primary_key(schema_module, id)
    riak_id = "#{id}"
    IO.inspect({meta.pid, repo.config[:database], source, riak_id})
    result = Riak.find(meta.pid, repo.config[:database], source, riak_id)
    case result do
      {:error, problem} -> raise ArgumentError, "Riak error: #{problem}"
      nil -> nil
      riak_map ->
        repo.load(schema_module, load_riak_map(riak_map))
    end
  end

  defp dump_primary_key(schema_module, value) do
    [primary_key | _] = schema_module.__schema__(:primary_key)
    riak_id_type = schema_module.__schema__(:type, primary_key)
    with {:ok, riak_id} <-  Ecto.Type.adapter_dump(__MODULE__, riak_id_type, value) do
      {:ok, riak_id}
    else _ ->
      :error
    end
  end

  defp load_riak_map(riak_map) do
    riak_map
    |> Riak.CRDT.Map.value
    |> Enum.map(fn {{key, value_type}, riak_value} ->
      value = case value_type do
                :register -> riak_value # String
                :counter -> riak_value # TODO
                :flag -> riak_value # TODO
                :map -> raise "Not Implemented"
              end
      {String.to_existing_atom(key), value}
    end)
    |> Enum.into(%{})
  end

  def dump(struct = %schema_module{}) do
    build_riak_map(schema_module, Map.from_struct(struct))
  end

  defp build_riak_map(schema_module, map = %{}) do
    map
    |> Map.to_list
    |> Enum.map(fn {key, value} ->
      type = schema_module.__schema__(:type, key)
      {key, type, value}
    end)
    |> Enum.reject(fn {key, type, _} ->
      type == nil
    end)
    |> IO.inspect
    |> Enum.map(fn {key, type, value} ->
      {:ok, riak_value} = Ecto.Type.adapter_dump(__MODULE__, type, value)
      {Atom.to_string(key), riak_value}
    end)
    |> IO.inspect
    |> Enum.reduce(Riak.CRDT.Map.new, fn {key, value}, riak_map ->
      Riak.CRDT.Map.put(riak_map, key, value)
    end)
  end

  @doc """
  Implementation of Repo.insert

  For now, only works with plain structs.
  (Changeset support is TODO)
  """
  def insert(repo, meta, struct_or_changeset, opts)
  def insert(repo, meta, changeset = %Ecto.Changeset{data: struct = %schema_module{}, changes: changes}, opts) do
    riak_map = build_riak_map(schema_module, changes)

    source = schema_module.__schema__(:source)
    [primary_key | _] = schema_module.__schema__(:primary_key)
    riak_id = "#{Map.fetch!(struct, primary_key)}"

    case do_insert(repo, meta, source, riak_map, riak_id, schema_module, opts) do
      :ok -> {:ok, repo.get(schema_module, riak_id)}
      :error -> {:error, changeset}
    end
  end
  def insert(repo, meta, struct = %schema_module{}, opts) do
    riak_map = dump(struct)

    source = schema_module.__schema__(:source)
    [primary_key | _] = schema_module.__schema__(:primary_key)
    riak_id = "#{Map.fetch!(struct, primary_key)}"

    case do_insert(repo, meta, source, riak_map, riak_id, schema_module, opts) do
      :ok -> {:ok, repo.get(schema_module, riak_id)}
      :error -> {:error, Ecto.Changeset.change(struct)}
    end
  end

  defp do_insert(repo, meta, source, riak_map, riak_id, schema_module, opts) do
    IO.inspect({repo, meta, source, riak_map, riak_id, schema_module, opts})
    case Riak.update(meta.pid, riak_map, repo.config[:database], source, riak_id) do
      {:ok, riak_map} ->
        res = repo.load(schema_module, load_riak_map(riak_map))
        {:ok, res}
      other ->
        other
    end
  end

  @impl Ecto.Adapter.Storage
  def storage_up(config) do
    with {:ok, database} <- Keyword.fetch(config, :database),
         hostname = Keyword.get(config, :hostname, @default_hostname),
         port = Keyword.get(config, :port, @default_port),
         {:ok, pid} <- Riak.Connection.start_link(String.to_charlist(hostname), port),
         {res1, 0} <- System.cmd("riak-admin", ["bucket-type", "create", database, ~s[{"props":{"datatype":"map"}}]]),
         {res2, 0} <- System.cmd("riak-admin", ["bucket-type", "activate", database]) do
      IO.puts res1
      IO.puts res2
      :ok
    else
      {"Error creating bucket type riak3_ecto_test_example:\nalready_active\n", 1} ->
        {:error, :already_up}
      {command_error_string, 1} when is_binary(command_error_string) ->
        IO.inspect(command_error_string, label: "command_error_string")
        {:error, command_error_string}
      error ->
        {:error, error}
    end
  end

  @impl Ecto.Adapter.Storage
  def storage_down(config) do
    with {:ok, database} <- Keyword.fetch(config, :database),
         hostname = Keyword.get(config, :hostname, @default_hostname),
           port = Keyword.get(config, :port, @default_port),
         {:ok, pid} <- Riak.Connection.start_link(String.to_charlist(hostname), port),
           buckets = Riak.Bucket.Type.list!(pid, database) do
      for bucket <- buckets do
        IO.puts "Flushing values in bucket `#{bucket}`"
        keys = Riak.Bucket.keys!(pid, database, bucket)
        n_keys = Enum.count(keys)

        keys
        |> Enum.with_index
        |> Enum.each(fn {key, index} ->
          IO.inspect("Deleting `#{inspect(key)}`")
          Riak.delete(pid, database, bucket, key)
          ProgressBar.render(index + 1, n_keys)
        end)

      end
      IO.puts "NOTE: Riak does not support 'dropping' a bucket type (or buckets contained within), so it has only been emptied."
      :ok
    end
  end
end
