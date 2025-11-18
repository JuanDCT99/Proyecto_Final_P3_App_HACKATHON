#Logica principal del proyecto

defmodule ProyectoFinal.Hackaton do
  @moduledoc"""
  Modulo principal que maneja la logica de la aplicación

  """

  #Alias

  alias ProyectoFinal.Domain.Equipo
  alias ProyectoFinal.Chat.PersistenceManager
  alias ProyectoFinal.Domain.Proyectos_Hackaton
  alias ProyectoFinal.Domain.Persona
  alias ProyectoFinal.Domain.Mentor
  alias ProyectoFinal.Services.Util, as: Funcional
  alias ProyectoFinal.Chat.ChatServer

  #Variables del Modulo

  @equipos_csv_path "priv/equipos.csv"
  @proyectos_csv_path "priv/proyectos.csv"
  @personas_csv_path "priv/personas.csv"
  @mentores_csv_path "priv/mentores.csv"

  #Funciones Publicas

  def arrancar_app do
    Funcional.mostrar_mensaje("Inicio de la plataforma para la Hackaton \n*CODE4FUTURE*\nBienvenido")
    handle_help()
    #Inicio del ciclo principal
    ciclo_entrada_usuario()
  end


  defp ciclo_entrada_usuario do

    IO.gets("> ")
    |> String.trim()
    |> procesar_comando()

    ciclo_entrada_usuario()
  end

    #Procesado de los comandos
    #Caso /teams

  defp procesar_comando(input) do
    case String.split(input, " ", parts: 2, trim: true) do
      ["/teams"] -> handle_teams()
      ["/create-team"] -> handle_create_team()
      ["/create-project"] -> handle_create_project()
      ["/add-user"] -> handle_add_user()
      ["/create-mentor"] -> handle_add_mentor()
      ["/help"] -> handle_help()
      ["/project", nombre_equipo] -> handle_project(nombre_equipo)
      ["/join", nombre_equipo] -> handle_join(nombre_equipo)
      ["/historial", nombre_equipo] -> handle_historial(nombre_equipo)
      # --- Comandos de mentoría / consultas ---
      ["/enviar-consulta", rest] ->
        # espera: "/enviar-consulta <equipo> <mensaje...>"
        case String.split(rest, " ", parts: 2) do
          [nombre_equipo, mensaje] -> handle_enviar_consulta(nombre_equipo, mensaje)
          _ -> Funcional.mostrar_mensaje("Uso: /enviar-consulta <equipo> <mensaje>")
        end
      ["/ver-consultas", nombre_equipo] -> handle_ver_consultas(nombre_equipo)
      ["/responder-consulta", nombre_equipo] -> handle_responder_consulta(nombre_equipo)
      # Comandos de Chat
      ["/chat", nombre_equipo] -> handle_chat(nombre_equipo)
      ["/salas"] -> handle_list_rooms()
      ["/create_room"] -> handle_create_room()
      ["/broadcast"] -> handle_broadcast()
      ["/users", sala] -> handle_users_in_channel(sala)
       # Comandos de Gestión del Chat
      ["/chat-stats"] -> handle_chat_stats()
      ["/backup-chat"] -> handle_backup_chat()
      ["/restore-chat", backup] -> handle_restore_chat(backup)
      ["/list-backups"] -> handle_list_backups()
      ["/export-all-chats"] -> handle_export_all()
      ["/chat-integrity"] -> handle_chat_integrity()
      ["/export-users"] -> handle_export_users()
      ["/show-users-by-sala"] -> handle_show_users_by_sala()
      ["/clean-messages", dias] -> handle_clean_messages(dias)


      _-> handle_comando_desconocido()
    end
  end

  defp handle_chat_stats do
    PersistenceManager.generar_reporte_completo()
  end

  defp handle_backup_chat do
  Funcional.mostrar_mensaje("--- Creando Backup del Chat ---")
  case PersistenceManager.crear_backup() do
    {:ok, path, _resultado} ->
      Funcional.mostrar_mensaje("✓ Backup creado exitosamente en: #{path}")
    _ ->
      Funcional.mostrar_mensaje("⚠️ Hubo un problema al crear el backup")
    end
  end

  defp handle_restore_chat(backup_nombre) do
  Funcional.mostrar_mensaje("--- Restaurando Backup del Chat ---")
  Funcional.mostrar_mensaje("⚠️  ADVERTENCIA: Esto sobrescribirá los datos actuales.")
  confirmacion = Funcional.input("¿Continuar? (si/no): ", :string)

  if String.downcase(confirmacion) == "si" do
    case PersistenceManager.restaurar_backup(backup_nombre) do
      {:ok, _resultado} ->
        Funcional.mostrar_mensaje("✓ Backup restaurado. Reinicia la aplicación.")
      {:error, reason} ->
        Funcional.mostrar_mensaje("❌ Error: #{reason}")
    end
  else
    Funcional.mostrar_mensaje("Operación cancelada.")
  end
