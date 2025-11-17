defmodule ProyectoFinal.Chat.ChatServer do
  @moduledoc """
  Servidor de chat con persistencia simple de usuarios por sala en CSV.
  """

  use GenServer
  alias ProyectoFinal.Domain.Mensaje

  # Rutas de archivos
  @mensajes_path "priv/chat_mensajes.bin"
  @salas_path "priv/chat_salas.bin"
  @usuarios_salas_csv "priv/chat_usuarios_salas.csv"
  @auto_save_interval 300_000

  # ============================================================
  # API DEL CLIENTE
  # ============================================================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  def enviar_mensaje(canal, remitente, contenido) do
    GenServer.call(__MODULE__, {:enviar_mensaje, canal, remitente, contenido})
  end

  def broadcast_anuncio(remitente, contenido) do
    GenServer.call(__MODULE__, {:broadcast_anuncio, remitente, contenido})
  end

  def suscribirse(canal, nombre_usuario \\ nil) do
    # Si no se proporciona nombre, usa el PID como identificador
    usuario = nombre_usuario || "Usuario_#{inspect(self())}"
    GenServer.call(__MODULE__, {:suscribirse, canal, usuario})
  end

  def desuscribirse(canal, nombre_usuario \\ nil) do
    usuario = nombre_usuario || "Usuario_#{inspect(self())}"
    GenServer.call(__MODULE__, {:desuscribirse, canal, usuario})
  end

  def crear_sala(nombre_sala, tema, creador) do
    GenServer.call(__MODULE__, {:crear_sala, nombre_sala, tema, creador})
  end

  def listar_salas() do
    GenServer.call(__MODULE__, :listar_salas)
  end

  def historial(canal, limite \\ 50) do
    GenServer.call(__MODULE__, {:historial, canal, limite})
  end

  def usuarios_en_canal(canal) do
    GenServer.call(__MODULE__, {:usuarios_en_canal, canal})
  end

  def listar_canales() do
    GenServer.call(__MODULE__, :listar_canales)
  end

  def guardar_estado() do
    GenServer.cast(__MODULE__, :guardar_estado)
  end

  def obtener_estadisticas() do
    GenServer.call(__MODULE__, :obtener_estadisticas)
  end

  # ============================================================
  # CALLBACKS
  # ============================================================

  @impl true
  def init(:ok) do
    estado = cargar_estado_inicial()
    schedule_auto_save()
    {:ok, estado}
  end

  @impl true
  def handle_call({:enviar_mensaje, canal, remitente, contenido}, _from, estado) do
    mensaje = Mensaje.crear(remitente, canal, contenido)

    mensajes_canal = Map.get(estado.mensajes, canal, [])
    nuevos_mensajes = [mensaje | mensajes_canal]
    nuevo_estado_mensajes = Map.put(estado.mensajes, canal, nuevos_mensajes)

    # Asegurar que el remitente esté en la lista de usuarios de la sala
    usuarios_canal = Map.get(estado.usuarios_por_sala, canal, [])
    if remitente not in usuarios_canal do
      usuarios_actualizados = [remitente | usuarios_canal]
      nuevo_estado_usuarios = Map.put(estado.usuarios_por_sala, canal, usuarios_actualizados)

      nuevo_estado = %{
        estado |
        mensajes: nuevo_estado_mensajes,
        usuarios_por_sala: nuevo_estado_usuarios
      }

      guardar_mensajes(nuevo_estado.mensajes)
      guardar_usuarios_salas(nuevo_estado.usuarios_por_sala)

      {:reply, {:ok, mensaje}, nuevo_estado}
    else
      nuevo_estado = %{estado | mensajes: nuevo_estado_mensajes}
      guardar_mensajes(nuevo_estado.mensajes)
      {:reply, {:ok, mensaje}, nuevo_estado}
    end
  end

  @impl true
  def handle_call({:broadcast_anuncio, remitente, contenido}, _from, estado) do
    mensaje = Mensaje.crear(remitente, "BROADCAST", contenido)
    canales = Map.keys(estado.suscriptores)

    resultados = Enum.map(canales, fn canal ->
      mensajes_canal = Map.get(estado.mensajes, canal, [])
      {canal, [mensaje | mensajes_canal]}
    end)

    nuevo_estado_mensajes = Map.new(resultados)
    nuevo_estado = %{estado | mensajes: nuevo_estado_mensajes}

    guardar_mensajes(nuevo_estado.mensajes)

    {:reply, {:ok, mensaje}, nuevo_estado}
  end

  @impl true
  def handle_call({:suscribirse, canal, usuario}, _from, estado) do
    # Agregar PID a suscriptores (para notificaciones)
    suscriptores_canal = Map.get(estado.suscriptores, canal, [])
    pid = self()

    nuevos_suscriptores = if pid in suscriptores_canal do
      suscriptores_canal
    else
      [pid | suscriptores_canal]
    end

    nuevo_estado_suscriptores = Map.put(estado.suscriptores, canal, nuevos_suscriptores)

    # Agregar usuario a la lista de usuarios de la sala
    usuarios_canal = Map.get(estado.usuarios_por_sala, canal, [])

    if usuario in usuarios_canal do
      {:reply, {:error, :ya_suscrito}, %{estado | suscriptores: nuevo_estado_suscriptores}}
    else
      nuevos_usuarios = [usuario | usuarios_canal]
      nuevo_estado_usuarios = Map.put(estado.usuarios_por_sala, canal, nuevos_usuarios)

      Process.monitor(pid)

      nuevo_estado = %{
        estado |
        suscriptores: nuevo_estado_suscriptores,
        usuarios_por_sala: nuevo_estado_usuarios
      }

      guardar_usuarios_salas(nuevo_estado.usuarios_por_sala)

      {:reply, :ok, nuevo_estado}
    end
  end

  @impl true
  def handle_call({:desuscribirse, canal, usuario}, _from, estado) do
    # Remover PID
    suscriptores_canal = Map.get(estado.suscriptores, canal, [])
    pid = self()
    nuevos_suscriptores = List.delete(suscriptores_canal, pid)
    nuevo_estado_suscriptores = Map.put(estado.suscriptores, canal, nuevos_suscriptores)

    # Remover usuario de la lista
    usuarios_canal = Map.get(estado.usuarios_por_sala, canal, [])
    nuevos_usuarios = List.delete(usuarios_canal, usuario)
    nuevo_estado_usuarios = Map.put(estado.usuarios_por_sala, canal, nuevos_usuarios)

    nuevo_estado = %{
      estado |
      suscriptores: nuevo_estado_suscriptores,
      usuarios_por_sala: nuevo_estado_usuarios
    }

    guardar_usuarios_salas(nuevo_estado.usuarios_por_sala)

    {:reply, :ok, nuevo_estado}
  end

  @impl true
  def handle_call({:crear_sala, nombre_sala, tema, creador}, _from, estado) do
    canal_id = nombre_sala |> String.downcase() |> String.replace(" ", "_")

    if Map.has_key?(estado.salas, canal_id) do
      {:reply, {:error, :sala_existente}, estado}
    else
      nueva_sala = %{
        nombre: nombre_sala,
        tema: tema,
        creador: creador,
        creado_en: DateTime.utc_now()
      }

      nuevo_estado_salas = Map.put(estado.salas, canal_id, nueva_sala)
      nuevo_estado_mensajes = Map.put(estado.mensajes, canal_id, [])
      nuevo_estado_suscriptores = Map.put(estado.suscriptores, canal_id, [])
      nuevo_estado_usuarios = Map.put(estado.usuarios_por_sala, canal_id, [])

      nuevo_estado = %{
        estado |
        salas: nuevo_estado_salas,
        mensajes: nuevo_estado_mensajes,
        suscriptores: nuevo_estado_suscriptores,
        usuarios_por_sala: nuevo_estado_usuarios
      }

      guardar_salas(nuevo_estado.salas)
      guardar_usuarios_salas(nuevo_estado.usuarios_por_sala)

      {:reply, {:ok, canal_id}, nuevo_estado}
    end
  end

  @impl true
  def handle_call(:listar_salas, _from, estado) do
    salas_info = Enum.map(estado.salas, fn {id, info} ->
      num_usuarios = length(Map.get(estado.usuarios_por_sala, id, []))
      num_mensajes = length(Map.get(estado.mensajes, id, []))
      usuarios = Map.get(estado.usuarios_por_sala, id, [])

      Map.merge(info, %{
        id: id,
        usuarios_activos: num_usuarios,
        total_mensajes: num_mensajes,
        usuarios: usuarios
      })
    end)

    {:reply, salas_info, estado}
  end

  @impl true
  def handle_call({:historial, canal, limite}, _from, estado) do
    mensajes = Map.get(estado.mensajes, canal, [])
    mensajes_limitados = Enum.take(mensajes, limite)

    {:reply, mensajes_limitados, estado}
  end

  @impl true
  def handle_call({:usuarios_en_canal, canal}, _from, estado) do
    usuarios = Map.get(estado.usuarios_por_sala, canal, [])
    {:reply, length(usuarios), estado}
  end

  @impl true
  def handle_call(:listar_canales, _from, estado) do
    canales = Map.keys(estado.suscriptores)
    {:reply, canales, estado}
  end

  @impl true
  def handle_call(:obtener_estadisticas, _from, estado) do
    total_salas = map_size(estado.salas)
    total_mensajes = Enum.reduce(estado.mensajes, 0, fn {_canal, msgs}, acc ->
      acc + length(msgs)
    end)

    total_usuarios_unicos = estado.usuarios_por_sala
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
    |> length()

    estadisticas = %{
      total_salas: total_salas,
      total_mensajes: total_mensajes,
      total_usuarios_unicos: total_usuarios_unicos
    }

    {:reply, estadisticas, estado}
  end

  @impl true
  def handle_cast(:guardar_estado, estado) do
    guardar_mensajes(estado.mensajes)
    guardar_salas(estado.salas)
    guardar_usuarios_salas(estado.usuarios_por_sala)

    IO.puts("✓ Estado del chat guardado")

    {:noreply, estado}
  end

  @impl true
  def handle_info(:auto_save, estado) do
    guardar_mensajes(estado.mensajes)
    guardar_salas(estado.salas)
    guardar_usuarios_salas(estado.usuarios_por_sala)

    schedule_auto_save()
    {:noreply, estado}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, estado) do
    nuevo_estado_suscriptores =
      Enum.map(estado.suscriptores, fn {canal, suscriptores} ->
        {canal, List.delete(suscriptores, pid)}
      end)
      |> Enum.into(%{})

    nuevo_estado = %{estado | suscriptores: nuevo_estado_suscriptores}
    {:noreply, nuevo_estado}
  end

  # ============================================================
  # FUNCIONES PRIVADAS DE PERSISTENCIA
  # ============================================================

  defp cargar_estado_inicial() do
    mensajes = cargar_mensajes()
    salas = cargar_salas()
    usuarios_por_sala = cargar_usuarios_salas()

    %{
      mensajes: mensajes,
      suscriptores: %{"general" => []},
      salas: salas,
      usuarios_por_sala: usuarios_por_sala
    }
  end

  defp cargar_mensajes() do
    case File.read(@mensajes_path) do
      {:ok, contenido} -> :erlang.binary_to_term(contenido)
      {:error, :enoent} -> %{"general" => []}
      _ -> %{"general" => []}
    end
  end

  defp guardar_mensajes(mensajes) do
    File.mkdir_p!("priv")
    contenido = :erlang.term_to_binary(mensajes)
    File.write!(@mensajes_path, contenido)
  end

  defp cargar_salas() do
    case File.read(@salas_path) do
      {:ok, contenido} -> :erlang.binary_to_term(contenido)
      {:error, :enoent} ->
        %{
          "general" => %{
            nombre: "Canal General",
            tema: "Anuncios y comunicación general",
            creador: "Sistema",
            creado_en: DateTime.utc_now()
          }
        }
      _ ->
        %{
          "general" => %{
            nombre: "Canal General",
            tema: "Anuncios y comunicación general",
            creador: "Sistema",
            creado_en: DateTime.utc_now()
          }
        }
    end
  end

  defp guardar_salas(salas) do
    File.mkdir_p!("priv")
    contenido = :erlang.term_to_binary(salas)
    File.write!(@salas_path, contenido)
  end

  # ============================================================
  # PERSISTENCIA DE USUARIOS POR SALA EN CSV
  # ============================================================

  defp cargar_usuarios_salas() do
    case File.read(@usuarios_salas_csv) do
      {:ok, contenido} ->
        String.split(contenido, "\n")
        |> Enum.drop(1)  # Saltar encabezado
        |> Enum.filter(&(String.trim(&1) != ""))
        |> Enum.map(fn linea ->
          case String.split(linea, ",", parts: 2) do
            [sala, usuarios_str] ->
              usuarios = String.split(usuarios_str, ";")
                        |> Enum.map(&String.trim/1)
                        |> Enum.reject(&(&1 == ""))
              {String.trim(sala), usuarios}
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.into(%{})

      {:error, :enoent} ->
        IO.puts("ℹ️  No hay archivo de usuarios por sala. Iniciando limpio.")
        %{"general" => []}

      {:error, reason} ->
        IO.puts("⚠️  Error al leer usuarios por sala: #{reason}")
        %{"general" => []}
    end
  end

  defp guardar_usuarios_salas(usuarios_por_sala) do
    File.mkdir_p!("priv")

    encabezado = "Sala,Usuarios\n"

    contenido = Enum.map(usuarios_por_sala, fn {sala, usuarios} ->
      usuarios_str = Enum.join(usuarios, ";")
      "#{sala},#{usuarios_str}\n"
    end)
    |> Enum.join("")

    File.write!(@usuarios_salas_csv, encabezado <> contenido)
  end

  defp schedule_auto_save() do
    Process.send_after(self(), :auto_save, @auto_save_interval)
  end
end
