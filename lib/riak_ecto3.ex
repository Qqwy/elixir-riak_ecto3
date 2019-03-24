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
      @doc """
      Fetches a struct using the given primary key `id`.

      On success, will return the struct.
      On failure (if the struct does not exist within the Riak database), returns `nil`.

      iex> alice = %User{name: "Alice", age: 10, id: 33}
      iex> Repo.get(User, "33") == nil
      true
      iex> {:ok, %User{name: "Alice", age: 10, id: 33}} = Repo.insert(alice)
      iex> %user{name: "Alice", age: 10, id: 33} = Repo.get(User, "33")
      iex> {:ok, %User{name: "Alice", age: 10, id: 33}} = Repo.delete(alice)
      iex> Repo.get(User, "33") == nil
      true

      """
      def get(schema_module, id, opts \\ []) do
        {adapter, meta} = Ecto.Repo.Registry.lookup(__MODULE__)
        adapter.get(__MODULE__, meta, schema_module, id, opts)
      end

      @doc """
      Inserts (or updates) a struct in the database.
      Pass either a struct or an `Ecto.Changeset`

      On success, will return `{:ok, struct}`.
      On failure (when there were validation problems for instance), will return `{:error, struct_or_changeset}`
      """
      def insert(struct_or_changeset, opts \\ []) do
        {adapter, meta} = Ecto.Repo.Registry.lookup(__MODULE__)
        adapter.insert(__MODULE__, meta, struct_or_changeset, opts)
      end

      @doc """
      Deletes a struct from the database, using the primary ID of the struct or changeset
      passed to this function.

      Returns `{:ok, struct}` on success.
      Raises `Ecto.NoPrimaryKeyValueError` if the passed struct or changeset does not have a primary key set.
      """
      def delete(struct_or_changeset, opts \\ []) do
        {adapter, meta} = Ecto.Repo.Registry.lookup(__MODULE__)
        adapter.delete(__MODULE__, meta, struct_or_changeset, opts)
      end

      @doc """
      Allows you to perform a raw SOLR query on a given Schema module.

      See https://docs.riak.com/riak/kv/2.2.3/developing/usage/search/index.html
      and https://docs.riak.com/riak/kv/2.2.3/developing/usage/searching-data-types.1.html#data-types-and-search-examples

      for more information and syntax.

      A query is prefixed to constrain it to the given schema module's bucket (in the database's bucket type).

      The response of this will either be `{:error, problem}` or `{:ok, results}`
      where `results` will be a list of maps.
      Each of these maps has a `:meta`-key containing the raw SOLR result for that resource,
      and a `:resource` key, which is a 0-arity function that will fetch the given resource from the repo when called.

      Example:

          iex> bob = %User{name: "Bob", id: 42, age: 41}
          iex> {:ok, _} = Repo.insert(bob)
          iex> :timer.sleep(1000) # It takes 'typically a second' before SOLR is able to see changes.
          iex> {:ok, results} = Repo.raw_solr_query(RiakEcto3Test.Example.User, "age_register:[40 TO 41]")
          iex> results |> Enum.map(fn elem -> elem.resource.() end) |> Enum.any?(fn user -> user.name == "Bob" end)
          true
      """
      def raw_solr_query(schema_module, query, solr_opts \\ []) do
        {adapter, meta} = Ecto.Repo.Registry.lookup(__MODULE__)
        adapter.raw_solr_query(__MODULE__, meta, schema_module, query, solr_opts)
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
    |> Enum.map(fn {key, type, value} ->
      {:ok, riak_value} = Ecto.Type.adapter_dump(__MODULE__, type, value)
      {Atom.to_string(key), riak_value}
    end)
    |> Enum.reduce(Riak.CRDT.Map.new, fn {key, value}, riak_map ->
      Riak.CRDT.Map.put(riak_map, key, value)
    end)
  end

  @doc """
  Implementation of Repo.insert
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
    case Riak.update(meta.pid, riak_map, repo.config[:database], source, riak_id) do
      {:ok, riak_map} ->
        res = repo.load(schema_module, load_riak_map(riak_map))
        {:ok, res}
      other ->
        other
    end
  end

  @doc """
  Implementation of Repo.delete
  """
  def delete(repo, meta, struct_or_changeset, opts)
  def delete(_repo, _meta, changeset = %Ecto.Changeset{valid?: false}, _opts) do
    {:error, changeset}
  end
  def delete(repo, meta, changeset = %Ecto.Changeset{data: struct = %schema_module{}}, opts) do
    delete(repo, meta, struct, opts)
  end

  def delete(repo, meta, struct = %schema_module{}, opts) do
    source = schema_module.__schema__(:source)
    [primary_key | _] = schema_module.__schema__(:primary_key)
    riak_id = "#{Map.fetch!(struct, primary_key)}"
    if riak_id == "" do
      raise Ecto.NoPrimaryKeyValueError
    end

    case Riak.delete(meta.pid, repo.config[:database], source, riak_id) do
      :ok -> {:ok, struct}
      :error -> raise Ecto.StaleEntryError
    end
  end

  def raw_solr_query(repo, meta, schema_module, query, solr_opts) do
    require Logger

    source = schema_module.__schema__(:source)
    database = repo.config[:database]
    compound_query = ~s[_yz_rt:"#{database}" AND _yz_rb:"#{source}" AND #{query}]
    index = "#{database}_index"
    case Riak.Search.query(meta.pid, index, compound_query, solr_opts) do
      {:error, problem} ->
        Logger.debug("Solr Query that was executed: #{compound_query}")
        {:error, problem}
      {:ok, {:search_results, results, _max_score, _num_found}} ->
        results =
          results
          |> Enum.map(fn {index_name, properties} ->
          meta = Enum.into(properties, %{})
          resource = fn -> repo.get(schema_module, meta["_yz_rk"]) end
          %{meta: meta, resource: resource}
        end)
        {:ok, results}
    end
  end


  @impl Ecto.Adapter.Storage
  def storage_up(config) do
    require Logger
    {:ok, database} = Keyword.fetch(config, :database)
    already_exists_binary = "Error creating bucket type #{database}:\nalready_active\n"
    with hostname = Keyword.get(config, :hostname, @default_hostname),
         port = Keyword.get(config, :port, @default_port),
         {:ok, pid} <- Riak.Connection.start_link(String.to_charlist(hostname), port),
           Logger.info("Creating bucket type `#{database}`..."),
         {res1, 0} <- System.cmd("riak-admin", ["bucket-type", "create", database, ~s[{"props":{"datatype":"map"}}]]),
           Logger.info("Activating Bucket Type `#{database}`..."),
         {res2, 0} <- System.cmd("riak-admin", ["bucket-type", "activate", database]),
           database_index = "#{database}_index",
           Logger.info("Creating Search Index `#{database_index}`..."),
           :ok <- Riak.Search.Index.put(pid, database_index),
           Logger.info("Associating Search Index `#{database_index}`with bucket type `#{database}`..."),
           :ok <- Riak.Bucket.Type.put(pid, database, search_index: database_index)
      do
      IO.puts res1
      IO.puts res2
      :ok
    else
      {^already_exists_binary, 1} ->
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
    require Logger
    with {:ok, database} <- Keyword.fetch(config, :database),
         hostname = Keyword.get(config, :hostname, @default_hostname),
           port = Keyword.get(config, :port, @default_port),
         {:ok, pid} <- Riak.Connection.start_link(String.to_charlist(hostname), port),
           buckets = Riak.Bucket.Type.list!(pid, database) do
      for bucket <- buckets do
        Logger.info "Flushing values in bucket `#{bucket}`"
        keys = Riak.Bucket.keys!(pid, database, bucket)
        n_keys = Enum.count(keys)

        keys
        |> Enum.with_index
        |> Enum.each(fn {key, index} ->
          Riak.delete(pid, database, bucket, key)
          ProgressBar.render(index + 1, n_keys)
        end)
      end
      Logger.info "NOTE: Riak does not support 'dropping' a bucket type (or buckets contained within), so this task has only removed all data contained within them."
      :ok
    end
  end
end
