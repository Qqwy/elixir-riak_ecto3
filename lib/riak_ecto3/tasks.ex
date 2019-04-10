defmodule Mix.Tasks.RiakEcto3 do
  defmodule CreateSearchIndex do
    use Mix.Task

    @shortdoc "Only creates the search index without setting up the whole database bucket type."

    @impl Mix.Task
    def run([database_name, hostname, port]) do
      RiakEcto3.create_search_index(database_name, hostname, port)
    end
  end
end
