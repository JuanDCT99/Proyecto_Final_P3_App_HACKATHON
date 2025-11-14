#Logica principal del proyecto

defmodule ProyectoFinal.Hackaton do
  @moduledoc"""
  Modulo principal que maneja la logica de la aplicación

  """

  #Alias

  alias ProyectoFinal.Domain.Equipo
  alias ProyectoFinal.Domain.Proyectos_Hackaton
  alias ProyectoFinal.Domain.Persona
  alias ProyectoFinal.Services.Util, as: Funcional

  #Variables del Modulo

  @equipos_csv_path "priv/equipos.csv"
  @proyectos_csv_path "priv/proyectos.csv"
  @personas_csv_path "priv/personas.csv"

  #Funciones Publicas

  def arrancar_app do
    Funcional.mostrar_mensaje("Inicio de la platafora para la Hackaton \n**CODE4FUTURE**\nBienvenido")
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
    case String.split(input, " ", parts: 2) do
      ["/teams"] -> handle_teams()
      ["/create-team"] -> handle_create_team()
      ["/create-project"] -> handle_create_project()
      ["/add-user"] -> handle_add_user()
      ["/help"] -> handle_help()
      ["/project", nombre_equipo] -> handle_project(nombre_equipo)
      ["/join", nombre_equipo] -> handle_join(nombre_equipo)
      ["/chat", nombre_equipo] -> handle_chat(nombre_equipo)
      _-> handle_comando_desconocido()
    end
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
    --- Comandos Disponibles ---
    ---------------------------------------------------------------------------------------
    /teams                  -> Muestra la lista de equipos registrados
    /create_team            -> Crea un nuevo equipo
    /create_project         -> Crea un nuevo proyecto
    /add_user               -> Agrega un nuevo usuario a un equipo
    /project <equipo>       -> Muestra la informacion referente a el proyecto de un equipo
    /join <equipo>          -> Permite unirse a un equipo
    /chat <equipo>          -> Inicia una sesión de chat con un equipo ya existente
    /help                   -> Muestra esta ayuda
    ----------------------------------------------------------------------------------------
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
    Funcional.mostrar_mensaje("Funcionalidad /join #{nombre_equipo}, pendiente de implementación")
  end

  defp handle_chat(nombre_equipo) do
    remitente = Funcional.input("Ingresa tu nombre para el chat: ", :string)
    Funcional.mostrar_mensaje("--- Iniciando chat con #{nombre_equipo} ---")
    Funcional.mostrar_mensaje("Escribe tus mensajes. Usa /exit para salir.")

    # Iniciar el ciclo de chat
    ciclo_chat(remitente, nombre_equipo)
  end

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

  defp ciclo_chat(remitente, nombre_equipo) do
    case IO.gets("> ") |> String.trim() do
      "/exit" ->
        Funcional.mostrar_mensaje("--- Saliendo del chat ---")
        # No hacemos nada más, el ciclo principal tomará el control.
        :ok
      mensaje ->
        # Enviar el mensaje al servidor de chat
        ProyectoFinal.Chat.Server.enviar_mensaje(remitente, nombre_equipo, mensaje)
        # Continuar el ciclo de chat
        ciclo_chat(remitente, nombre_equipo)
    end
  end

  defp handle_comando_desconocido do
    Funcional.mostrar_mensaje("Comando no reconocido. Escribe /help para ver la lista de comandos")
  end
end
