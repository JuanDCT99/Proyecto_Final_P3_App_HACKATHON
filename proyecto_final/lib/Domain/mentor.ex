defmodule Mentor do
  defstruct nombre: "",
            identificacion: "",
            celular: "",
            edad: "",
            equipo: "",
            consultas_recibidas: [],
            retroalimentacion: []

  def crear_mentor() do
    nombre = Funcional.input("Ingrese su nombre señor(a) mentor(a): ", :string)
    identificacion = Funcional.input("Ingrese su identificación señor(a) mentor(a): ", :string)
    celular = Funcional.input("Ingrese su número de celular señor(a) mentor(a): ", :string)
    edad = Funcional.input("Ingrese su edad señor(a) mentor(a): ", :string)
    equipo = Funcional.input("Ingrese su equipo señor(a) mentor(a): ", :string)
    crear(nombre, identificacion, celular, edad, equipo)
  end

  def crear(nombre, identificacion, celular, edad, equipo) do
    %Mentor{
      nombre: nombre,
      identificacion: identificacion,
      celular: celular,
      edad: edad,
      equipo: equipo,
      consultas_recibidas: [],
      retroalimentacion: []
    }
  end

  # ===== FUNCIONALIDAD 1: Canal de Consultas =====

  def enviar_consulta(mentor, equipo, consulta) do
    nueva_consulta = %{
      equipo: equipo,
      consulta: consulta,
      fecha: DateTime.utc_now(),
      respondida: false,
      respuesta: nil
    }

    %{mentor | consultas_recibidas: [nueva_consulta | mentor.consultas_recibidas]}
  end

  def ver_consultas_pendientes(mentor) do
    Enum.filter(mentor.consultas_recibidas, fn c -> !c.respondida end)
  end

  def responder_consulta(mentor, indice_consulta, respuesta) do
    consultas_actualizadas =
      Enum.with_index(mentor.consultas_recibidas)
      |> Enum.map(fn {consulta, idx} ->
        if idx == indice_consulta do
          %{consulta | respondida: true, respuesta: respuesta}
        else
          consulta
        end
      end)

    %{mentor | consultas_recibidas: consultas_actualizadas}
  end

  def listar_consultas(mentor) do
    IO.puts("\n=== Consultas para #{mentor.nombre} ===")
    Enum.with_index(mentor.consultas_recibidas)
    |> Enum.each(fn {consulta, idx} ->
      estado = if consulta.respondida, do: "✓ Respondida", else: "⏳ Pendiente"
      IO.puts("\n[#{idx}] #{estado}")
      IO.puts("Equipo: #{consulta.equipo}")
      IO.puts("Consulta: #{consulta.consulta}")
      if consulta.respondida do
        IO.puts("Respuesta: #{consulta.respuesta}")
      end
    end)
  end

  # ===== FUNCIONALIDAD 2: Sistema de Retroalimentación =====

  def agregar_retroalimentacion(mentor, equipo, tipo, comentario, calificacion \\ nil) do
    nueva_retro = %{
      equipo: equipo,
      tipo: tipo,  # :positiva, :constructiva, :sugerencia
      comentario: comentario,
      calificacion: calificacion,
      fecha: DateTime.utc_now()
    }

    %{mentor | retroalimentacion: [nueva_retro | mentor.retroalimentacion]}
  end

  def ver_historial_retroalimentacion(mentor) do
    IO.puts("\n=== Historial de Retroalimentación - #{mentor.nombre} ===")
    Enum.each(mentor.retroalimentacion, fn retro ->
      IO.puts("\nEquipo: #{retro.equipo}")
      IO.puts("Tipo: #{retro.tipo}")
      IO.puts("Comentario: #{retro.comentario}")
      if retro.calificacion do
        IO.puts("Calificación: #{retro.calificacion}/5")
      end
      IO.puts("Fecha: #{Calendar.strftime(retro.fecha, "%Y-%m-%d %H:%M")}")
    end)

    mentor.retroalimentacion
  end

  def calcular_calificacion_promedio(mentor) do
    calificaciones =
      Enum.filter(mentor.retroalimentacion, fn r -> r.calificacion != nil end)
      |> Enum.map(fn r -> r.calificacion end)

    if Enum.empty?(calificaciones) do
      0
    else
      Enum.sum(calificaciones) / length(calificaciones)
    end
  end

  def generar_reporte_mentor(mentor) do
    total_consultas = length(mentor.consultas_recibidas)
    consultas_pendientes = length(ver_consultas_pendientes(mentor))
    consultas_respondidas = total_consultas - consultas_pendientes
    total_retroalimentacion = length(mentor.retroalimentacion)
    calificacion_promedio = calcular_calificacion_promedio(mentor)

    IO.puts("\n╔════════════════════════════════════════╗")
    IO.puts("║  REPORTE DE MENTORÍA - #{String.pad_trailing(mentor.nombre, 16)} ║")
    IO.puts("╚════════════════════════════════════════╝")
    IO.puts("\n📊 Estadísticas:")
    IO.puts("   • Total de consultas: #{total_consultas}")
    IO.puts("   • Consultas respondidas: #{consultas_respondidas}")
    IO.puts("   • Consultas pendientes: #{consultas_pendientes}")
    IO.puts("   • Total retroalimentaciones: #{total_retroalimentacion}")
    IO.puts("   • Calificación promedio: #{Float.round(calificacion_promedio, 2)}/5")
    IO.puts("\n👥 Equipo asignado: #{mentor.equipo}")
  end

  # ===== FUNCIONALIDAD 3: Integración con Archivos =====

  def guardar_datos_completos(mentor, nombre_archivo) do
    datos = %{
      info_basica: %{
        nombre: mentor.nombre,
        identificacion: mentor.identificacion,
        celular: mentor.celular,
        edad: mentor.edad,
        equipo: mentor.equipo
      },
      consultas: mentor.consultas_recibidas,
      retroalimentacion: mentor.retroalimentacion
    }

    contenido = :erlang.term_to_binary(datos)
    File.write!(nombre_archivo, contenido)
    IO.puts("✓ Datos del mentor guardados en #{nombre_archivo}")
  end

  def cargar_datos_completos(nombre_archivo) do
    case File.read(nombre_archivo) do
      {:ok, contenido} ->
        datos = :erlang.binary_to_term(contenido)
        info = datos.info_basica

        %Mentor{
          nombre: info.nombre,
          identificacion: info.identificacion,
          celular: info.celular,
          edad: info.edad,
          equipo: info.equipo,
          consultas_recibidas: datos.consultas,
          retroalimentacion: datos.retroalimentacion
        }
      {:error, reason} ->
        IO.puts("Error al cargar datos: #{reason}")
        nil
    end
  end

  # ===== Funciones Originales Mantenidas =====

  def escribir_csv(lista_mentores, nombre_archivo) do
    encabezado = "Nombre,Identificacion,Celular,Edad,Equipo\n"
    contenido =
      Enum.map(lista_mentores, fn %Mentor{
        nombre: nombre,
        identificacion: identificacion,
        celular: celular,
        edad: edad,
        equipo: equipo
      } ->
        "#{nombre},#{identificacion},#{celular},#{edad},#{equipo}\n"
      end)
      |> Enum.join("")

    File.write!(nombre_archivo, encabezado <> contenido)
  end

  def leer_csv(nombre_archivo) do
    case File.read(nombre_archivo) do
      {:ok, contenido} ->
        String.split(contenido, "\n")
        |> Enum.map(fn linea ->
          case String.split(linea, ",") do
            [nombre, identificacion, celular, edad, equipo]
            when is_binary(nombre) and is_binary(identificacion)
            and is_binary(celular) and is_binary(edad)
            and is_binary(equipo) ->
              %Mentor{
                nombre: String.trim(nombre),
                identificacion: String.trim(identificacion),
                celular: String.trim(celular),
                edad: String.trim(edad),
                equipo: String.trim(equipo)
              }
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
      {:error, _reason} ->
        IO.puts("Error al leer el archivo #{nombre_archivo}")
        []
    end
  end

  def asignar_mentor_a_equipo(mentor, nombre_equipo) do
    %{mentor | equipo: nombre_equipo}
  end
end