end


  defp handle_list_backups do
    PersistenceManager.listar_backups()
  end

  defp handle_export_all do
    Funcional.mostrar_mensaje("--- Exportando Todas las Salas ---")
    PersistenceManager.exportar_todas_las_salas()
  end

  defp handle_clean_messages(dias_str) do
    dias = String.to_integer(dias_str)
    Funcional.mostrar_mensaje("--- Limpieza de Mensajes Antiguos ---")
    Funcional.mostrar_mensaje("Se eliminarán mensajes con más de #{dias} días.")

    confirmacion = Funcional.input("¿Continuar? (si/no): ", :string)

    if String.downcase(confirmacion) == "si" do
      PersistenceManager.limpiar_datos_antiguos(dias: dias, backup: true)
    else
      Funcional.mostrar_mensaje("Operación cancelada.")
    end
  end

  defp handle_chat_integrity do
  PersistenceManager.verificar_integridad()
end

  defp handle_export_users do
  Funcional.mostrar_mensaje("--- Exportar Usuarios por Sala ---")
  case PersistenceManager.exportar_usuarios_consolidado() do
    {:ok, archivo} ->
      Funcional.mostrar_mensaje("✓ Usuarios exportados exitosamente")
      Funcional.mostrar_mensaje("  Archivo: #{archivo}")
    {:error, reason} ->
      Funcional.mostrar_mensaje("❌ Error al exportar: #{reason}")
    end
  end

  defp handle_show_users_by_sala do
   PersistenceManager.mostrar_usuarios_por_sala()
  end

  #Handlers referentes a comandos

# ---- Ciclo Principal y despachador de comandos -----
  defp handle_teams do
    Funcional.mostrar_mensaje("----- Equipos Registrados -----")
    case Equipo.leer_csv(@equipos_csv_path) do
      [] ->
        Funcional.mostrar_mensaje("No hay equipos registrados por el momento")
      equipos ->
        Enum.each(equipos, fn equipo ->
          integrantes_str = Enum.join(equipo.integrantes, ", ")
          Funcional.mostrar_mensaje("- #{equipo.nombre} (ID: #{equipo.groupID}) | Integrantes: #{integrantes_str}")
        end)
    end
      Funcional.mostrar_mensaje("---------------------------------")
  end

  defp handle_help do
  Funcional.mostrar_mensaje("""
  ╔========================== COMANDOS DISPONIBLES ==========================╗

[ EQUIPOS Y PROYECTOS ]
  /teams                 -> Lista equipos                |  /create-team          -> Crear equipo
  /create-project        -> Crear proyecto               |  /add-user             -> Agregar usuario
  /create-mentor         -> Asignar mentor               |  /project <equipo>     -> Ver proyecto
  /join <equipo>         -> Unirse a equipo              |  /historial <equipo>   -> Ver historial

[ MENTORÍA ]
  /enviar-consulta <equipo> <msg>  -> Enviar consulta    |  /ver-consultas <equipo> -> Ver consultas
  /responder-consulta <equipo>     -> Responder consulta

[ CHAT ]
  /chat <sala>           -> Entrar a sala                |  /salas                -> Ver salas
  /create_room           -> Crear sala                   |  /users <sala>         -> Ver usuarios
  /broadcast             -> Mensaje global

[ CHAT AVANZADO ]
  /chat-stats            -> Estadísticas chat            |  /backup-chat          -> Crear backup
  /list-backups          -> Listar backups               |  /restore-chat <file>  -> Restaurar backup
  /export-all-chats      -> Exportar chats               |  /chat-integrity       -> Verificar integridad
  /export-users          -> Exportar usuarios            |  /show-users-by-sala   -> Usuarios por sala
  /clean-messages <días> -> Limpiar mensajes viejos

[ AYUDA ]
  /help                  -> Mostrar ayuda

╚==========================================================================╝
  """)
