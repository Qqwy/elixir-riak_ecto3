defmodule RiakEcto3Test do

  alias RiakEcto3Test.Example.{Repo, User}

  use ExUnit.Case, async: true
  doctest RiakEcto3


  test 'basic get/2 and insert/1' do
    alice = %User{name: "Alice", age: 10, id: 33}

    assert Repo.get(User, "33") == nil
    assert Repo.insert(alice) == {:ok, alice}
    assert Repo.get(User, "33") == alice
  end
end
