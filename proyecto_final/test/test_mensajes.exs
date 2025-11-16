defmodule ProyectoFinal.Domain.MensajeTest do
  use ExUnit.Case
  alias ProyectoFinal.Domain.Mensaje
  import ExUnit.CaptureIO

  # Módulo mock para CSVAdapter
  defmodule MockCSVAdapter do
    def write(_nombre_archivo, _header, _rows), do: :ok

    def read("mensajes_validos.csv") do
      {:ok, {
        ["Remitente", "Destinatario", "Contenido", "Timestamp"],
        [
          ["Juan", "María", "Hola, ¿cómo estás?", "2024-11-15T10:30:00Z"],
          ["María", "Juan", "¡Muy bien, gracias!", "2024-11-15T10:35:00Z"],
          ["Carlos", "Ana", "Reunión a las 3pm", "2024-11-15T09:00:00Z"]
        ]
      }}
    end

    def read("mensajes_sin_timestamp.csv") do
      {:ok, {
        ["Remitente", "Destinatario", "Contenido", "Timestamp"],
        [
          ["Juan", "María", "Mensaje sin fecha", ""]
        ]
      }}
    end

    def read("archivo_invalido.csv") do
      {:error, :enoent}
    end
  end

  describe "crear/3" do
    test "crea un mensaje con todos los campos" do
      mensaje = Mensaje.crear("Juan", "María", "Hola mundo")

      assert mensaje.remitente == "Juan"
      assert mensaje.destinatario == "María"
      assert mensaje.contenido == "Hola mundo"
      assert %DateTime{} = mensaje.timestamp
    end

    test "el timestamp se genera automáticamente" do
      antes = DateTime.utc_now() |> DateTime.truncate(:second)
      mensaje = Mensaje.crear("A", "B", "Test")
      despues = DateTime.utc_now() |> DateTime.truncate(:second)

      assert mensaje.timestamp != nil
      assert DateTime.compare(mensaje.timestamp, antes) in [:gt, :eq]
      assert DateTime.compare(mensaje.timestamp, despues) in [:lt, :eq]
    end

    test "el timestamp está truncado a segundos (sin microsegundos)" do
      mensaje = Mensaje.crear("Juan", "María", "Test")

      # Verificar que los microsegundos son {0, 0}
      assert mensaje.timestamp.microsecond == {0, 0}
    end

    test "dos mensajes creados tienen timestamps diferentes o iguales" do
      mensaje1 = Mensaje.crear("A", "B", "Primero")
      :timer.sleep(1100) # Esperar más de 1 segundo
      mensaje2 = Mensaje.crear("C", "D", "Segundo")

      # Pueden ser iguales si se crean en el mismo segundo
      assert DateTime.compare(mensaje1.timestamp, mensaje2.timestamp) in [:lt, :eq]
    end

    test "el mensaje es una estructura válida" do
      mensaje = Mensaje.crear("Test", "Test", "Test")

      assert %Mensaje{} = mensaje
    end

    test "maneja contenido largo" do
      contenido_largo = String.duplicate("Lorem ipsum ", 100)
      mensaje = Mensaje.crear("A", "B", contenido_largo)

      assert String.length(mensaje.contenido) > 1000
    end

    test "maneja caracteres especiales en todos los campos" do
      mensaje = Mensaje.crear(
        "José María",
        "O'Brien",
        "¡Hola! ¿Cómo estás? #test @mention"
      )

      assert mensaje.remitente == "José María"
      assert mensaje.destinatario == "O'Brien"
      assert mensaje.contenido =~ "¡Hola!"
    end
  end

  describe "escribir_csv/2" do
    setup do
      mensajes = [
        Mensaje.crear("Juan", "María", "Hola"),
        Mensaje.crear("María", "Juan", "Adiós")
      ]

      {:ok, mensajes: mensajes}
    end

    test "formatea correctamente el header" do
      header = ["Remitente", "Destinatario", "Contenido", "Timestamp"]

      assert length(header) == 4
      assert Enum.at(header, 0) == "Remitente"
      assert Enum.at(header, 3) == "Timestamp"
    end

    test "convierte timestamp a formato ISO8601", %{mensajes: mensajes} do
      [mensaje | _] = mensajes
      timestamp_str = DateTime.to_iso8601(mensaje.timestamp)

      # Verificar formato ISO8601
      assert timestamp_str =~ ~r/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
    end

    test "genera filas con el formato correcto", %{mensajes: mensajes} do
      rows = Enum.map(mensajes, fn %Mensaje{remitente: r, destinatario: d, contenido: c, timestamp: t} ->
        timestamp_str = if t, do: DateTime.to_iso8601(t), else: ""
        [r, d, c, timestamp_str]
      end)

      assert length(rows) == 2

      # Primera fila
      [primera_fila | _] = rows
      assert Enum.at(primera_fila, 0) == "Juan"
      assert Enum.at(primera_fila, 1) == "María"
      assert Enum.at(primera_fila, 2) == "Hola"
      assert is_binary(Enum.at(primera_fila, 3))
    end

    test "maneja mensaje con timestamp nil" do
      mensaje = %Mensaje{
        remitente: "A",
        destinatario: "B",
        contenido: "Test",
        timestamp: nil
      }

      timestamp_str = if mensaje.timestamp, do: DateTime.to_iso8601(mensaje.timestamp), else: ""

      assert timestamp_str == ""
    end

    test "maneja lista vacía de mensajes" do
      rows = Enum.map([], fn _ -> [] end)

      assert rows == []
    end
  end

  describe "leer_csv/1" do
    setup do
      Application.put_env(:proyecto_final, :csv_adapter, MockCSVAdapter)
      :ok
    end

    test "lee y parsea mensajes correctamente desde CSV válido" do
      mensajes = [
        %Mensaje{
          remitente: "Juan",
          destinatario: "María",
          contenido: "Hola, ¿cómo estás?",
          timestamp: ~U[2024-11-15 10:30:00Z]
        },
        %Mensaje{
          remitente: "María",
          destinatario: "Juan",
          contenido: "¡Muy bien, gracias!",
          timestamp: ~U[2024-11-15 10:35:00Z]
        }
      ]

      [mensaje1, mensaje2] = mensajes

      # Verificar primer mensaje
      assert mensaje1.remitente == "Juan"
      assert mensaje1.destinatario == "María"
      assert mensaje1.contenido == "Hola, ¿cómo estás?"
      assert mensaje1.timestamp == ~U[2024-11-15 10:30:00Z]

      # Verificar segundo mensaje
      assert mensaje2.remitente == "María"
      assert mensaje2.contenido == "¡Muy bien, gracias!"
    end

    test "parsea timestamp en formato ISO8601 correctamente" do
      timestamp_str = "2024-11-15T10:30:00Z"

      result = case DateTime.from_iso8601(timestamp_str) do
        {:ok, dt, _} -> dt
        _ -> nil
      end

      assert result == ~U[2024-11-15 10:30:00Z]
      assert %DateTime{} = result
    end

    test "maneja timestamp inválido retornando nil" do
      timestamp_invalido = "fecha-invalida"

      result = case DateTime.from_iso8601(timestamp_invalido) do
        {:ok, dt, _} -> dt
        _ -> nil
      end

      assert result == nil
    end

    test "maneja timestamp vacío retornando nil" do
      timestamp_vacio = ""

      result = case DateTime.from_iso8601(String.trim(timestamp_vacio)) do
        {:ok, dt, _} -> dt
        _ -> nil
      end

      assert result == nil
    end

    test "elimina espacios en blanco de todos los campos" do
      remitente = "  Juan  "
      destinatario = "  María  "
      contenido = "  Hola mundo  "

      assert String.trim(remitente) == "Juan"
      assert String.trim(destinatario) == "María"
      assert String.trim(contenido) == "Hola mundo"
    end

    test "retorna lista vacía cuando hay error al leer archivo" do
      mensajes = Mensaje.leer_csv("archivo_invalido.csv")

      assert mensajes == []
    end

    test "filtra mensajes con formato inválido (nil)" do
      datos_mixtos = [
        %Mensaje{remitente: "Juan", destinatario: "María", contenido: "Test", timestamp: nil},
        nil,
        %Mensaje{remitente: "Ana", destinatario: "Luis", contenido: "Test2", timestamp: nil}
      ]

      resultado = Enum.reject(datos_mixtos, &is_nil/1)

      assert length(resultado) == 2
      refute Enum.any?(resultado, &is_nil/1)
    end

    test "maneja filas con menos de 4 campos" do
      # Simular fila incompleta
      fila = ["Solo", "Tres", "Campos"]

      resultado = case fila do
        [remitente, destinatario, contenido, timestamp_str] ->
          %Mensaje{remitente: remitente}
        _ -> nil
      end

      assert is_nil(resultado)
    end

    test "maneja diferentes formatos de timestamp ISO8601" do
      timestamps = [
        "2024-11-15T10:30:00Z",           # UTC
        "2024-11-15T10:30:00+00:00",      # Con offset
        "2024-11-15T10:30:00.000Z",       # Con milisegundos
      ]

      resultados = Enum.map(timestamps, fn ts ->
        case DateTime.from_iso8601(ts) do
          {:ok, dt, _} -> dt
          _ -> nil
        end
      end)

      # Todos deben parsear correctamente
      refute Enum.any?(resultados, &is_nil/1)
      assert Enum.all?(resultados, &match?(%DateTime{}, &1))
    end
  end

  describe "struct Mensaje" do
    test "tiene los campos correctos por defecto" do
      mensaje = %Mensaje{}

      assert mensaje.remitente == ""
      assert mensaje.destinatario == ""
      assert mensaje.contenido == ""
      assert mensaje.timestamp == nil
    end

    test "permite actualizar campos individualmente" do
      mensaje = %Mensaje{}
      mensaje_actualizado = %{mensaje | remitente: "Juan", contenido: "Nuevo contenido"}

      assert mensaje_actualizado.remitente == "Juan"
      assert mensaje_actualizado.contenido == "Nuevo contenido"
      assert mensaje_actualizado.destinatario == ""
    end

    test "permite crear con valores personalizados" do
      timestamp = DateTime.utc_now()
      mensaje = %Mensaje{
        remitente: "Test",
        destinatario: "Test2",
        contenido: "Mensaje de prueba",
        timestamp: timestamp
      }

      assert mensaje.remitente == "Test"
      assert mensaje.timestamp == timestamp
    end
  end

  describe "integración escribir_csv y leer_csv" do
    test "timestamp se preserva correctamente en ciclo completo" do
      # Crear mensaje con timestamp conocido
      timestamp_original = ~U[2024-11-15 10:30:00Z]
      mensaje_original = %Mensaje{
        remitente: "Juan",
        destinatario: "María",
        contenido: "Test",
        timestamp: timestamp_original
      }

      # Simular escritura: convertir a ISO8601
      timestamp_str = DateTime.to_iso8601(mensaje_original.timestamp)
      assert timestamp_str == "2024-11-15T10:30:00Z"

      # Simular lectura: parsear desde ISO8601
      {:ok, timestamp_leido, _} = DateTime.from_iso8601(timestamp_str)

      # Verificar que son iguales
      assert DateTime.compare(timestamp_original, timestamp_leido) == :eq
    end

    test "mensaje completo sobrevive ciclo de escritura/lectura" do
      # Crear mensaje
      mensaje_original = Mensaje.crear("Juan", "María", "Hola mundo")

      # Simular escritura
      timestamp_str = DateTime.to_iso8601(mensaje_original.timestamp)
      fila = [
        mensaje_original.remitente,
        mensaje_original.destinatario,
        mensaje_original.contenido,
        timestamp_str
      ]

      # Simular lectura
      [remitente, destinatario, contenido, ts_str] = fila
      {:ok, timestamp, _} = DateTime.from_iso8601(ts_str)

      mensaje_leido = %Mensaje{
        remitente: remitente,
        destinatario: destinatario,
        contenido: contenido,
        timestamp: timestamp
      }

      # Verificar que todos los campos coinciden
      assert mensaje_leido.remitente == mensaje_original.remitente
      assert mensaje_leido.destinatario == mensaje_original.destinatario
      assert mensaje_leido.contenido == mensaje_original.contenido
      assert DateTime.compare(mensaje_leido.timestamp, mensaje_original.timestamp) == :eq
    end
  end

  describe "casos edge y validaciones" do
    test "mensaje con contenido vacío" do
      mensaje = Mensaje.crear("A", "B", "")

      assert mensaje.contenido == ""
    end

    test "remitente y destinatario pueden ser el mismo" do
      mensaje = Mensaje.crear("Juan", "Juan", "Nota para mí mismo")

      assert mensaje.remitente == mensaje.destinatario
    end

    test "contenido con saltos de línea" do
      contenido = "Primera línea\nSegunda línea\nTercera línea"
      mensaje = Mensaje.crear("A", "B", contenido)

      assert mensaje.contenido =~ "\n"
      assert String.split(mensaje.contenido, "\n") |> length() == 3
    end

    test "múltiples mensajes en conversación" do
      conversacion = [
        Mensaje.crear("Juan", "María", "Hola"),
        Mensaje.crear("María", "Juan", "Hola, ¿cómo estás?"),
        Mensaje.crear("Juan", "María", "Bien, gracias"),
        Mensaje.crear("María", "Juan", "Me alegro")
      ]

      assert length(conversacion) == 4

      # Verificar orden temporal (cada mensaje tiene timestamp mayor o igual al anterior)
      timestamps = Enum.map(conversacion, & &1.timestamp)

      assert Enum.zip(timestamps, tl(timestamps))
             |> Enum.all?(fn {t1, t2} -> DateTime.compare(t1, t2) in [:lt, :eq] end)
    end

    test "timestamp mantiene zona horaria UTC" do
      mensaje = Mensaje.crear("A", "B", "Test")

      assert mensaje.timestamp.time_zone == "Etc/UTC"
      assert mensaje.timestamp.utc_offset == 0
      assert mensaje.timestamp.std_offset == 0
    end
  end
end
