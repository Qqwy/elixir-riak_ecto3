defmodule RiakEcto3Test do

  alias RiakEcto3Test.Example.{Repo, User}

  use ExUnit.Case, async: true
  doctest RiakEcto3


  test 'basic get/2, insert/1 and delete/1' do
    alice = %User{name: "Alice", age: 10, id: 33}

    assert Repo.get(User, "33") == nil
    assert {:ok, %User{name: "Alice", age: 10, id: 33}} = Repo.insert(alice)
    assert %user{name: "Alice", age: 10, id: 33} = Repo.get(User, "33")
    assert {:ok, %User{name: "Alice", age: 10, id: 33}} = Repo.delete(alice)
    assert Repo.get(User, "33") == nil
  end
end
