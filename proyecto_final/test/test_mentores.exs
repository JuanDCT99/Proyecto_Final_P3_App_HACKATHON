defmodule MentorTest do
  use ExUnit.Case
  doctest Mentor

  # Setup para crear un mentor de prueba antes de cada test
  setup do
    mentor = Mentor.crear("Juan Pérez", "123456", "3001234567", "35", "Equipo A")
    {:ok, mentor: mentor}
  end

  # ===== TESTS DE FUNCIONES BÁSICAS =====

  describe "crear/5" do
    test "crea un mentor con los datos correctos" do
      mentor = Mentor.crear("Ana García", "789012", "3109876543", "28", "Equipo B")

      assert mentor.nombre == "Ana García"
      assert mentor.identificacion == "789012"
      assert mentor.celular == "3109876543"
      assert mentor.edad == "28"
      assert mentor.equipo == "Equipo B"
      assert mentor.consultas_recibidas == []
      assert mentor.retroalimentacion == []
    end

    test "crea un mentor con listas vacías por defecto" do
      mentor = Mentor.crear("Test", "111", "222", "30", "Equipo Test")

      assert is_list(mentor.consultas_recibidas)
      assert Enum.empty?(mentor.consultas_recibidas)
      assert is_list(mentor.retroalimentacion)
      assert Enum.empty?(mentor.retroalimentacion)
    end
  end

  describe "asignar_mentor_a_equipo/2" do
    test "asigna un mentor a un nuevo equipo", %{mentor: mentor} do
      mentor_actualizado = Mentor.asignar_mentor_a_equipo(mentor, "Equipo C")

      assert mentor_actualizado.equipo == "Equipo C"
      assert mentor_actualizado.nombre == mentor.nombre
    end

    test "preserva los demás datos al cambiar equipo", %{mentor: mentor} do
      mentor_actualizado = Mentor.asignar_mentor_a_equipo(mentor, "Nuevo Equipo")

      assert mentor_actualizado.identificacion == mentor.identificacion
      assert mentor_actualizado.celular == mentor.celular
      assert mentor_actualizado.edad == mentor.edad
    end
  end

  # ===== TESTS DE CANAL DE CONSULTAS =====

  describe "enviar_consulta/3" do
    test "agrega una consulta al mentor", %{mentor: mentor} do
      mentor_con_consulta = Mentor.enviar_consulta(
        mentor,
        "Equipo B",
        "¿Cómo mejorar el código?"
      )

      assert length(mentor_con_consulta.consultas_recibidas) == 1
      consulta = hd(mentor_con_consulta.consultas_recibidas)
      assert consulta.equipo == "Equipo B"
      assert consulta.consulta == "¿Cómo mejorar el código?"
      assert consulta.respondida == false
      assert consulta.respuesta == nil
    end

    test "agrega múltiples consultas correctamente", %{mentor: mentor} do
      mentor = Mentor.enviar_consulta(mentor, "Equipo B", "Consulta 1")
      mentor = Mentor.enviar_consulta(mentor, "Equipo C", "Consulta 2")
      mentor = Mentor.enviar_consulta(mentor, "Equipo D", "Consulta 3")

      assert length(mentor.consultas_recibidas) == 3
    end

    test "las consultas tienen fecha de creación", %{mentor: mentor} do
      mentor_con_consulta = Mentor.enviar_consulta(mentor, "Equipo B", "Test")
      consulta = hd(mentor_con_consulta.consultas_recibidas)

      assert %DateTime{} = consulta.fecha
    end
  end

  describe "ver_consultas_pendientes/1" do
    test "retorna solo consultas no respondidas", %{mentor: mentor} do
      mentor = Mentor.enviar_consulta(mentor, "Equipo B", "Consulta 1")
      mentor = Mentor.enviar_consulta(mentor, "Equipo C", "Consulta 2")
      mentor = Mentor.responder_consulta(mentor, 0, "Respuesta 1")

      pendientes = Mentor.ver_consultas_pendientes(mentor)

      assert length(pendientes) == 1
      assert hd(pendientes).consulta == "Consulta 2"
    end

    test "retorna lista vacía si todas están respondidas", %{mentor: mentor} do
      mentor = Mentor.enviar_consulta(mentor, "Equipo B", "Consulta 1")
      mentor = Mentor.responder_consulta(mentor, 0, "Respuesta")

      pendientes = Mentor.ver_consultas_pendientes(mentor)

      assert Enum.empty?(pendientes)
    end
  end

  describe "responder_consulta/3" do
    test "marca consulta como respondida y agrega respuesta", %{mentor: mentor} do
      mentor = Mentor.enviar_consulta(mentor, "Equipo B", "¿Ayuda?")
      mentor = Mentor.responder_consulta(mentor, 0, "Claro, aquí está mi respuesta")

      consulta = hd(mentor.consultas_recibidas)
      assert consulta.respondida == true
      assert consulta.respuesta == "Claro, aquí está mi respuesta"
    end

    test "responde la consulta correcta por índice", %{mentor: mentor} do
      mentor = Mentor.enviar_consulta(mentor, "Equipo B", "Consulta 1")
      mentor = Mentor.enviar_consulta(mentor, "Equipo C", "Consulta 2")
      mentor = Mentor.enviar_consulta(mentor, "Equipo D", "Consulta 3")

      mentor = Mentor.responder_consulta(mentor, 1, "Respuesta a consulta 2")

      consulta_respondida = Enum.at(mentor.consultas_recibidas, 1)
      assert consulta_respondida.respondida == true
      assert consulta_respondida.respuesta == "Respuesta a consulta 2"

      # Las otras deben seguir sin responder
      assert Enum.at(mentor.consultas_recibidas, 0).respondida == false
      assert Enum.at(mentor.consultas_recibidas, 2).respondida == false
    end
  end

  # ===== TESTS DE RETROALIMENTACIÓN =====

  describe "agregar_retroalimentacion/5" do
    test "agrega retroalimentación sin calificación", %{mentor: mentor} do
      mentor = Mentor.agregar_retroalimentacion(
        mentor,
        "Equipo B",
        :sugerencia,
        "Sería bueno más reuniones"
      )

      assert length(mentor.retroalimentacion) == 1
      retro = hd(mentor.retroalimentacion)
      assert retro.equipo == "Equipo B"
      assert retro.tipo == :sugerencia
      assert retro.comentario == "Sería bueno más reuniones"
      assert retro.calificacion == nil
    end

    test "agrega retroalimentación con calificación", %{mentor: mentor} do
      mentor = Mentor.agregar_retroalimentacion(
        mentor,
        "Equipo C",
        :positiva,
        "Excelente mentor",
        5
      )

      retro = hd(mentor.retroalimentacion)
      assert retro.calificacion == 5
    end

    test "agrega múltiples retroalimentaciones", %{mentor: mentor} do
      mentor = Mentor.agregar_retroalimentacion(mentor, "E1", :positiva, "Bien", 4)
      mentor = Mentor.agregar_retroalimentacion(mentor, "E2", :constructiva, "Mejorar", 3)
      mentor = Mentor.agregar_retroalimentacion(mentor, "E3", :positiva, "Genial", 5)

      assert length(mentor.retroalimentacion) == 3
    end

    test "retroalimentación tiene fecha", %{mentor: mentor} do
      mentor = Mentor.agregar_retroalimentacion(mentor, "E1", :positiva, "Test")
      retro = hd(mentor.retroalimentacion)

      assert %DateTime{} = retro.fecha
    end
  end

  describe "calcular_calificacion_promedio/1" do
    test "calcula promedio correctamente", %{mentor: mentor} do
      mentor = Mentor.agregar_retroalimentacion(mentor, "E1", :positiva, "Bien", 4)
      mentor = Mentor.agregar_retroalimentacion(mentor, "E2", :positiva, "Excelente", 5)
      mentor = Mentor.agregar_retroalimentacion(mentor, "E3", :constructiva, "Regular", 3)

      promedio = Mentor.calcular_calificacion_promedio(mentor)

      assert promedio == 4.0
    end

    test "ignora retroalimentación sin calificación", %{mentor: mentor} do
      mentor = Mentor.agregar_retroalimentacion(mentor, "E1", :positiva, "Sin nota")
      mentor = Mentor.agregar_retroalimentacion(mentor, "E2", :positiva, "Con nota", 5)

      promedio = Mentor.calcular_calificacion_promedio(mentor)

      assert promedio == 5.0
    end

    test "retorna 0 si no hay calificaciones", %{mentor: mentor} do
      promedio = Mentor.calcular_calificacion_promedio(mentor)
      assert promedio == 0
    end
  end

  # ===== TESTS DE ARCHIVOS CSV =====

  describe "escribir_csv/2 y leer_csv/1" do
    test "escribe y lee correctamente un archivo CSV" do
      mentor1 = Mentor.crear("Ana López", "111", "3001111111", "30", "Equipo X")
      mentor2 = Mentor.crear("Carlos Ruiz", "222", "3002222222", "40", "Equipo Y")
      lista = [mentor1, mentor2]

      archivo = "test_mentores.csv"
      Mentor.escribir_csv(lista, archivo)

      mentores_leidos = Mentor.leer_csv(archivo)

      assert length(mentores_leidos) == 2
      assert Enum.at(mentores_leidos, 0).nombre == "Ana López"
      assert Enum.at(mentores_leidos, 1).nombre == "Carlos Ruiz"

      # Limpiar archivo de prueba
      File.rm(archivo)
    end

    test "lee archivo CSV vacío sin errores" do
      archivo = "test_vacio.csv"
      File.write!(archivo, "Nombre,Identificacion,Celular,Edad,Equipo\n")

      mentores = Mentor.leer_csv(archivo)

      assert Enum.empty?(mentores)
      File.rm(archivo)
    end

    test "maneja archivo inexistente", %{} do
      assert capture_io(fn ->
        mentores = Mentor.leer_csv("archivo_inexistente.csv")
        assert Enum.empty?(mentores)
      end) =~ "Error al leer el archivo"
    end
  end

  # ===== TESTS DE PERSISTENCIA COMPLETA =====

  describe "guardar_datos_completos/2 y cargar_datos_completos/1" do
    test "guarda y carga datos completos correctamente", %{mentor: mentor} do
      # Agregar datos al mentor
      mentor = Mentor.enviar_consulta(mentor, "Equipo B", "Consulta test")
      mentor = Mentor.responder_consulta(mentor, 0, "Respuesta test")
      mentor = Mentor.agregar_retroalimentacion(mentor, "Equipo B", :positiva, "Muy bien", 5)

      archivo = "test_mentor_completo.exs"
      Mentor.guardar_datos_completos(mentor, archivo)

      mentor_cargado = Mentor.cargar_datos_completos(archivo)

      assert mentor_cargado.nombre == mentor.nombre
      assert mentor_cargado.identificacion == mentor.identificacion
      assert length(mentor_cargado.consultas_recibidas) == 1
      assert length(mentor_cargado.retroalimentacion) == 1

      consulta = hd(mentor_cargado.consultas_recibidas)
      assert consulta.respondida == true
      assert consulta.respuesta == "Respuesta test"

      File.rm(archivo)
    end

    test "maneja archivo inexistente al cargar", %{} do
      assert capture_io(fn ->
        resultado = Mentor.cargar_datos_completos("no_existe.exs")
        assert resultado == nil
      end) =~ "Error al cargar datos"
    end

    test "preserva todas las consultas y retroalimentaciones", %{mentor: mentor} do
      # Crear datos complejos
      mentor = Mentor.enviar_consulta(mentor, "E1", "C1")
      mentor = Mentor.enviar_consulta(mentor, "E2", "C2")
      mentor = Mentor.enviar_consulta(mentor, "E3", "C3")
      mentor = Mentor.responder_consulta(mentor, 0, "R1")

      mentor = Mentor.agregar_retroalimentacion(mentor, "E1", :positiva, "Bien", 4)
      mentor = Mentor.agregar_retroalimentacion(mentor, "E2", :constructiva, "Mejorar", 3)

      archivo = "test_complejo.exs"
      Mentor.guardar_datos_completos(mentor, archivo)
      mentor_cargado = Mentor.cargar_datos_completos(archivo)

      assert length(mentor_cargado.consultas_recibidas) == 3
      assert length(mentor_cargado.retroalimentacion) == 2
      assert Enum.at(mentor_cargado.consultas_recibidas, 0).respondida == true

      File.rm(archivo)
    end
  end

  # ===== TESTS DE INTEGRACIÓN =====

  describe "flujo completo de mentoría" do
    test "simula un ciclo completo de mentoría", %{mentor: mentor} do
      # 1. Recibir consultas
      mentor = Mentor.enviar_consulta(mentor, "Equipo B", "¿Cómo usar Git?")
      mentor = Mentor.enviar_consulta(mentor, "Equipo C", "¿Qué es Scrum?")

      assert length(mentor.consultas_recibidas) == 2

      # 2. Responder primera consulta
      mentor = Mentor.responder_consulta(mentor, 0, "Git es un sistema de control de versiones")

      pendientes = Mentor.ver_consultas_pendientes(mentor)
      assert length(pendientes) == 1

      # 3. Recibir retroalimentación
      mentor = Mentor.agregar_retroalimentacion(mentor, "Equipo B", :positiva, "Excelente explicación", 5)

      # 4. Calcular estadísticas
      promedio = Mentor.calcular_calificacion_promedio(mentor)
      assert promedio == 5.0

      # 5. Guardar todo
      archivo = "test_flujo_completo.exs"
      Mentor.guardar_datos_completos(mentor, archivo)

      # 6. Cargar y verificar
      mentor_recuperado = Mentor.cargar_datos_completos(archivo)
      assert mentor_recuperado.nombre == "Juan Pérez"
      assert length(mentor_recuperado.consultas_recibidas) == 2
      assert length(mentor_recuperado.retroalimentacion) == 1

      File.rm(archivo)
    end
  end

  # Helper para capturar IO
  defp capture_io(fun) do
    ExUnit.CaptureIO.capture_io(fun)
  end
end
