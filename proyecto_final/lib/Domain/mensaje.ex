#Modulo para los mensajes

defmodule ProyectoFinal.Domain.Mensaje do
  @moduledoc"""

  Define la estructura, la funcionalidad y la logica de un mensaje

  """

  defstruct remitente: "", destinatario: "", contenido: "", timestamp: nil


  @doc"""

  Crear una nueva estructura de mensaje

  """

  def crear(remitente, destinatario, contenido) do
    %__MODULE__{
      remitente: remitente,
      destinatario: destinatario,
      contenido: contenido,
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
    }
  end

  @doc"""

  Escribe una lista de mensajes y lo pone en un archivo CSV

  """


  def escribir_csv(lista_mensajes, nombre_archivo) do
    header = ["Remitente", "Destinatario", "Contenido", "Timestamp"]
    rows = Enum.map(lista_mensajes, fn %__MODULE__{remitente: r, destinatario: d, contenido: c, timestamp: t} ->
      #Timestamp se debe de convertir a string para que se pueda escribir en el CSV
      timestamp_str = if t, do: DateTime.to_iso8601(t), else: ""
      [r, d, c, timestamp_str]
    end)
    Adapters.CSVAdapter.write(nombre_archivo, header, rows)
  end

  @doc"""

  Lee una lista de mensajes desde un archivo CSV

  """

  def leer_csv(nombre_archivo) do
    case Adapters.CSVAdapter.read(nombre_archivo) do
      {:ok, {_header, rows}} ->
        Enum.map(rows, fn
          [remitente, destinatario, contenido, timestamp_str] ->
            timestamp = case DateTime.from_iso8601(String.trim(timestamp_str)) do
              {:ok, dt, _} -> dt
              _ -> nil
            end
            %__MODULE__{
              remitente: String.trim(remitente),
              destinatario: String.trim(destinatario),
              contenido: String.trim(contenido),
              timestamp: timestamp
            }
          _ -> nil
        end)
        |> Enum.reject(&is_nil/1)
      {:error, _reason} ->
        []
    end
  end
end
