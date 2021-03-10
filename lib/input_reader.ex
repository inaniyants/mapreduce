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
        lines = Regex.split(~r/\r|\n|\r\n/, String.trim(body))

        Enum.each(lines, fn line ->
          spawn(fn -> Mapper.map(line, partition) end)
        end)

        mapper_processes_cnt = length(lines)
        IO.puts("Mapper processes #{mapper_processes_cnt}")

        send(partition, {:fulfill, {true, mapper_processes_cnt}})

      {:error, reason} ->
        IO.puts(:stderr, "File Error: #{reason}")
    end
  end
end
