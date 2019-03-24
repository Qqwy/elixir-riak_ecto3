defmodule Riak3TestRepo do
  use Ecto.Repo, otp_app: :riak_ecto3, adapter: RiakEcto3, database: "riak_ecto3_test_repo"
end

defmodule User do
  use Ecto.Schema
  schema "users" do
    field :name, :string
    field :age, :integer
  end
end

Riak3TestRepo.start_link()
ExUnit.start()
