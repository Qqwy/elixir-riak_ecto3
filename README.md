# RiakEcto3

RiakEcto3 is an Ecto 3 Adapter for the Riak KV database (v 2.0 and upward).

## Features

- Structs are serialized as Riak CRDT Data Types.
- `Repo.get`  and `Repo.insert/update`
- Support for `Repo.delete`
- Usage of raw Solr-queries with `Repo.raw_solr_query/2`.
- Setting up a Riak bucket type ('database')
- 'Tearing down' a Riak bucket type ('database'): It will only be flushed because Riak does not support the actual dropping of a bucket or bucket type.

## Planned Features


- Support for Secondary Indexes (2i) to allow rudimentary searching functionality.
- Support for associations
  - and preloading them.
- Support for the Counter, Set and Flag CRDT datatypes.
- (Maybe!) a converter for the Ecto query syntax into the Solr query syntax.

## Installation

As soon as [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `riak_ecto3` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:riak_ecto3, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/riak_ecto3](https://hexdocs.pm/riak_ecto3).

