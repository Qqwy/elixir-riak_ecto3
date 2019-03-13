defmodule RiakEcto3Test do
  use ExUnit.Case
  doctest RiakEcto3

  defmodule Repo do
    use Ecto.Repo, otp_app: :riak_ecto3, adapter: RiakEcto3
  end

  defmodule User do
    use Ecto.Schema
    schema "users" do
      field :name, :string
      field :age, :integer
    end
  end

  alice = %User{name: "Alice", age: 10, id: 33}
end
