defmodule Partition do
  require Reducer
  require OutputWriter

  def start_link do
    Task.start_link(fn -> loop([], []) end)
  end

  defp loop(processes, values, is_fulfilled \\ false) do
    mailbox_length = elem(Process.info(self(), :message_queue_len), 1)

    if mailbox_length === 0 do
      mapper_check(
        processes,
        Keyword.delete(Keyword.delete(values, String.to_atom(~s(\s))), String.to_atom("")),
        is_fulfilled
      )
    end

    receive do
      {:process_put, caller} ->
        loop([caller | processes], values, is_fulfilled)

      {:value_put, key} ->
        loop(processes, [{String.to_atom(key), 1} | values], is_fulfilled)

      {:fulfill, true} ->
        loop(processes, values, true)

      error ->
        IO.puts(:stderr, "Partition Error: #{error}")
    end
  end

  defp mapper_check(processes, values, true) do
    check =
      length(processes) > 0 &&
        Enum.filter(processes, fn process -> Process.alive?(process) == true end) |> length() ===
          0

    if check do
      length(processes) |> IO.inspect(label: "Partition processes")

      output_writer = elem(OutputWriter.start_link(), 1)
      uniques = Enum.uniq(Keyword.keys(values))

      Enum.each(uniques, fn unique ->
        spawn(fn ->
          Reducer.reduce(Keyword.to_list(Keyword.take(values, [unique])), output_writer)
        end)
      end)

      send(output_writer, {:fulfill, true})
    end
  end

  defp mapper_check(_, _, false) do
  end
end
