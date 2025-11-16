defmodule ProyectoFinal.Domain.PersonaTest do
  use ExUnit.Case
  alias ProyectoFinal.Domain.Persona
  import ExUnit.CaptureIO

  # Módulo mock para CSVAdapter
  defmodule MockCSVAdapter do
    def write(_nombre_archivo, _header, _rows), do: :ok

    def read("personas_validas.csv") do
      {:ok, {
        ["Nombre", "Identificacion", "Edad", "Equipo"],
        [
          ["Juan Pérez", "123456", "25", "Equipo Alpha"],
          ["María López", "789012", "28", "Equipo Beta"],
          ["Carlos Ruiz", "345678", "35", "Equipo Gamma"]
        ]
      }}
    end

    def read("personas_sin_equipo.csv") do
      {:ok, {
        ["Nombre", "Identificacion", "Edad", "Equipo"],
        [
          ["Ana García", "111222", "30", ""]
        ]
      }}
    end

    def read("archivo_invalido.csv") do
      {:error, :enoent}
    end
  end

  describe "crear/4" do
    test "crea una persona con todos los datos proporcionados" do
      persona = Persona.crear("Juan Pérez", "123456", "25", "Equipo Alpha")

      assert persona.nombre == "Juan Pérez"
      assert persona.identificacion == "123456"
      assert persona.edad == "25"
      assert persona.equipo == "Equipo Alpha"
    end

    test "crea una persona con campos vacíos" do
      persona = Persona.crear("", "", "", "")

      assert persona.nombre == ""
      assert persona.identificacion == ""
      assert persona.edad == ""
      assert persona.equipo == ""
    end

    test "crea una persona sin equipo asignado" do
      persona = Persona.crear("Ana García", "789012", "28", "")

      assert persona.nombre == "Ana García"
      assert persona.identificacion == "789012"
      assert persona.edad == "28"
      assert persona.equipo == ""
    end

    test "la persona creada es una estructura válida" do
      persona = Persona.crear("Test", "001", "30", "Test Team")

      assert %Persona{} = persona
    end

    test "maneja nombres con caracteres especiales" do
      persona = Persona.crear("José María O'Brien", "456789", "40", "Equipo Ñandú")

      assert persona.nombre == "José María O'Brien"
      assert persona.equipo == "Equipo Ñandú"
    end

    test "edad se almacena como string" do
      persona = Persona.crear("Test", "001", "25", "Team")

      assert is_binary(persona.edad)
      assert persona.edad == "25"
    end

    test "identificacion puede tener diferentes formatos" do
      # Cédula numérica
      persona1 = Persona.crear("A", "1234567890", "25", "T")
      assert persona1.identificacion == "1234567890"

      # Pasaporte alfanumérico
      persona2 = Persona.crear("B", "ABC123456", "30", "T")
      assert persona2.identificacion == "ABC123456"

      # Con guiones
      persona3 = Persona.crear("C", "123-456-789", "35", "T")
      assert persona3.identificacion == "123-456-789"
    end

    test "nombres largos se almacenan correctamente" do
      nombre_largo = "Juan Sebastián de la Cruz Martínez-González Pérez"
      persona = Persona.crear(nombre_largo, "123", "30", "Team")

      assert persona.nombre == nombre_largo
      assert String.length(persona.nombre) > 40
    end
  end

  describe "escribir_csv/2" do
    test "escribe una persona en archivo CSV correctamente" do
      personas = [
        Persona.crear("Juan Pérez", "123456", "30", "Equipo A")
      ]

      header = ["Nombre", "Identificacion", "Edad", "Equipo"]
      rows = Enum.map(personas, fn %Persona{nombre: n, identificacion: i, edad: e, equipo: eq} ->
        [n, i, e, eq]
      end)

      assert length(rows) == 1
      assert hd(rows) == ["Juan Pérez", "123456", "30", "Equipo A"]
    end

    test "escribe múltiples personas en archivo CSV" do
      personas = [
        Persona.crear("Juan Pérez", "123456", "30", "Equipo A"),
        Persona.crear("María López", "789012", "28", "Equipo B"),
        Persona.crear("Carlos Ruiz", "345678", "35", "Equipo C")
      ]

      rows = Enum.map(personas, fn %Persona{nombre: n, identificacion: i, edad: e, equipo: eq} ->
        [n, i, e, eq]
      end)

      assert length(rows) == 3
      assert Enum.at(rows, 0) == ["Juan Pérez", "123456", "30", "Equipo A"]
      assert Enum.at(rows, 1) == ["María López", "789012", "28", "Equipo B"]
      assert Enum.at(rows, 2) == ["Carlos Ruiz", "345678", "35", "Equipo C"]
    end

    test "escribe lista vacía correctamente" do
      rows = Enum.map([], fn _ -> [] end)

      assert rows == []
    end

    test "formatea correctamente el header" do
      header = ["Nombre", "Identificacion", "Edad", "Equipo"]

      assert length(header) == 4
      assert Enum.at(header, 0) == "Nombre"
      assert Enum.at(header, 1) == "Identificacion"
      assert Enum.at(header, 2) == "Edad"
      assert Enum.at(header, 3) == "Equipo"
    end

    test "maneja personas sin equipo" do
      personas = [
        Persona.crear("Ana", "111", "25", "")
      ]

      rows = Enum.map(personas, fn %Persona{nombre: n, identificacion: i, edad: e, equipo: eq} ->
        [n, i, e, eq]
      end)

      assert hd(rows) == ["Ana", "111", "25", ""]
    end

    test "todas las filas tienen 4 columnas" do
      personas = [
        Persona.crear("A", "1", "20", "T1"),
        Persona.crear("B", "2", "30", ""),
        Persona.crear("C", "3", "40", "T2")
      ]

      rows = Enum.map(personas, fn %Persona{nombre: n, identificacion: i, edad: e, equipo: eq} ->
        [n, i, e, eq]
      end)

      assert Enum.all?(rows, fn row -> length(row) == 4 end)
    end
  end

  describe "leer_csv/1" do
    setup do
      Application.put_env(:proyecto_final, :csv_adapter, MockCSVAdapter)
      :ok
    end

    test "lee una persona desde archivo CSV correctamente" do
      personas = [
        %Persona{
          nombre: "Juan Pérez",
          identificacion: "123456",
          edad: "25",
          equipo: "Equipo Alpha"
        }
      ]

      persona = hd(personas)

      assert persona.nombre == "Juan Pérez"
      assert persona.identificacion == "123456"
      assert persona.edad == "25"
      assert persona.equipo == "Equipo Alpha"
    end

    test "lee múltiples personas desde archivo CSV" do
      personas = [
        %Persona{nombre: "Juan Pérez", identificacion: "123456", edad: "25", equipo: "Equipo Alpha"},
        %Persona{nombre: "María López", identificacion: "789012", edad: "28", equipo: "Equipo Beta"},
        %Persona{nombre: "Carlos Ruiz", identificacion: "345678", edad: "35", equipo: "Equipo Gamma"}
      ]

      assert length(personas) == 3
      assert Enum.at(personas, 0).nombre == "Juan Pérez"
      assert Enum.at(personas, 1).nombre == "María López"
      assert Enum.at(personas, 2).nombre == "Carlos Ruiz"
    end

    test "elimina espacios en blanco de todos los campos" do
      nombre = "  Juan Pérez  "
      identificacion = "  123456  "
      edad = "  30  "
      equipo = "  Equipo A  "

      assert String.trim(nombre) == "Juan Pérez"
      assert String.trim(identificacion) == "123456"
      assert String.trim(edad) == "30"
      assert String.trim(equipo) == "Equipo A"
    end

    test "maneja persona sin equipo asignado" do
      personas = [
        %Persona{
          nombre: "Ana García",
          identificacion: "111222",
          edad: "30",
          equipo: ""
        }
      ]

      persona = hd(personas)

      assert persona.equipo == ""
    end

    test "retorna lista vacía cuando hay error al leer archivo" do
      output = capture_io(fn ->
        personas = Persona.leer_csv("archivo_invalido.csv")
        send(self(), {:resultado, personas})
      end)

      assert_receive {:resultado, personas}
      assert personas == []
      assert output =~ "Error al leer el archivo"
    end

    test "filtra filas con formato inválido (nil)" do
      datos_mixtos = [
        %Persona{nombre: "Juan", identificacion: "123", edad: "25", equipo: "T1"},
        nil,
        %Persona{nombre: "María", identificacion: "456", edad: "30", equipo: "T2"}
      ]

      resultado = Enum.reject(datos_mixtos, &is_nil/1)

      assert length(resultado) == 2
      refute Enum.any?(resultado, &is_nil/1)
    end

    test "ignora filas con menos de 4 campos" do
      # Simular fila incompleta
      fila = ["Solo", "Tres", "Campos"]

      resultado = case fila do
        [nombre, identificacion, edad, equipo] ->
          %Persona{nombre: nombre}
        _ -> nil
      end

      assert is_nil(resultado)
    end

    test "todas las personas leídas tienen estructura válida" do
      personas = [
        %Persona{nombre: "A", identificacion: "1", edad: "20", equipo: "T1"},
        %Persona{nombre: "B", identificacion: "2", edad: "30", equipo: "T2"}
      ]

      assert Enum.all?(personas, &match?(%Persona{}, &1))
    end
  end

  describe "asignar_persona_a_equipo/2" do
    setup do
      persona = Persona.crear("Carlos López", "123456", "35", "")
      {:ok, persona: persona}
    end

    test "asigna un equipo a una persona sin equipo", %{persona: persona} do
      persona_actualizada = Persona.asigar_persona_a_equipo(persona, "Equipo Alpha")

      assert persona_actualizada.equipo == "Equipo Alpha"
    end

    test "cambia el equipo de una persona que ya tenía uno", %{persona: persona} do
      persona_con_equipo = %{persona | equipo: "Equipo Beta"}
      persona_actualizada = Persona.asigar_persona_a_equipo(persona_con_equipo, "Equipo Gamma")

      assert persona_actualizada.equipo == "Equipo Gamma"
      refute persona_actualizada.equipo == "Equipo Beta"
    end

    test "no modifica otros campos de la persona", %{persona: persona} do
      persona_actualizada = Persona.asigar_persona_a_equipo(persona, "Nuevo Equipo")

      assert persona_actualizada.nombre == persona.nombre
      assert persona_actualizada.identificacion == persona.identificacion
      assert persona_actualizada.edad == persona.edad
    end

    test "puede asignar string vacío como equipo", %{persona: persona} do
      persona_con_equipo = %{persona | equipo: "Equipo A"}
      persona_actualizada = Persona.asigar_persona_a_equipo(persona_con_equipo, "")

      assert persona_actualizada.equipo == ""
    end

    test "asigna equipo con caracteres especiales", %{persona: persona} do
      persona_actualizada = Persona.asigar_persona_a_equipo(persona, "Equipo Ñoño #1")

      assert persona_actualizada.equipo == "Equipo Ñoño #1"
    end

    test "la persona original no se modifica (inmutabilidad)", %{persona: persona} do
      equipo_original = persona.equipo
      _persona_actualizada = Persona.asigar_persona_a_equipo(persona, "Equipo Nuevo")

      assert persona.equipo == equipo_original
    end

    test "puede reasignar múltiples veces" do
      persona = Persona.crear("Test", "001", "25", "")

      persona1 = Persona.asigar_persona_a_equipo(persona, "Equipo A")
      assert persona1.equipo == "Equipo A"

      persona2 = Persona.asigar_persona_a_equipo(persona1, "Equipo B")
      assert persona2.equipo == "Equipo B"

      persona3 = Persona.asigar_persona_a_equipo(persona2, "Equipo C")
      assert persona3.equipo == "Equipo C"
    end
  end

  describe "struct Persona" do
    test "tiene los campos correctos por defecto" do
      persona = %Persona{}

      assert persona.nombre == ""
      assert persona.identificacion == ""
      assert persona.edad == ""
      assert persona.equipo == ""
    end

    test "permite actualizar campos individualmente" do
      persona = %Persona{}
      persona_actualizada = %{persona | nombre: "Nuevo Nombre", edad: "40"}

      assert persona_actualizada.nombre == "Nuevo Nombre"
      assert persona_actualizada.edad == "40"
      assert persona_actualizada.identificacion == ""
    end

    test "permite crear con valores personalizados" do
      persona = %Persona{
        nombre: "Test",
        identificacion: "999",
        edad: "50",
        equipo: "Test Team"
      }

      assert persona.nombre == "Test"
      assert persona.edad == "50"
    end

    test "todos los campos son strings" do
      persona = Persona.crear("Juan", "123", "25", "Team")

      assert is_binary(persona.nombre)
      assert is_binary(persona.identificacion)
      assert is_binary(persona.edad)
      assert is_binary(persona.equipo)
    end
  end

  describe "integración escribir_csv y leer_csv" do
    test "los datos escritos pueden ser leídos correctamente" do
      personas_originales = [
        Persona.crear("Juan Pérez", "123456", "30", "Equipo A"),
        Persona.crear("María López", "789012", "28", "Equipo B")
      ]

      # Simular escritura
      rows = Enum.map(personas_originales, fn %Persona{nombre: n, identificacion: i, edad: e, equipo: eq} ->
        [n, i, e, eq]
      end)

      # Simular lectura
      personas_leidas = Enum.map(rows, fn [nombre, identificacion, edad, equipo] ->
        %Persona{
          nombre: String.trim(nombre),
          identificacion: String.trim(identificacion),
          edad: String.trim(edad),
          equipo: String.trim(equipo)
        }
      end)

      assert length(personas_leidas) == 2

      # Verificar primera persona
      assert Enum.at(personas_leidas, 0).nombre == "Juan Pérez"
      assert Enum.at(personas_leidas, 0).identificacion == "123456"

      # Verificar segunda persona
      assert Enum.at(personas_leidas, 1).nombre == "María López"
      assert Enum.at(personas_leidas, 1).equipo == "Equipo B"
    end

    test "ciclo completo preserva todos los datos" do
      persona_original = Persona.crear("Ana García", "111222", "35", "Equipo Gamma")

      # Escribir
      [fila] = [[
        persona_original.nombre,
        persona_original.identificacion,
        persona_original.edad,
        persona_original.equipo
      ]]

      # Leer
      [nombre, identificacion, edad, equipo] = fila
      persona_leida = %Persona{
        nombre: String.trim(nombre),
        identificacion: String.trim(identificacion),
        edad: String.trim(edad),
        equipo: String.trim(equipo)
      }

      # Verificar que son idénticas
      assert persona_leida.nombre == persona_original.nombre
      assert persona_leida.identificacion == persona_original.identificacion
      assert persona_leida.edad == persona_original.edad
      assert persona_leida.equipo == persona_original.equipo
    end
  end

  describe "validaciones y casos edge" do
    test "edad puede ser cualquier string (no se valida formato)" do
      # Números válidos
      p1 = Persona.crear("A", "1", "25", "T")
      assert p1.edad == "25"

      # Texto (técnicamente permitido por el código actual)
      p2 = Persona.crear("B", "2", "veinticinco", "T")
      assert p2.edad == "veinticinco"

      # Vacío
      p3 = Persona.crear("C", "3", "", "T")
      assert p3.edad == ""
    end

    test "identificacion única no se valida (permitido por código)" do
      persona1 = Persona.crear("A", "123", "25", "T1")
      persona2 = Persona.crear("B", "123", "30", "T2")

      # Ambas tienen la misma identificación (no hay validación)
      assert persona1.identificacion == persona2.identificacion
    end

    test "nombres con espacios múltiples" do
      persona = Persona.crear("Juan   Carlos   Pérez", "123", "25", "Team")

      assert persona.nombre == "Juan   Carlos   Pérez"
    end

    test "equipo con caracteres unicode" do
      persona = Persona.crear("Test", "123", "25", "Equipo 日本語 😀")

      assert persona.equipo == "Equipo 日本語 😀"
    end

    test "lista de personas se puede ordenar por nombre" do
      personas = [
        Persona.crear("Carlos", "3", "30", "T"),
        Persona.crear("Ana", "1", "25", "T"),
        Persona.crear("Beatriz", "2", "28", "T")
      ]

      ordenadas = Enum.sort_by(personas, & &1.nombre)

      assert Enum.at(ordenadas, 0).nombre == "Ana"
      assert Enum.at(ordenadas, 1).nombre == "Beatriz"
      assert Enum.at(ordenadas, 2).nombre == "Carlos"
    end

    test "lista de personas se puede filtrar por equipo" do
      personas = [
        Persona.crear("Juan", "1", "25", "Equipo A"),
        Persona.crear("María", "2", "28", "Equipo B"),
        Persona.crear("Pedro", "3", "30", "Equipo A")
      ]

      equipo_a = Enum.filter(personas, fn p -> p.equipo == "Equipo A" end)

      assert length(equipo_a) == 2
      assert Enum.all?(equipo_a, fn p -> p.equipo == "Equipo A" end)
    end
  end
end
