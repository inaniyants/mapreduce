defmodule InputReader do
  require Mapper

  @spec reader(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | char,
              binary | []
            ),
          any
        ) :: :ok
  def reader(file, partition) do
    case File.read(file) do
      {:ok, body} ->
        Enum.each(Regex.split(~r/\r|\n|\r\n/, String.trim(body)), fn line ->
          spawn(fn -> Mapper.map(line, partition) end)
        end)

        send(partition, {:fulfill, true})

      {:error, reason} ->
        IO.puts(:stderr, "File Error: #{reason}")
    end
  end
end