end

  defp handle_project(nombre_equipo) do
    Funcional.mostrar_mensaje("---- Buscando proyecto del equipo: #{nombre_equipo} ----")
    proyectos = Proyectos_Hackaton.leer_csv(@proyectos_csv_path)

    case Enum.find(proyectos, fn proyecto -> String.downcase(proyecto.nombre) == String.downcase(nombre_equipo) end) do
      nil ->
        Funcional.mostrar_mensaje("No se encontro el proyecto asociado al equipo")
      proyecto ->
        Funcional.mostrar_mensaje("""
        - Nombre: #{proyecto.nombre}
        - Descripcion: #{proyecto.descripcion}
        - Categoria: #{proyecto.categoria}
        - Estado: #{proyecto.estado}
        -Avances: #{Enum.join(proyecto.avances, ", ")}
        """)
    end
    Funcional.mostrar_mensaje("-------------------------------------------------------------")
  end

  defp handle_join(nombre_equipo) do
    id_usuario = Funcional.input("Ingrese su identificacion de usuario: ", :string)

    equipos = Equipo.leer_csv(@equipos_csv_path)
    personas = Persona.leer_csv(@personas_csv_path)

    equipo_a_unirse = Enum.find(equipos, fn e -> e.nombre == nombre_equipo end)
    usuario_a_unir = Enum.find(personas, fn p -> p.identificacion == id_usuario end)

    case {equipo_a_unirse, usuario_a_unir} do
      {nil, _} ->
        Funcional.mostrar_mensaje("Error, el equipo #{nombre_equipo} no existe. Crea el equipo primero.")

      {_, nil} ->
        Funcional.mostrar_mensaje("Error, no existe un usuario con la identificacion #{id_usuario}. crea el usuario primero.")

      {equipo, usuario} ->
        nuevos_integrantes = [usuario.nombre | equipo.integrantes] |> Enum.uniq()
        equipo_actualizado = %{equipo | integrantes: nuevos_integrantes}

        usuario_actualizado = %{usuario | equipo: equipo.nombre}

        equipos_actualizados = Enum.map(equipos, fn e -> if e.nombre == equipo.nombre, do: equipo_actualizado, else: e end)
        personas_actualizadas = Enum.map(personas, fn p -> if p.identificacion == usuario.identificacion, do: usuario_actualizado, else: p end)

        Equipo.escribir_csv(equipos_actualizados, @equipos_csv_path)
        Persona.escribir_csv(personas_actualizadas, @personas_csv_path)

        Funcional.mostrar_mensaje("El usuario #{usuario.nombre} se ha unido exitosamente al equipo #{equipo.nombre}")
      end
    end

  # Mostrar todo el historial/avances del proyecto
  defp handle_historial(nombre_equipo) do
    proyectos = Proyectos_Hackaton.leer_csv(@proyectos_csv_path)
    case Enum.find(proyectos, fn p -> String.downcase(p.nombre) == String.downcase(nombre_equipo) end) do
      nil ->
        Funcional.mostrar_mensaje("No se encontró proyecto para #{nombre_equipo}")
      proyecto ->
        if proyecto.avances == [] do
          Funcional.mostrar_mensaje("No hay avances registrados para #{nombre_equipo}")
        else
          Funcional.mostrar_mensaje("Historial de avances para #{nombre_equipo}:")
          Enum.with_index(proyecto.avances, 1)
          |> Enum.each(fn {av, idx} -> Funcional.mostrar_mensaje("#{idx}. #{av}") end)
        end
    end
  end

  # Enviar una consulta: se solicita remitente y el texto (mensaje ya llega desde el comando)
  defp handle_enviar_consulta(nombre_equipo, mensaje) do
    equipos = Equipo.leer_csv(@equipos_csv_path)

    case Enum.find(equipos, fn e -> String.downcase(e.nombre) == String.downcase(nombre_equipo) end) do
      nil ->
        Funcional.mostrar_mensaje("Error: El equipo #{nombre_equipo} no existe.")
      _equipo ->
        remitente = Funcional.input("Ingrese su nombre (quien realiza la consulta): ", :string)
        texto = "CONSULTA de #{remitente}: #{mensaje}"

        case Proyectos_Hackaton.agregar_avance(nombre_equipo, texto) do
          :ok ->
            Funcional.mostrar_mensaje("Consulta registrada y enviada a los mentores de #{nombre_equipo}.")
          {:error, :not_found} ->
            Funcional.mostrar_mensaje("No se encontró el proyecto para el equipo #{nombre_equipo}. Cree el proyecto primero.")
          {:error, reason} ->
            Funcional.mostrar_mensaje("Error al registrar la consulta: #{inspect(reason)}")
        end
    end
  end

  # Ver consultas: lista avaces que comienzan por "CONSULTA"
  defp handle_ver_consultas(nombre_equipo) do
    proyectos = Proyectos_Hackaton.leer_csv(@proyectos_csv_path)

    case Enum.find(proyectos, fn p -> String.downcase(p.nombre) == String.downcase(nombre_equipo) end) do
      nil ->
        Funcional.mostrar_mensaje("No se encontró proyecto para #{nombre_equipo}")
      proyecto ->
        consultas = Enum.filter(proyecto.avances, fn av -> String.starts_with?(av, "CONSULTA") end)
        if consultas == [] do
          Funcional.mostrar_mensaje("No hay consultas registradas para #{nombre_equipo}")
        else
          Funcional.mostrar_mensaje("Consultas para #{nombre_equipo}:")
          Enum.with_index(consultas, 1)
          |> Enum.each(fn {c, i} -> Funcional.mostrar_mensaje("#{i}. #{c}") end)
        end
    end
  end

  # Responder una consulta: flujo interactivo (escoge índice, pide mentor y respuesta)
  defp handle_responder_consulta(nombre_equipo) do
    proyectos = Proyectos_Hackaton.leer_csv(@proyectos_csv_path)

    case Enum.find(proyectos, fn p -> String.downcase(p.nombre) == String.downcase(nombre_equipo) end) do
      nil ->
        Funcional.mostrar_mensaje("No se encontró proyecto para #{nombre_equipo}")
      proyecto ->
        consultas = Enum.filter(proyecto.avances, fn av -> String.starts_with?(av, "CONSULTA") end)

        if Enum.empty?(consultas) do
          Funcional.mostrar_mensaje("No hay consultas pendientes para #{nombre_equipo}")
        else
          Funcional.mostrar_mensaje("Consultas pendientes:")
          Enum.with_index(consultas, 1)
          |> Enum.each(fn {c, i} -> Funcional.mostrar_mensaje("#{i}. #{c}") end)

          idx_str = Funcional.input("Ingrese el número de la consulta a responder: ", :string)
          idx = try do String.to_integer(idx_str) rescue _ -> -1 end

          if idx < 1 or idx > length(consultas) do
            Funcional.mostrar_mensaje("Índice inválido.")
          else
            mentor = Funcional.input("Ingrese el nombre del mentor que responde: ", :string)
            respuesta = Funcional.input("Ingrese la respuesta del mentor: ", :string)
            texto_respuesta = "RESPUESTA de #{mentor}: #{respuesta}"

            case Proyectos_Hackaton.agregar_avance(nombre_equipo, texto_respuesta) do
              :ok ->
                Funcional.mostrar_mensaje("Respuesta registrada en el historial del proyecto.")
              {:error, :not_found} ->
                Funcional.mostrar_mensaje("No se encontró el proyecto para el equipo #{nombre_equipo}.")
              {:error, reason} ->
                Funcional.mostrar_mensaje("Error al guardar la respuesta: #{inspect(reason)}")
            end
          end
        end
    end
  end

  # --- Handlers de Chat ---

  defp handle_chat(nombre_sala) do
    remitente = Funcional.input("Ingresa tu nombre para el chat: ", :string)
    Funcional.mostrar_mensaje("--- Uniéndose a la sala de chat: #{nombre_sala} ---")

    # Suscribirse a la sala
    case ChatServer.suscribirse(nombre_sala) do
      :ok ->
        Funcional.mostrar_mensaje("Te has unido a la sala. ¡Hola, #{remitente}!")
      {:error, :ya_suscrito} ->
        Funcional.mostrar_mensaje("Ya estabas en esta sala.")
      _ ->
        Funcional.mostrar_mensaje("Creando y uniéndose a la nueva sala: #{nombre_sala}")
    end

    # 1. Obtener y mostrar el historial de mensajes recientes
    Funcional.mostrar_mensaje("--- Historial de Mensajes Recientes ---")
    historial = ChatServer.historial(nombre_sala, 10)

    if Enum.empty?(historial) do
      Funcional.mostrar_mensaje("No hay mensajes recientes en esta sala.")
    else
      historial
      |> Enum.reverse()
      |> Enum.each(fn msg ->
        tiempo_formateado = msg.timestamp |> DateTime.to_time() |> Time.to_string()
        Funcional.mostrar_mensaje("[#{tiempo_formateado}] #{msg.remitente}: #{msg.contenido}")
      end)
    end
    Funcional.mostrar_mensaje("---------------------------------------")

    Funcional.mostrar_mensaje("Escribe tus mensajes. Usa /exit para salir.")

    # 2. Iniciar el ciclo de chat interactivo
    ciclo_chat(remitente, nombre_sala)
  end

  defp ciclo_chat(remitente, nombre_sala) do
    case IO.gets("> ") |> String.trim() do
      "/exit" ->
        ChatServer.desuscribirse(nombre_sala)
        Funcional.mostrar_mensaje("--- Has salido de la sala ---")
        :ok
      mensaje ->
        # Enviar el mensaje al servidor de chat
        ChatServer.enviar_mensaje(nombre_sala, remitente, mensaje)
        # Continuar el ciclo de chat
        ciclo_chat(remitente, nombre_sala)
    end
  end

  defp handle_list_rooms do
    Funcional.mostrar_mensaje("--- Salas de Chat Disponibles ---")
    salas = ChatServer.listar_salas()
    if Enum.empty?(salas) do
      Funcional.mostrar_mensaje("No hay salas creadas, ¡sé el primero!")
    else
      Enum.each(salas, fn sala ->
        Funcional.mostrar_mensaje("- Sala: #{sala.id} | Tema: #{sala.tema} | Usuarios: #{sala.usuarios_activos}")
      end)
    end
    Funcional.mostrar_mensaje("---------------------------------")
  end

  defp handle_create_room do
    Funcional.mostrar_mensaje("--- Crear Nueva Sala de Chat ---")
    nombre_sala = Funcional.input("Nombre de la sala: ", :string)
    tema = Funcional.input("Tema de la sala: ", :string)
    creador = Funcional.input("Tu nombre (creador): ", :string)

    case ChatServer.crear_sala(nombre_sala, tema, creador) do
      {:ok, canal_id} ->
        Funcional.mostrar_mensaje("¡Sala '#{nombre_sala}' creada con éxito! Puedes unirte con /chat #{canal_id}")
      {:error, :sala_existente} ->
        Funcional.mostrar_mensaje("Error: Ya existe una sala con ese nombre.")
    end
    Funcional.mostrar_mensaje("--------------------------------")
  end

  defp handle_broadcast do
    Funcional.mostrar_mensaje("--- Enviar Anuncio Global ---")
    remitente = Funcional.input("Tu nombre (Admin): ", :string)
    contenido = Funcional.input("Mensaje del anuncio: ", :string)

    case ChatServer.broadcast_anuncio(remitente, contenido) do
      {:ok, _} -> Funcional.mostrar_mensaje("Anuncio enviado a todas las salas.")
      _ -> Funcional.mostrar_mensaje("Error al enviar el anuncio.")
    end
    Funcional.mostrar_mensaje("-----------------------------")
  end

  defp handle_users_in_channel(sala) do
  Funcional.mostrar_mensaje("--- Usuarios en la sala: #{sala} ---")

  salas = ChatServer.listar_salas()
  sala_info = Enum.find(salas, fn s -> s.id == sala end)

  if sala_info do
    if Enum.empty?(sala_info.usuarios) do
      Funcional.mostrar_mensaje("No hay usuarios en esta sala actualmente.")
    else
      Funcional.mostrar_mensaje("Total de usuarios: #{length(sala_info.usuarios)}")
      Funcional.mostrar_mensaje("")
      Enum.each(sala_info.usuarios, fn usuario ->
        Funcional.mostrar_mensaje("  • #{usuario}")
      end)
    end
  else
    Funcional.mostrar_mensaje("Sala no encontrada.")
  end
  Funcional.mostrar_mensaje("--------------------------------------")
