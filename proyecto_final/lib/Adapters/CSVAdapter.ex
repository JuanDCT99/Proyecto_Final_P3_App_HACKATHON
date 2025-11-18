defmodule Adapters.CSVAdapter do
  @moduledoc """
  Adapter para archivos CSV
  """
  def read(path) do
    case File.read(path) do
      {:ok, content} ->
        lines =
          content
          |> String.split("\n", trim: true)
          |> Enum.map(&String.split(&1, ","))

        case lines do
          [header | rows] -> {:ok, {header, rows}}
          [] -> {:ok, {[], []}}
          [header] -> {:ok, {header, []}}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  def write(path, header, rows) when is_list(header) and is_list(rows) do
    # Une la cabecera y las filas en un solo string
    header_line = Enum.join(header, ",")
    content =
      rows
      |> Enum.map(&Enum.join(&1, ","))
      |> Enum.join("\n")

    File.write(path, header_line <> "\n" <> content)
  end
end
