# RiakEcto3

RiakEcto3 is an Ecto 3 Adapter for the Riak KV database (v 2.0 and upward).

## Features

- Structs are serialized as Riak CRDT Data Types.
- `Repo.get`  and `Repo.insert/update`

## Planned Features

- Support for Secondary Indexes (2i) to allow rudimentary searching functionality.
- Support for associations
  - and preloading them.
- Support for the Counter, Set and Flag CRDT datatypes.

## (For now) deliberatly not planned as features

- Support for searching with Solr, because it is better to have a small library with a couple of stable features, than a large library with only many unstable features.

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

