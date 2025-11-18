defmodule SistemaComandos do
  @moduledoc """
  Sistema de comandos interactivo para gestionar equipos y participantes.
  Implementa los comandos /teams y /join
  """

  @archivo_personas "personas.csv"
  @archivo_equipos "equipos.csv"

  # Inicia el sistema de comandos
  def iniciar do
    IO.puts("\n=== Sistema de Gestión de Equipos ===")
    IO.puts("Comandos disponibles:")
    IO.puts("  /teams          - Listar todos los equipos activos")
    IO.puts("  /join <equipo>  - Unirse a un equipo")
    IO.puts("  /registro       - Registrar nuevo participante")
    IO.puts("  /crear-equipo   - Crear nuevo equipo")
    IO.puts("  /ayuda          - Mostrar ayuda")
    IO.puts("  /salir          - Salir del sistema\n")

    # Cargar datos existentes
    personas = Persona.leer_csv(@archivo_personas)
    equipos = Equipo.leer_csv(@archivo_equipos)

    loop(personas, equipos, nil)
  end

  # Loop principal que mantiene el estado
  defp loop(personas, equipos, usuario_actual) do
    IO.write("> ")
    input = IO.gets("") |> String.trim()

    case procesar_comando(input, personas, equipos, usuario_actual) do
      {:continuar, nuevas_personas, nuevos_equipos, nuevo_usuario} ->
        loop(nuevas_personas, nuevos_equipos, nuevo_usuario)

      :salir ->
        IO.puts("¡Hasta luego!")
        :ok
    end
  end

  # Procesa los comandos ingresados por el usuario
  defp procesar_comando(input, personas, equipos, usuario_actual) do
    cond do
      String.starts_with?(input, "/teams") ->
        comando_teams(equipos)
        {:continuar, personas, equipos, usuario_actual}

      String.starts_with?(input, "/join ") ->
        nombre_equipo = String.replace_prefix(input, "/join ", "")
        comando_join(nombre_equipo, personas, equipos, usuario_actual)

      input == "/registro" ->
        comando_registro(personas, equipos, usuario_actual)

      input == "/crear-equipo" ->
        comando_crear_equipo(personas, equipos, usuario_actual)

      input == "/ayuda" ->
        mostrar_ayuda()
        {:continuar, personas, equipos, usuario_actual}

      input == "/salir" ->
        :salir

      input == "" ->
        {:continuar, personas, equipos, usuario_actual}

      true ->
        IO.puts("Comando no reconocido. Escribe /ayuda para ver los comandos disponibles.")
        {:continuar, personas, equipos, usuario_actual}
    end
  end

  # Comando /teams - Lista todos los equipos activos
  defp comando_teams([]) do
    IO.puts("\n❌ No hay equipos registrados en el sistema.")
    IO.puts("   Usa /crear-equipo para crear uno nuevo.\n")
  end

  defp comando_teams(equipos) do
    IO.puts("\n📋 === EQUIPOS ACTIVOS ===")

    Enum.with_index(equipos, 1)
    |> Enum.each(fn {equipo, idx} ->
      cantidad_integrantes = length(equipo.integrantes)
      IO.puts("\n#{idx}. #{equipo.nombre}")
      IO.puts("   ID Grupo: #{equipo.groupID}")
      IO.puts("   Integrantes: #{cantidad_integrantes}")

      if cantidad_integrantes > 0 do
        IO.puts("   Miembros:")
        Enum.each(equipo.integrantes, fn integrante ->
          IO.puts("     • #{integrante}")
        end)
      else
        IO.puts("   (Sin integrantes)")
      end
    end)

    IO.puts("\n")
  end

  # Comando /join <equipo> - Unirse a un equipo
  defp comando_join(_nombre_equipo, _personas, equipos, nil) do
    IO.puts("\n❌ Primero debes registrarte usando /registro\n")
    {:continuar, _personas, equipos, nil}
  end

  defp comando_join(nombre_equipo, personas, equipos, usuario_actual) do
    nombre_equipo = String.trim(nombre_equipo)

    # Buscar el equipo
    case Enum.find(equipos, fn eq -> eq.nombre == nombre_equipo end) do
      nil ->
        IO.puts("\n❌ El equipo '#{nombre_equipo}' no existe.")
        IO.puts("   Usa /teams para ver los equipos disponibles.\n")
        {:continuar, personas, equipos, usuario_actual}

      equipo ->
        # Verificar si ya está en el equipo
        if Enum.member?(equipo.integrantes, usuario_actual.nombre) do
          IO.puts("\n⚠️  Ya eres miembro del equipo '#{nombre_equipo}'.\n")
          {:continuar, personas, equipos, usuario_actual}
        else
          # Agregar al equipo
          equipo_actualizado = Equipo.ingresar_integrante(equipo, usuario_actual)

          # Actualizar lista de equipos
          equipos_actualizados = Enum.map(equipos, fn eq ->
            if eq.nombre == nombre_equipo, do: equipo_actualizado, else: eq
          end)

          # Actualizar persona con el equipo asignado
          usuario_actualizado = Persona.asigar_persona_a_equipo(usuario_actual, nombre_equipo)

          personas_actualizadas = Enum.map(personas, fn p ->
            if p.identificacion == usuario_actualizado.identificacion,
              do: usuario_actualizado,
              else: p
          end)

          # Guardar cambios en archivos
          Persona.escribir_csv(personas_actualizadas, @archivo_personas)
          Equipo.escribir_csv(equipos_actualizados, @archivo_equipos)

          IO.puts("\n✅ Te has unido exitosamente al equipo '#{nombre_equipo}'!")
          IO.puts("   Ahora eres parte del grupo #{equipo_actualizado.groupID}\n")

          {:continuar, personas_actualizadas, equipos_actualizados, usuario_actualizado}
        end
    end
  end

  # Comando /registro - Registrar nuevo participante
  defp comando_registro(personas, equipos, _usuario_actual) do
    IO.puts("\n--- Registro de Participante ---")
    nueva_persona = Persona.crear_Usuario()

    # Verificar si ya existe
    existe = Enum.any?(personas, fn p ->
      p.identificacion == nueva_persona.identificacion
    end)

    if existe do
      IO.puts("\n⚠️  Ya existe un participante con esa identificación.")
      IO.puts("   Iniciando sesión...\n")

      usuario = Enum.find(personas, fn p ->
        p.identificacion == nueva_persona.identificacion
      end)

      {:continuar, personas, equipos, usuario}
    else
      personas_actualizadas = [nueva_persona | personas]
      Persona.escribir_csv(personas_actualizadas, @archivo_personas)

      IO.puts("\n✅ Registro exitoso! Bienvenido #{nueva_persona.nombre}")
      IO.puts("   Ahora puedes usar /teams y /join para unirte a un equipo.\n")

      {:continuar, personas_actualizadas, equipos, nueva_persona}
    end
  end

  # Comando /crear-equipo - Crear nuevo equipo
  defp comando_crear_equipo(personas, equipos, usuario_actual) do
    IO.puts("\n--- Crear Nuevo Equipo ---")
    nuevo_equipo = Equipo.crearEquipo()

    # Verificar si ya existe
    existe = Enum.any?(equipos, fn eq -> eq.nombre == nuevo_equipo.nombre end)

    if existe do
      IO.puts("\n⚠️  Ya existe un equipo con ese nombre.\n")
      {:continuar, personas, equipos, usuario_actual}
    else
      equipos_actualizados = [nuevo_equipo | equipos]
      Equipo.escribir_csv(equipos_actualizados, @archivo_equipos)

      IO.puts("\n✅ Equipo '#{nuevo_equipo.nombre}' creado exitosamente!")
      IO.puts("   ID de Grupo: #{nuevo_equipo.groupID}\n")

      {:continuar, personas, equipos_actualizados, usuario_actual}
    end
  end

  # Mostrar ayuda
  defp mostrar_ayuda do
    IO.puts("""

    === AYUDA DEL SISTEMA ===

    Comandos disponibles:

    /teams
      Muestra todos los equipos activos con sus integrantes

    /join <nombre_equipo>
      Únete a un equipo específico
      Ejemplo: /join EquipoA

    /registro
      Registra un nuevo participante en el sistema

    /crear-equipo
      Crea un nuevo equipo

    /ayuda
      Muestra esta ayuda

    /salir
      Sale del sistema

    """)
  end
end

SistemaComandos.iniciar()

