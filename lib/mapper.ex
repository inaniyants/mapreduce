defmodule Mapper do
  def map(line, partition) do
    send(partition, {:process_put, self()})

    Enum.each(String.split(line, " "), fn key ->
      key = String.trim(key, ".")
      send(partition, {:value_put, key})
    end)
  end
end
