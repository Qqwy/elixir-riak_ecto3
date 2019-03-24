defmodule RiakEcto3Test do
  use ExUnit.Case, async: true
  doctest RiakEcto3


  test 'basic get/2 and insert/1' do
    alice = %User{name: "Alice", age: 10, id: 33}

    assert Riak3TestRepo.get(User, 33) == nil
    assert Riak3TestRepo.insert(alice) == {:ok, alice}
    assert Riak3TestRepo.get(User, 33) == alice
  end
end
