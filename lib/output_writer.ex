defmodule OutputWriter do
  def start_link do
    Task.start_link(fn -> loop([], []) end)
  end

  defp loop(processes, values, is_fulfilled \\ false) do
    mailbox_length = elem(Process.info(self(), :message_queue_len), 1)
    if mailbox_length == 0, do: reducer_check(processes, values, is_fulfilled)

    receive do
      {:process_put, caller} ->
        loop([caller | processes], values, is_fulfilled)

      {:value_put, value} ->
        loop(processes, [value | values], is_fulfilled)

      {:fulfill, true} ->
        loop(processes, values, true)
    end
  end

  defp reducer_check(processes, values, true) do
    check = Enum.filter(processes, fn process -> Process.alive?(process) == true end)

    if length(check) == 0 && length(processes) != 0 do
      length(processes) |> IO.inspect(label: "OutputWriter processes")

      {:ok, file} = File.open(Path.join("test", "output.txt"), [:write])

      IO.puts("<Total>: #{length(values)}")
      IO.write(file, "<Total>: #{length(values)}" <> ~s(\n))

      values
      |> Enum.sort_by(&elem(&1, 1))
      |> Enum.reverse()
      |> Enum.each(fn {key, count} ->
        value = "#{key} #{count}"
        IO.puts(value)
        IO.write(file, value <> ~s(\n))
      end)

      File.close(file)
      Process.exit(self(), :kill)
    end
  end

  defp reducer_check(_, _, false) do
  end
end
