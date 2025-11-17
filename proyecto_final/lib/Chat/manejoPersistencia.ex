defmodule ProyectoFinal.Chat.PersistenceManager do
  @moduledoc """
  Módulo auxiliar para gestionar la persistencia del ChatServer.
  Permite hacer backups, restaurar datos, y generar reportes.
  """

  alias ProyectoFinal.Chat.ChatServer

  @mensajes_path "priv/chat_mensajes.bin"
  @salas_path "priv/chat_salas.bin"
  @usuarios_activos_path "priv/chat_usuarios.csv"
  @backup_dir "priv/backups"

  # ============================================================
  # FUNCIONES DE BACKUP Y RESTAURACIÓN
  # ============================================================

  @doc """
  Crea un backup completo del estado del chat.
  """
  def crear_backup() do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    backup_nombre = "chat_backup_#{timestamp}"
    backup_path = Path.join(@backup_dir, backup_nombre)

    File.mkdir_p!(backup_path)

    # Copiar archivos de datos
    archivos = [
      {@mensajes_path, "mensajes.bin"},
      {@salas_path, "salas.bin"},
      {@usuarios_activos_path, "usuarios.csv"}
    ]

    resultado = Enum.reduce(archivos, [], fn {origen, destino}, acc ->
      destino_completo = Path.join(backup_path, destino)

      case File.exists?(origen) do
        true ->
          case File.cp(origen, destino_completo) do
            :ok -> [{:ok, destino} | acc]
            {:error, reason} -> [{:error, destino, reason} | acc]
          end
        false ->
          [{:skip, destino} | acc]
      end
    end)

    # Crear archivo de metadatos
    metadata = %{
      fecha_backup: DateTime.utc_now() |> DateTime.to_string(),
      archivos_respaldados: length(Enum.filter(resultado, fn r -> elem(r, 0) == :ok end))
    }

    metadata_path = Path.join(backup_path, "metadata.txt")
    File.write!(metadata_path, inspect(metadata, pretty: true))

    IO.puts("✓ Backup creado en: #{backup_path}")
    {:ok, backup_path, resultado}
  end

  @doc """
  Lista todos los backups disponibles.
  """
  def listar_backups() do
    case File.ls(@backup_dir) do
      {:ok, archivos} ->
        backups = Enum.filter(archivos, fn nombre ->
          String.starts_with?(nombre, "chat_backup_")
        end)
        |> Enum.sort(:desc)

        IO.puts("\n=== Backups Disponibles ===")
        Enum.each(backups, fn backup ->
          IO.puts("  • #{backup}")
        end)
        IO.puts("===========================\n")

        backups

      {:error, :enoent} ->
        IO.puts("No hay backups disponibles.")
        []

      {:error, reason} ->
        IO.puts("Error al listar backups: #{reason}")
        []
    end
  end

  @doc """
  Restaura el chat desde un backup específico.
  """
  def restaurar_backup(nombre_backup) do
    backup_path = Path.join(@backup_dir, nombre_backup)

    if File.exists?(backup_path) do
      archivos = [
        {Path.join(backup_path, "mensajes.bin"), @mensajes_path},
        {Path.join(backup_path, "salas.bin"), @salas_path},
        {Path.join(backup_path, "usuarios.csv"), @usuarios_activos_path}
      ]

      resultado = Enum.map(archivos, fn {origen, destino} ->
        if File.exists?(origen) do
          case File.cp(origen, destino) do
            :ok -> {:ok, destino}
            {:error, reason} -> {:error, destino, reason}
          end
        else
          {:skip, destino}
        end
      end)

      IO.puts("✓ Backup restaurado desde: #{backup_path}")
      IO.puts("⚠️  Reinicia el ChatServer para cargar los datos restaurados.")

      {:ok, resultado}
    else
      {:error, "Backup no encontrado: #{nombre_backup}"}
    end
  end

  @doc """
  Elimina un backup específico.
  """
  def eliminar_backup(nombre_backup) do
    backup_path = Path.join(@backup_dir, nombre_backup)

    if File.exists?(backup_path) do
      File.rm_rf!(backup_path)
      IO.puts("✓ Backup eliminado: #{nombre_backup}")
      :ok
    else
      {:error, "Backup no encontrado: #{nombre_backup}"}
    end
  end

  # ============================================================
  # REPORTES Y ESTADÍSTICAS
  # ============================================================

  @doc """
  Genera un reporte completo del estado del chat.
  """
  def generar_reporte_completo() do
    estadisticas = ChatServer.obtener_estadisticas()

    IO.puts("\n╔══════════════════════════════════════════╗")
    IO.puts("║     REPORTE COMPLETO DEL CHAT SERVER     ║")
    IO.puts("╚══════════════════════════════════════════╝")
    IO.puts("\n📊 Estadísticas Generales:")
    IO.puts("   • Total de salas: #{estadisticas.total_salas}")
    IO.puts("   • Total de mensajes: #{estadisticas.total_mensajes}")
    IO.puts("   • Usuarios activos: #{estadisticas.total_usuarios_activos}")

    if estadisticas.sala_mas_activa do
      IO.puts("   • Sala más activa: #{estadisticas.sala_mas_activa}")
      IO.puts("     (#{estadisticas.mensajes_sala_mas_activa} mensajes)")
    end

    IO.puts("\n📁 Archivos de Persistencia:")
    verificar_archivos_persistencia()

    IO.puts("\n💾 Información de Backups:")
    backups = listar_backups()
    IO.puts("   Total de backups: #{length(backups)}")

    IO.puts("\n════════════════════════════════════════════\n")
  end

  @doc """
  Exporta todas las salas a archivos CSV individuales.
  """
  def exportar_todas_las_salas() do
    salas = ChatServer.listar_salas()
    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    File.mkdir_p!("priv/exports")

    resultados = Enum.map(salas, fn sala ->
      nombre_archivo = "sala_#{sala.id}_#{timestamp}.csv"

      case ChatServer.exportar_historial_csv(sala.id, nombre_archivo) do
        {:ok, mensaje} -> {:ok, sala.id, mensaje}
        {:error, razon} -> {:error, sala.id, razon}
      end
    end)

    exitosos = Enum.count(resultados, fn r -> elem(r, 0) == :ok end)

    IO.puts("\n✓ Exportación completada:")
    IO.puts("  • Salas exportadas: #{exitosos}/#{length(salas)}")
    IO.puts("  • Ubicación: priv/exports/")

    resultados
  end

  @doc """
  Limpia los datos antiguos del chat.
  """
  def limpiar_datos_antiguos(opciones \\ []) do
    dias = Keyword.get(opciones, :dias, 30)
    crear_backup_antes = Keyword.get(opciones, :backup, true)

    IO.puts("\n🧹 Iniciando limpieza de datos antiguos...")

    if crear_backup_antes do
      IO.puts("📦 Creando backup de seguridad...")
      crear_backup()
    end

    case ChatServer.limpiar_mensajes_antiguos(dias) do
      {:ok, mensajes_eliminados} ->
        IO.puts("✓ Limpieza completada:")
        IO.puts("  • Mensajes eliminados: #{mensajes_eliminados}")
        IO.puts("  • Mensajes anteriores a: #{dias} días")
        {:ok, mensajes_eliminados}

      {:error, reason} ->
        IO.puts("❌ Error en limpieza: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Verifica la integridad de los archivos de persistencia.
  """
  def verificar_integridad() do
    IO.puts("\n🔍 Verificando integridad de archivos...")

    archivos = [
      {@mensajes_path, "Mensajes"},
      {@salas_path, "Salas"},
      {@usuarios_activos_path, "Usuarios Activos"}
    ]

    resultados = Enum.map(archivos, fn {path, nombre} ->
      if File.exists?(path) do
        case File.stat(path) do
          {:ok, stat} ->
            tamano_kb = div(stat.size, 1024)
            IO.puts("  ✓ #{nombre}: #{tamano_kb} KB")
            {:ok, nombre, stat.size}

          {:error, reason} ->
            IO.puts("  ❌ #{nombre}: Error - #{reason}")
            {:error, nombre, reason}
        end
      else
        IO.puts("  ⚠️  #{nombre}: Archivo no encontrado")
        {:not_found, nombre}
      end
    end)

    IO.puts("")

    errores = Enum.count(resultados, fn r -> elem(r, 0) == :error end)
    if errores == 0 do
      IO.puts("✓ Todos los archivos están correctos")
    else
      IO.puts("⚠️  Se encontraron #{errores} errores")
    end

    resultados
  end

  # ============================================================
  # FUNCIONES PRIVADAS
  # ============================================================

  defp verificar_archivos_persistencia() do
    archivos = [
      {@mensajes_path, "Mensajes"},
      {@salas_path, "Salas"},
      {@usuarios_activos_path, "Usuarios"}
    ]

    Enum.each(archivos, fn {path, nombre} ->
      estado = if File.exists?(path) do
        case File.stat(path) do
          {:ok, stat} -> "#{div(stat.size, 1024)} KB"
          {:error, _} -> "Error"
        end
      else
        "No existe"
      end

      IO.puts("   • #{nombre}: #{estado}")
    end)
  end

  @doc """
  Migra datos antiguos a la nueva estructura (útil para actualizaciones).
  """
  def migrar_datos_antiguos(origen_mensajes, origen_salas) do
    IO.puts("\n🔄 Iniciando migración de datos...")

    # Crear backup del estado actual
    crear_backup()

    # Leer datos antiguos
    mensajes_antiguos = case File.read(origen_mensajes) do
      {:ok, contenido} -> :erlang.binary_to_term(contenido)
      _ -> %{}
    end

    salas_antiguas = case File.read(origen_salas) do
      {:ok, contenido} -> :erlang.binary_to_term(contenido)
      _ -> %{}
    end

    # Escribir en la nueva ubicación
    File.mkdir_p!("priv")
    File.write!(@mensajes_path, :erlang.term_to_binary(mensajes_antiguos))
    File.write!(@salas_path, :erlang.term_to_binary(salas_antiguas))

    IO.puts("✓ Migración completada")
    IO.puts("  • Mensajes migrados: #{map_size(mensajes_antiguos)} canales")
    IO.puts("  • Salas migradas: #{map_size(salas_antiguas)}")

    :ok
  end
end
