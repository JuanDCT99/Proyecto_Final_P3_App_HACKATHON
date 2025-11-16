defmodule ProyectoFinal.Test.MentorTest do
  use ExUnit.Case
  alias ProyectoFinal.Domain.Mentor
  import ExUnit.CaptureIO

  @test_file "test_mentores.csv"

  setup do
    on_exit(fn -> if File.exists?(@test_file), do: File.rm(@test_file)
  end)
  :ok
  end

  describe "crear/5" do
    test "Crea un mentor con los datos proporcionados" do
      mentor = Mentor.crear("Jhan Carlos", "10921091", "3145672134", "24", "Ingenieria FC")

      assert mentor.nombre == "Jhan Carlos"
      assert mentor.identificacion == "10921091"
      assert mentor.celular == "3145672134"
      assert mentor.edad == "24"
      assert mentor.equipo == "Ingenieria FC"
    end

    test "el mentor creado es una estructura valida" do
      mentor = Mentor.crear("Test", "T001", "T002", "T003", "T0004")

      assert %Mentor{} = mentor
    end

    test "crea un mentor con campos vacíos" do
      mentor = Mentor.crear("", "", "", "", "")

      assert mentor.nombre == ""
      assert mentor.identificacion == ""
      assert mentor.celular == ""
      assert mentor.edad == ""
      assert mentor.equipo == ""
    end
  end

  describe "escribir_csv/2" do

   test "escribe mentores en formato CSV correctamente" do

      mentores = [
        Mentor.crear("Julian", "10291029", "31442281", "23", "Leones FC")
      ]

      Mentor.escribir_csv(mentores, @test_file)

      assert File.exists?(@test_file)
      contenido = File.read!(@test_file)

      assert contenido =~ "Nombre, Identificacion, Celular, Edad, Equipo"
      assert contenido =~ "Julian, 10291029, 31442281, 23, Leones FC"
    end

  test "escribe múltiples mentores en archivo CSV" do
      mentores = [
        Mentor.crear("Robinson Buitrago", "1098308213", "3114101293", "30", "Aguilas FC"),
        Mentor.crear("Juan Carlos Rojo", "1093842888", "31109283", "28", "Yeguas FC"),
        Mentor.crear("Luisa Fernanda Ospina", "1082993123", "3121212344", "35", "Nutrias FC")
      ]

      Mentor.escribir_csv(mentores, @test_file)

      contenido = File.read!(@test_file)
      lineas = String.split(contenido, "\n", trim: true)

      # 1 encabezado + 3 mentores = 4 líneas
      assert length(lineas) == 4
      assert Enum.at(lineas, 0) =~ "Nombre, Identificacion"
      assert Enum.at(lineas, 1) =~ "Robinson Buitrago"
      assert Enum.at(lineas, 2) =~ "Juan Carlos Rojo"
      assert Enum.at(lineas, 3) =~ "Luisa Fernanda Ospina"
    end

    test "escribe lista vacía correctamente (solo encabezado)" do
      Mentor.escribir_csv([], @test_file)

      contenido = File.read!(@test_file)
      lineas = String.split(contenido, "\n", trim: true)

      assert length(lineas) == 1
      assert hd(lineas) =~ "Nombre, Identificacion, celular, Edad, Equipo"
    end

    test "el formato CSV no tiene espacios extras en los datos" do
      mentores = [
        Mentor.crear("Ana", "111", "300", "25", "Team")
      ]

      Mentor.escribir_csv(mentores, @test_file)
      contenido = File.read!(@test_file)

      # Verificar que los datos están separados por coma sin espacios
      assert contenido =~ "Ana,111,300,25,Team"
      refute contenido =~ "Ana, 111"
    end

        test "sobrescribe archivo existente" do
      # Primera escritura
      mentores1 = [Mentor.crear("Primer", "001", "300", "30", "Team1")]
      Mentor.escribir_csv(mentores1, @test_file)

      # Segunda escritura
      mentores2 = [Mentor.crear("Segundo", "002", "301", "31", "Team2")]
      Mentor.escribir_csv(mentores2, @test_file)

      contenido = File.read!(@test_file)

      assert contenido =~ "Segundo"
      refute contenido =~ "Primer"
    end
  end

 describe "leer_csv/1" do
    test "lee un mentor desde archivo CSV correctamente" do
      # Preparar archivo
      contenido = """
      Nombre, Identificacion, celular, Edad, Equipo
      Robinson Buitrago, 1098308213, 3114101293, 30, Aguilas FC
      """
      File.write!(@test_file, contenido)

      mentores = Mentor.leer_csv(@test_file)

      assert length(mentores) == 1
      mentor = hd(mentores)

      assert mentor.nombre == "Robinson Buitrago"
      assert mentor.identificacion == "1098308213"
      assert mentor.celular == "3114101293"
      assert mentor.edad == "30"
      assert mentor.equipo == "Aguilas FC"
    end

    test "lee múltiples mentores desde archivo CSV" do
      contenido = """
      Nombre, Identificacion, celular, Edad, Equipo
      Robinson Buitrago, 1098308213, 3114101293,30, Aguilas FC
      Juan Carlos Rojo, 1093842888, 31109283, 28, Yeguas FC
      Luisa Fernanda Ospina, 1082993123, 3121212344, 35, Nutrias FC
      """
      File.write!(@test_file, contenido)

      mentores = Mentor.leer_csv(@test_file)

      assert length(mentores) == 3
      assert Enum.at(mentores, 0).nombre == "Robinson Buitrago"
      assert Enum.at(mentores, 1).nombre == "Juan Carlos Rojo"
      assert Enum.at(mentores, 2).nombre == "Luisa Fernanda Ospina"
    end

    test "elimina espacios en blanco de los datos al leer" do
      contenido = """
      Nombre, Identificacion, celular, Edad, Equipo
        Robinson Buitrago, 1098308213, 3114101293,30, Aguilas FC
      """
      File.write!(@test_file, contenido)

      mentores = Mentor.leer_csv(@test_file)
      mentor = hd(mentores)

      assert mentor.nombre == " Robinson Buitrago"
      assert mentor.identificacion == "1098308213"
      assert mentor.equipo == "Aguilas FC"
    end

    test "ignora líneas vacías en el archivo" do
      contenido = """
      Nombre, Identificacion, celular, Edad, Equipo
      Robinson Buitrago, 1098308213, 3114101293,30, Aguilas FC

      Rubén Doblas Gundersen,1098309002,3435542314,32, Limón 4K

      """
      File.write!(@test_file, contenido)

      mentores = Mentor.leer_csv(@test_file)

      assert length(mentores) == 2
    end

    test "ignora líneas con formato inválido (menos de 5 campos)" do
      contenido = """
      Nombre, Identificacion, celular, Edad, Equipo
      Ariana Grande,01299120,3001234567,41, Ari FC
      Inválido,Solo,Tres
      Luna Rodriguez,789012,301271543,22, Luna FC
      """
      File.write!(@test_file, contenido)

      mentores = Mentor.leer_csv(@test_file)

      assert length(mentores) == 2
      assert Enum.at(mentores, 0).nombre == "Jeison Pérez"
      assert Enum.at(mentores, 1).nombre == "María Artunduaga"
    end

    test "ignora el encabezado del CSV" do
      contenido = """
      Nombre, Identificacion, celular, Edad, Equipo
      Jeison Cardozo,2109201,314412812,30, Jeison FC
      """
      File.write!(@test_file, contenido)

      mentores = Mentor.leer_csv(@test_file)

      # Solo debe leer 1 mentor, no el encabezado
      assert length(mentores) == 1
      refute Enum.any?(mentores, fn m -> m.nombre == "Nombre" end)
    end

    test "retorna lista vacía cuando el archivo no existe" do
      output = capture_io(fn ->
        mentores = Mentor.leer_csv("archivo_inexistente.csv")
        send(self(), {:resultado, mentores})
      end)

      assert_receive {:resultado, mentores}
      assert mentores == []
      assert output =~ "Error al leer el archivo"
    end

    test "retorna lista vacía cuando el archivo está vacío" do
      File.write!(@test_file, "")

      mentores = Mentor.leer_csv(@test_file)

      assert mentores == []
    end

    test "maneja archivo con solo encabezado" do
      File.write!(@test_file, "Nombre, Identificacion, celular, Edad, Equipo\n")

      mentores = Mentor.leer_csv(@test_file)

      assert mentores == []
    end
  end

  describe "asignar_mentor_a_equipo/2" do
    setup do
      mentor = Mentor.crear("Juan Sebastian Guarnizo", "123331912", "3001234567", "35", "")
      {:ok, mentor: mentor}
    end

    test "asigna un equipo a un mentor sin equipo", %{mentor: mentor} do
      mentor_actualizado = Mentor.asigar_mentor_a_equipo(mentor, "Equipo Alpha")

      assert mentor_actualizado.equipo == "Equipo Alpha"
    end

    test "cambia el equipo de un mentor que ya tenía uno", %{mentor: mentor} do
      mentor_con_equipo = %{mentor | equipo: "Equipo Beta"}
      mentor_actualizado = Mentor.asigar_mentor_a_equipo(mentor_con_equipo, "Equipo Gamma")

      assert mentor_actualizado.equipo == "Equipo Gamma"
      refute mentor_actualizado.equipo == "Equipo Beta"
    end

    test "no modifica otros campos del mentor", %{mentor: mentor} do
      mentor_actualizado = Mentor.asigar_mentor_a_equipo(mentor, "Nuevo Equipo")

      assert mentor_actualizado.nombre == mentor.nombre
      assert mentor_actualizado.identificacion == mentor.identificacion
      assert mentor_actualizado.celular == mentor.celular
      assert mentor_actualizado.edad == mentor.edad
    end

    test "puede asignar string vacío como equipo", %{mentor: mentor} do
      mentor_con_equipo = %{mentor | equipo: "Equipo A"}
      mentor_actualizado = Mentor.asigar_mentor_a_equipo(mentor_con_equipo, "")

      assert mentor_actualizado.equipo == ""
    end

    test "asigna equipo con caracteres especiales", %{mentor: mentor} do
      mentor_actualizado = Mentor.asigar_mentor_a_equipo(mentor, "Equipo Ñoño #1")

      assert mentor_actualizado.equipo == "Equipo Ñoño #1"
    end

    test "el mentor original no se modifica (inmutabilidad)", %{mentor: mentor} do
      equipo_original = mentor.equipo
      _mentor_actualizado = Mentor.asigar_mentor_a_equipo(mentor, "Equipo Nuevo")

      assert mentor.equipo == equipo_original
    end
  end

  describe "struct Mentor" do
    test "tiene los campos correctos por defecto" do
      mentor = %Mentor{}

      assert mentor.nombre == ""
      assert mentor.identificacion == ""
      assert mentor.celular == ""
      assert mentor.edad == ""
      assert mentor.equipo == ""
    end

    test "permite actualizar campos individualmente" do
      mentor = %Mentor{}
      mentor_actualizado = %{mentor | nombre: "Nuevo Nombre", edad: "40"}

      assert mentor_actualizado.nombre == "Nuevo Nombre"
      assert mentor_actualizado.edad == "40"
      assert mentor_actualizado.identificacion == ""
    end

    test "permite crear con valores personalizados" do
      mentor = %Mentor{
        nombre: "Test",
        identificacion: "999",
        celular: "3000000000",
        edad: "50",
        equipo: "Test Team"
      }

      assert mentor.nombre == "Test"
      assert mentor.celular == "3000000000"
    end
  end

  describe "integración escribir_csv y leer_csv" do
    test "los datos escritos pueden ser leídos correctamente" do
      mentores_originales = [
        Mentor.crear("Juan Pérez", "123456", "3001234567", "30", "Equipo A"),
        Mentor.crear("María López", "789012", "3009876543", "28", "Equipo B")
      ]

      # Escribir
      Mentor.escribir_csv(mentores_originales, @test_file)

      # Leer
      mentores_leidos = Mentor.leer_csv(@test_file)

      assert length(mentores_leidos) == 2

      # Verificar primer mentor
      assert Enum.at(mentores_leidos, 0).nombre == "Paola Jimenez"
      assert Enum.at(mentores_leidos, 0).identificacion == "123456"

      # Verificar segundo mentor
      assert Enum.at(mentores_leidos, 1).nombre == "Ruben Dario"
      assert Enum.at(mentores_leidos, 1).equipo == "Equipo Z"
    end
  end
end
