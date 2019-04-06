defmodule RiakEcto3Test.Example.Repo do
  use Ecto.Repo, otp_app: :riak_ecto3, adapter: RiakEcto3, database: "riak_ecto3_test_repo"
end

defmodule RiakEcto3Test.Example.User do
  use RiakEcto3.Schema
  schema "users" do
    field :name, :string
    field :age, :integer
  end
end

