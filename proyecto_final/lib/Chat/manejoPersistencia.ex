defmodule ProyectoFinal.Chat.PersistenceManager do
  @moduledoc """
  Módulo auxiliar para gestionar la persistencia del ChatServer.
  Permite hacer backups, restaurar datos, y generar reportes.
  """

  alias ProyectoFinal.Chat.ChatServer
  alias ProyectoFinal.Services.Util, as: Funcional

  @mensajes_path "priv/chat_mensajes.bin"
  @salas_path "priv/chat_salas.bin"
  @usuarios_salas_csv "priv/chat_usuarios_salas.csv"
  @backup_dir "priv/backups"

  @doc """
  Crea un backup completo del estado del chat.
  """
  def crear_backup() do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    backup_nombre = "chat_backup_#{timestamp}"
    backup_path = Path.join(@backup_dir, backup_nombre)

    File.mkdir_p!(backup_path)

    archivos = [
      {@mensajes_path, "mensajes.bin"},
      {@salas_path, "salas.bin"},
      {@usuarios_salas_csv, "usuarios_salas.csv"}
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

     Funcional.mostrar_mensaje("✓ Backup creado en: #{backup_path}")
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

         Funcional.mostrar_mensaje("\n=== Backups Disponibles ===")
        Enum.each(backups, fn backup ->
           Funcional.mostrar_mensaje("  • #{backup}")
        end)
         Funcional.mostrar_mensaje("===========================\n")

        backups

      {:error, :enoent} ->
         Funcional.mostrar_mensaje("No hay backups disponibles.")
        []

      {:error, reason} ->
         Funcional.mostrar_mensaje("Error al listar backups: #{reason}")
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
        {Path.join(backup_path, "usuarios_salas.csv"), @usuarios_salas_csv}
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

       Funcional.mostrar_mensaje("✓ Backup restaurado desde: #{backup_path}")
       Funcional.mostrar_mensaje("⚠️  Reinicia el ChatServer para cargar los datos restaurados.")

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
       Funcional.mostrar_mensaje("✓ Backup eliminado: #{nombre_backup}")
      :ok
    else
      {:error, "Backup no encontrado: #{nombre_backup}"}
    end
  end

  @doc """
  Genera un reporte completo del estado del chat.
  """
  def generar_reporte_completo() do
    estadisticas = ChatServer.obtener_estadisticas()

     Funcional.mostrar_mensaje("\n╔══════════════════════════════════════════╗")
     Funcional.mostrar_mensaje("║     REPORTE COMPLETO DEL CHAT SERVER     ║")
     Funcional.mostrar_mensaje("╚══════════════════════════════════════════╝")
     Funcional.mostrar_mensaje("\n📊 Estadísticas Generales:")
     Funcional.mostrar_mensaje("   • Total de salas: #{estadisticas.total_salas}")
     Funcional.mostrar_mensaje("   • Total de mensajes: #{estadisticas.total_mensajes}")
     Funcional.mostrar_mensaje("   • Usuarios únicos: #{estadisticas.total_usuarios_unicos}")

     Funcional.mostrar_mensaje("\n📁 Archivos de Persistencia:")
    verificar_archivos_persistencia()

     Funcional.mostrar_mensaje("\n💾 Información de Backups:")
    backups = listar_backups()
     Funcional.mostrar_mensaje("   Total de backups: #{length(backups)}")

     Funcional.mostrar_mensaje("\n════════════════════════════════════════════\n")
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

      case exportar_sala_csv(sala, nombre_archivo) do
        {:ok, mensaje} -> {:ok, sala.id, mensaje}
        {:error, razon} -> {:error, sala.id, razon}
      end
    end)

    exitosos = Enum.count(resultados, fn r -> elem(r, 0) == :ok end)

     Funcional.mostrar_mensaje("\n✓ Exportación completada:")
     Funcional.mostrar_mensaje("  • Salas exportadas: #{exitosos}/#{length(salas)}")
     Funcional.mostrar_mensaje("  • Ubicación: priv/exports/")

    resultados
  end

  defp exportar_sala_csv(sala, nombre_archivo) do
    try do
      ruta_completa = "priv/exports/#{nombre_archivo}"

      # Obtener historial de la sala
      historial = ChatServer.historial(sala.id, 1000)

      encabezado = "Timestamp,Remitente,Canal,Contenido\n"
      contenido = Enum.map(historial, fn msg ->
        timestamp = DateTime.to_string(msg.timestamp)
        # Escapar comas en el contenido
        contenido_escapado = String.replace(msg.contenido, ",", ";")
        "#{timestamp},#{msg.remitente},#{sala.id},#{contenido_escapado}\n"
      end)
      |> Enum.join("")

      File.write!(ruta_completa, encabezado <> contenido)

      {:ok, "Historial exportado a #{ruta_completa}"}
    rescue
      e -> {:error, "Error al exportar: #{Exception.message(e)}"}
    end
  end

  @doc """
  Verifica la integridad de los archivos de persistencia.
  """
  def verificar_integridad() do
     Funcional.mostrar_mensaje("\n🔍 Verificando integridad de archivos...")

    archivos = [
      {@mensajes_path, "Mensajes"},
      {@salas_path, "Salas"},
      {@usuarios_salas_csv, "Usuarios por Sala"}
    ]

    resultados = Enum.map(archivos, fn {path, nombre} ->
      if File.exists?(path) do
        case File.stat(path) do
          {:ok, stat} ->
            tamano_kb = div(stat.size, 1024)
             Funcional.mostrar_mensaje("  ✓ #{nombre}: #{tamano_kb} KB")
            {:ok, nombre, stat.size}

          {:error, reason} ->
             Funcional.mostrar_mensaje("  ❌ #{nombre}: Error - #{reason}")
            {:error, nombre, reason}
        end
      else
         Funcional.mostrar_mensaje("  ⚠️  #{nombre}: Archivo no encontrado")
        {:not_found, nombre}
      end
    end)

     Funcional.mostrar_mensaje("")

    errores = Enum.count(resultados, fn r -> elem(r, 0) == :error end)
    if errores == 0 do
       Funcional.mostrar_mensaje("✓ Todos los archivos están correctos")
    else
       Funcional.mostrar_mensaje("⚠️  Se encontraron #{errores} errores")
    end

    resultados
  end

  @doc """
  Exporta los usuarios de todas las salas a un CSV consolidado.
  """
  def exportar_usuarios_consolidado() do
    salas = ChatServer.listar_salas()
    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    File.mkdir_p!("priv/exports")
    nombre_archivo = "priv/exports/usuarios_consolidado_#{timestamp}.csv"

    encabezado = "Sala,NumeroUsuarios,Usuarios\n"

    contenido = Enum.map(salas, fn sala ->
      usuarios_str = Enum.join(sala.usuarios, ";")
      "#{sala.id},#{length(sala.usuarios)},#{usuarios_str}\n"
    end)
    |> Enum.join("")

    case File.write(nombre_archivo, encabezado <> contenido) do
      :ok ->
         Funcional.mostrar_mensaje("✓ Usuarios exportados a: #{nombre_archivo}")
        {:ok, nombre_archivo}
      {:error, reason} ->
        {:error, "No se pudo escribir el archivo: #{reason}"}
    end
  end

  @doc """
  Muestra el listado de usuarios por sala de forma visual.
  """
  def mostrar_usuarios_por_sala() do
    salas = ChatServer.listar_salas()

   Funcional.mostrar_mensaje("\n╔════════════════════════════════════════════════╗")
     Funcional.mostrar_mensaje("║          USUARIOS POR SALA DE CHAT             ║")
     Funcional.mostrar_mensaje("╚════════════════════════════════════════════════╝")

    Enum.each(salas, fn sala ->
      Funcional.mostrar_mensaje("\n Sala: #{sala.nombre} (#{sala.id})")
       Funcional.mostrar_mensaje("   Total de usuarios: #{length(sala.usuarios)}")

      if Enum.empty?(sala.usuarios) do
         Funcional.mostrar_mensaje("   (Sin usuarios actualmente)")
      else
        Enum.each(sala.usuarios, fn usuario ->
           Funcional.mostrar_mensaje("   • #{usuario}")
        end)
      end
    end)

     Funcional.mostrar_mensaje("\n════════════════════════════════════════════════\n")
  end

  @doc """
  Limpia los mensajes de chat que son más antiguos que un número de días dado.

  Opcionalmente, puede crear un backup antes de realizar la limpieza.

  """
  def limpiar_datos_antiguos(opts) do
    dias = Keyword.get(opts, :dias, 30)
    hacer_backup = Keyword.get(opts, :backup, false)

    if hacer_backup do
       Funcional.mostrar_mensaje("1. Creando backup antes de la limpieza...")
      crear_backup()
    end

     Funcional.mostrar_mensaje("2. Iniciando limpieza de mensajes con más de #{dias} días...")
    fecha_corte = DateTime.utc_now() |> DateTime.add(-dias * 24 * 3600, :second)
     Funcional.mostrar_mensaje("   (Se eliminarán mensajes anteriores a #{DateTime.to_date(fecha_corte)})")

    case File.read(@mensajes_path) do
      {:ok, binario} ->
        mensajes = :erlang.binary_to_term(binario)
        mensajes_originales = length(mensajes)

        mensajes_recientes = Enum.filter(mensajes, &(!DateTime.before?(&1.timestamp, fecha_corte)))
        mensajes_filtrados = length(mensajes_recientes)
        mensajes_eliminados = mensajes_originales - mensajes_filtrados

        :erlang.term_to_binary(mensajes_recientes) |> File.write!(@mensajes_path)

         Funcional.mostrar_mensaje("✓ Limpieza completada. Mensajes eliminados: #{mensajes_eliminados}")
        {:ok, %{eliminados: mensajes_eliminados, restantes: mensajes_filtrados}}
      {:error, :enoent} ->
         Funcional.mostrar_mensaje("⚠️  No se encontró el archivo de mensajes. No hay nada que limpiar.")
        {:ok, %{eliminados: 0, restantes: 0}}
    end
  end
 

  defp verificar_archivos_persistencia() do
    archivos = [
      {@mensajes_path, "Mensajes"},
      {@salas_path, "Salas"},
      {@usuarios_salas_csv, "Usuarios por Sala"}
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

       Funcional.mostrar_mensaje("   • #{nombre}: #{estado}")
    end)
  end
end
