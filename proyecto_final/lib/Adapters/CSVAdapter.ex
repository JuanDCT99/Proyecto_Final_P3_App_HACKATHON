defmodule Adapters.CSVAdapter do
  @moduledoc """
  Adapter for handling CSV file operations, separating headers and rows.
  """

  @doc """
  Reads a CSV file and returns the header and rows separately.
  Returns {:ok, {header, rows}} or {:error, reason}.
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
          [] -> {:ok, {[], []}} # Archivo vacío
          [header] -> {:ok, {header, []}} # Archivo con solo cabecera
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Writes a header and a list of rows to a CSV file.
  """
  def write(path, header, rows) when is_list(header) and is_list(rows) do
    # Une la cabecera y las filas en un solo string
    header_line = Enum.join(header, ",")
    content = 
      rows
      |> Enum.map(&Enum.join(&1, ","))
      |> Enum.join("\n")

    # Escribe el contenido completo al archivo
    File.write(path, header_line <> "\n" <> content)
  end
end