end


  # --- Handlers de Creación ---

  defp handle_create_team do
    Funcional.mostrar_mensaje("---- Creacion de Nuevo Equipo ----")
    #1. LLama a la funcion interactiva para crear el Equipo de memoria
    nuevo_equipo = Equipo.crearEquipo()

    equipos_existentes = Equipo.leer_csv(@equipos_csv_path)

    equipos_actualizados = Enum.reverse([nuevo_equipo | Enum.reverse(equipos_existentes)])

    case Equipo.escribir_csv(equipos_actualizados, @equipos_csv_path) do
      :ok ->
        Funcional.mostrar_mensaje("Equipo #{nuevo_equipo.nombre} creado exitosamente y guardado en #{@equipos_csv_path}")
      {:error, reason} ->
        Funcional.mostrar_mensaje("Error al guardar el equipo: #{reason}")
    end
    Funcional.mostrar_mensaje("----------------------------------")
  end

  defp handle_create_project do
    Funcional.mostrar_mensaje("---- Creacion de Nuevo Proyecto ----")
    #crear proyecto interactivo
    nuevo_proyecto = Proyectos_Hackaton.crear_Proyecto()

    equipos = Equipo.leer_csv(@equipos_csv_path)
    nombre_equipo_asociado = nuevo_proyecto.nombre

    equipo_existe = Enum.any?(equipos, fn equipo -> equipo.nombre == nombre_equipo_asociado end)

    if equipo_existe do
      #4. Si el equipo existe, guardar el proyecto
      proyectos_existentes = Proyectos_Hackaton.leer_csv(@proyectos_csv_path)
      proyectos_actualizados = Enum.reverse([nuevo_proyecto | Enum.reverse(proyectos_existentes)])

      case Proyectos_Hackaton.escribir_csv(proyectos_actualizados, @proyectos_csv_path) do
        :ok ->
          Funcional.mostrar_mensaje("Proyecto #{nuevo_proyecto.nombre} Creado exitosamente y guardado en #{@proyectos_csv_path}")

        {:error, reason} ->
          Funcional.mostrar_mensaje("Error al guardar el proyecto: #{reason}")
      end
    else
      Funcional.mostrar_mensaje("Error: No existe un equipo con el nombre #{nombre_equipo_asociado}. Crea el equipo primero.")
      Funcional.mostrar_mensaje("-------------------------------------")
    end
  end

  defp handle_add_user do
    Funcional.mostrar_mensaje("---- Agregar Usuario al Equipo ----")
    #crear usuario interactivo
    nuevo_usuario = Persona.crear_Usuario()

    #Leer los equipos existentes
    equipos = Equipo.leer_csv(@equipos_csv_path)
    nombre_equipo_usuario = nuevo_usuario.equipo

    #Paso de validacion: Verificar si el equipo existe
    equipo_existe = Enum.any?(equipos, fn equipo -> equipo.nombre == nombre_equipo_usuario end)

    if equipo_existe do
      #Si el equipo existe, agregar el usuario al equipo
      usuarios_existentes = Persona.leer_csv(@personas_csv_path)
      usuarios_actualizados = Enum.reverse([nuevo_usuario | Enum.reverse(usuarios_existentes)])

      case Persona.escribir_csv(usuarios_actualizados, @personas_csv_path) do
        :ok ->
          Funcional.mostrar_mensaje("Usuario #{nuevo_usuario.nombre} agregado exitosamente al equipo #{nombre_equipo_usuario} y guardado en priv/personas.csv")

        {:error, reason} ->
          Funcional.mostrar_mensaje("Error al guardar el usuario: #{reason}")
      end
    else
      Funcional.mostrar_mensaje("Error: No existe un equipo con el nombre #{nombre_equipo_usuario}. Crea el equipo primero.")
      Funcional.mostrar_mensaje("----------------------------------")
    end
  end

  defp handle_add_mentor do
    Funcional.mostrar_mensaje("---- Designar Mentor al Equipo ----")
    #crear mentor interactivo
    nuevo_mentor = Mentor.crear_mentor()

    #Leer los equipos existentes
    equipos = Equipo.leer_csv(@equipos_csv_path)
    nombre_equipo_mentor = nuevo_mentor.equipo

    #Paso de validacion: Verificar si el equipo existe
    equipo_existe = Enum.any?(equipos, fn equipo -> equipo.nombre == nombre_equipo_mentor end)

    if equipo_existe do
      #Si el equipo existe, agregar el mentor al equipo
      mentores_existentes = Mentor.leer_csv(@mentores_csv_path)
      mentores_actualizados = Enum.reverse([nuevo_mentor | Enum.reverse(mentores_existentes)])

      case Mentor.escribir_csv(mentores_actualizados, @mentores_csv_path) do
        :ok ->
          Funcional.mostrar_mensaje("Mentor #{nuevo_mentor.nombre} asignado exitosamente al equipo #{nombre_equipo_mentor} y guardado en priv/mentores.csv")

        {:error, reason} ->
          Funcional.mostrar_mensaje("Error al guardar el mentor: #{reason}")
      end
    else
      Funcional.mostrar_mensaje("Error: No existe un equipo con el nombre #{nombre_equipo_mentor}. Crea el equipo primero.")
      Funcional.mostrar_mensaje("----------------------------------")
    end
  end

  defp handle_comando_desconocido do
    Funcional.mostrar_mensaje("Comando no reconocido. Escribe /help para ver la lista de comandos")
  end
end
