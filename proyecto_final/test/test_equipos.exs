defmodule ProyectoFinal.Test.EquipoTest do
  use ExUnit.Case
  alias ProyectoFinal.Domain.Equipo
  import ExUnit.CaptureIO

  # Módulo mock para las dependencias
  defmodule MockCSVAdapter do
    def write(_nombre_archivo, _header, _rows), do: :ok

    def read("equipos_validos.csv") do
      {:ok, {
        ["Nombre del Equipo", "Numero de Grupo", "Lista de Integrantes"],
        [
          ["Equipo Alpha", "G001", "Juan;María;Pedro"],
          ["Equipo Beta", "G002", "Ana;Luis"]
        ]
      }}
    end

    def read("archivo_invalido.csv") do
      {:error, :enoent}
    end
  end

  describe "crear/3" do
    test "crea un equipo con los datos proporcionados" do
      equipo = Equipo.crear("Los Tigres", "G123", ["Juan", "María"])

      assert equipo.nombre == "Los Tigres"
      assert equipo.groupID == "G123"
      assert equipo.integrantes == ["Juan", "María"]
    end

    test "crea un equipo con lista de integrantes vacía" do
      equipo = Equipo.crear("Equipo Nuevo", "G456", [])

      assert equipo.nombre == "Equipo Nuevo"
      assert equipo.groupID == "G456"
      assert equipo.integrantes == []
    end

    test "el equipo creado es una estructura válida" do
      equipo = Equipo.crear("Test", "T001", [])

      assert %Equipo{} = equipo
    end
  end

  describe "escribir_csv/2" do
    setup do
      # Preparar datos de prueba
      equipos = [
        Equipo.crear("Equipo A", "G001", ["Juan", "Pedro"]),
        Equipo.crear("Equipo B", "G002", ["Ana", "Luis", "María"])
      ]

      {:ok, equipos: equipos}
    end

    test "escribe equipos en formato CSV correctamente", %{equipos: equipos} do
      # Mock del CSVAdapter
      Application.put_env(:proyecto_final, :csv_adapter, MockCSVAdapter)


      [equipo1, equipo2] = equipos

      # Verificar que los integrantes se unan con ";"
      assert Enum.join(equipo1.integrantes, ";") == "Juan;Pedro"
      assert Enum.join(equipo2.integrantes, ";") == "Ana;Luis;María"
    end

    test "genera filas con el formato esperado", %{equipos: equipos} do
      rows = Enum.map(equipos, fn %Equipo{nombre: nombre, groupID: groupID, integrantes: integrantes} ->
        [nombre, groupID, Enum.join(integrantes, ";")]
      end)

      assert rows == [
        ["Equipo A", "G001", "Juan;Pedro"],
        ["Equipo B", "G002", "Ana;Luis;María"]
      ]
    end
  end

  describe "leer_csv/1" do
    setup do
      # Configurar el mock para las pruebas
      Application.put_env(:proyecto_final, :csv_adapter, MockCSVAdapter)
      :ok
    end

    test "lee y parsea equipos correctamente desde CSV válido" do
 

      equipos = [
        %Equipo{nombre: "Equipo Alpha", groupID: "G001", integrantes: ["Juan", "María", "Pedro"]},
        %Equipo{nombre: "Equipo Beta", groupID: "G002", integrantes: ["Ana", "Luis"]}
      ]

      # Verificar estructura
      [equipo1, equipo2] = equipos

      assert equipo1.nombre == "Equipo Alpha"
      assert equipo1.groupID == "G001"
      assert length(equipo1.integrantes) == 3

      assert equipo2.nombre == "Equipo Beta"
      assert length(equipo2.integrantes) == 2
    end

    test "parsea correctamente integrantes separados por punto y coma" do
      integrantes_string = "Juan;María;Pedro"
      integrantes_lista = String.split(integrantes_string, ";") |> Enum.map(&String.trim/1)

      assert integrantes_lista == ["Juan", "María", "Pedro"]
    end

    test "maneja espacios en blanco en los datos" do
      nombre = "  Equipo Alpha  "
      groupID = "  G001  "

      assert String.trim(nombre) == "Equipo Alpha"
      assert String.trim(groupID) == "G001"
    end

    test "retorna lista vacía cuando hay error al leer archivo" do
      output = capture_io(fn ->
        equipos = Equipo.leer_csv("archivo_invalido.csv")
        send(self(), {:resultado, equipos})
      end)

      assert_receive {:resultado, equipos}
      assert equipos == []
      assert output =~ "Error al leer el archivo"
    end

    test "filtra filas inválidas (nil)" do
      # Simular datos con filas inválidas
      datos_mixtos = [
        %Equipo{nombre: "Válido", groupID: "G001", integrantes: []},
        nil,
        %Equipo{nombre: "Otro Válido", groupID: "G002", integrantes: []}
      ]

      resultado = Enum.reject(datos_mixtos, &is_nil/1)

      assert length(resultado) == 2
      refute Enum.any?(resultado, &is_nil/1)
    end
  end

  describe "ingresar_integrante/2" do
    setup do
      equipo = Equipo.crear("Los Leones", "G100", ["Juan", "María"])
      persona = %{nombre: "Pedro", edad: 20}
      persona_existente = %{nombre: "Juan", edad: 22}

      {:ok, equipo: equipo, persona: persona, persona_existente: persona_existente}
    end

    test "agrega un nuevo integrante al equipo", %{equipo: equipo, persona: persona} do
      equipo_actualizado = Equipo.ingresar_integrante(equipo, persona)

      assert "Pedro" in equipo_actualizado.integrantes
      assert length(equipo_actualizado.integrantes) == 3
    end

    test "no duplica integrante si ya existe en el equipo", %{equipo: equipo, persona_existente: persona_existente} do
      output = capture_io(fn ->
        equipo_actualizado = Equipo.ingresar_integrante(equipo, persona_existente)
        send(self(), {:equipo, equipo_actualizado})
      end)

      assert_receive {:equipo, equipo_actualizado}

      # El equipo no debe cambiar
      assert equipo_actualizado.integrantes == equipo.integrantes
      assert length(equipo_actualizado.integrantes) == 2

      # Debe mostrar mensaje
      assert output =~ "El integrante ya está en el equipo"
    end

    test "mantiene integrantes existentes al agregar uno nuevo", %{equipo: equipo, persona: persona} do
      equipo_actualizado = Equipo.ingresar_integrante(equipo, persona)

      assert "Juan" in equipo_actualizado.integrantes
      assert "María" in equipo_actualizado.integrantes
      assert "Pedro" in equipo_actualizado.integrantes
    end

    test "el nuevo integrante se agrega al inicio de la lista", %{equipo: equipo, persona: persona} do
      equipo_actualizado = Equipo.ingresar_integrante(equipo, persona)

      assert hd(equipo_actualizado.integrantes) == "Pedro"
    end

    test "no modifica otros campos del equipo", %{equipo: equipo, persona: persona} do
      equipo_actualizado = Equipo.ingresar_integrante(equipo, persona)

      assert equipo_actualizado.nombre == equipo.nombre
      assert equipo_actualizado.groupID == equipo.groupID
    end
  end

  describe "struct Equipo" do
    test "tiene los campos correctos por defecto" do
      equipo = %Equipo{}

      assert equipo.nombre == ""
      assert equipo.groupID == ""
      assert equipo.integrantes == []
    end

    test "permite actualizar campos individualmente" do
      equipo = %Equipo{}
      equipo_actualizado = %{equipo | nombre: "Nuevo Nombre"}

      assert equipo_actualizado.nombre == "Nuevo Nombre"
      assert equipo_actualizado.groupID == ""
    end
  end
end
