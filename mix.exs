defmodule RiakEcto3.MixProject do
  use Mix.Project

  def project do
    [
      app: :riak_ecto3,
      version: "0.5.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env),
      aliases: aliases(),
      description: description(),
      package: package(),
      source_url: "https://github.com/Qqwy/elixir_riak_ecto3",
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:earmark, ">= 0.0.0", only: [:dev, :docs]},    # Markdown, dependency of ex_doc
      {:ex_doc, "~> 0.11", only: [:dev, :docs]}, # Documentation for Hex.pm
      {:inch_ex, ">= 0.0.0", only: [:docs]},     # Inch CI documentation quality test.

      {:ecto, "~> 3.0"},
      {:riak, "~> 1.0"},
      {:progress_bar, "~> 2.0"} # Used for progress indicators during mix DB-creation/deletion tasks.

    ]
  end

  # Ensures `test/support/*.ex` files are read during tests
  defp elixirc_paths(:test), do: ["lib", "test/example"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      travis: ["test"],
      # Ensures database is reset before tests are run
      # test: ["ecto.create --quiet", "test", "ecto.drop --quiet"],
    ]
  end


  defp description do
    """
    Ecto 3 Adapter for the Riak KV database (v 2.0 and upward), representing schemas as CRDTs.
    """
  end

  defp package do
    [# These are the default files included in the package
      name: :riak_ecto3,
      files: ["lib", "mix.exs", "README*", "LICENSE"],
      maintainers: ["Wiebe-Marten Wijnja/Qqwy"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Qqwy/elixir_riak_ecto3/"}
    ]
  end

end
