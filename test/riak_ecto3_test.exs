defmodule RiakEcto3Test do

  alias RiakEcto3Test.Example.{Repo, User}

  use ExUnit.Case, async: true
  doctest RiakEcto3
  doctest RiakEcto3Test.Example.Repo # Because documentation and logic is inserted with `__using__`
end
