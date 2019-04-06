# RiakEcto3

[![hex.pm version](https://img.shields.io/hexpm/v/riak_ecto3.svg)](https://hex.pm/packages/map_diff)
[![Build Status](https://travis-ci.org/Qqwy/elixir_riak_ecto3.svg?branch=master)](https://travis-ci.org/Qqwy/elixir_riak_ecto3)
[![Inline docs](http://inch-ci.org/github/qqwy/elixir_riak_ecto3.svg)](http://inch-ci.org/github/qqwy/elixir_riak_ecto3)


RiakEcto3 is an Ecto 3 Adapter for the Riak KV database (v 2.0 and upward).

## Features

- Structs are serialized as Riak CRDT Data Types.
- `Repo.get`  and `Repo.insert/update`
- `Repo.delete`
- Executing raw Solr queries
- Finding a key within a range of keys (which relies on Riak's Secondary Indexes feature).
- Very basic repository creation and 'deletion' (actually: flushing) support.

## Planned Features

- Support for associations
  - and preloading them.
- Support for the Counter, Set and Flag CRDT datatypes.

## (For now) deliberatly not planned as features

- Support for the rest of Secondary Indexes, because these are deprecated and custom indexes cannot be created for CRDTs.
- Complete query-support for Solr.

## Installation

As soon as [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `riak_ecto3` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:riak_ecto3, "~> 0.5.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/riak_ecto3](https://hexdocs.pm/riak_ecto3).

## Running Tests

The tests expect Riak to be running in localhost at its default port (8087).
- Some of the features of RiakEcto3 require that searching is turned on, (the `search` setting in `riak.conf`)
- Some features (The ones that require secondary indexes) require that either the 'leveldb' or 'memory'-backend is used. (The `storage_backend` setting in `riak.conf`)
- Besides this, there are no restrictions when running the tests.

