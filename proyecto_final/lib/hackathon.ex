#Logica principal del proyecto

defmodule ProyectoFinal.Hackaton do
  @moduledoc"""
  Modulo principal que maneja la logica de la aplicación

  """

  #Alias

  alias ProyectoFinal.Domain.Equipo
  alias ProyectoFinal.Domain.Proyectos_Hackaton
  alias ProyectoFinal.Services.Util, as: Funcional

  #Variables del Modulo

  @equipos_csv_path "priv/equipos.csv"
  @proyectos_csv_path "priv/proyectos.csv"

  #Funciones Publicas

  def arrancar_app do
    Funcional.mostrar_mensaje("Inicio de la platafora para la Hackaton **CODE4FUTURE\nBienvenido")
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
    Funcional.mostrar_mensaje("Funcionalidad /chat #{nombre_equipo}, pendiente de implementación")
  end

  defp handle_comando_desconocido do
    Funcional.mostrar_mensaje("Comando no reconocido. Escribe /help para ver la lista de comandos")
  end
end
