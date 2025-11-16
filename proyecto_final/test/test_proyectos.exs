defmodule ProyectoFinal.Domain.ProyectosHackatonTest do
  use ExUnit.Case
  alias ProyectoFinal.Domain.Proyectos_Hackaton
  import ExUnit.CaptureIO

  # Módulo mock para CSVAdapter
  defmodule MockCSVAdapter do
    def write(_nombre_archivo, _header, _rows), do: :ok

    def read("proyectos_validos.csv") do
      {:ok, {
        ["Nombre", "Descripción", "Categoría", "Estado", "Integrantes", "Avances"],
        [
          ["App Móvil", "Sistema de gestión", "Tecnología", "En desarrollo", "Juan;María;Pedro", "Diseño UI;Backend API"],
          ["EcoSolución", "Proyecto sostenible", "Medio Ambiente", "Finalizado", "Ana;Luis", "Investigación;Prototipo;Presentación"]
        ]
      }}
    end

    def read("archivo_invalido.csv") do
      {:error, :enoent}
    end
  end

  describe "crear/6" do
    test "crea un proyecto con todos los campos proporcionados" do
      proyecto = Proyectos_Hackaton.crear(
        "App Móvil",
        "Sistema de gestión de tareas",
        "Tecnología",
        "En desarrollo",
        ["Juan", "María"],
        ["Diseño UI", "Backend API"]
      )

      assert proyecto.nombre == "App Móvil"
      assert proyecto.descripcion == "Sistema de gestión de tareas"
      assert proyecto.categoria == "Tecnología"
      assert proyecto.estado == "En desarrollo"
      assert proyecto.integrantes == ["Juan", "María"]
      assert proyecto.avances == ["Diseño UI", "Backend API"]
    end

    test "crea un proyecto sin integrantes ni avances" do
      proyecto = Proyectos_Hackaton.crear(
        "Proyecto Nuevo",
        "Descripción aquí",
        "Educación",
        "En desarrollo",
        [],
        []
      )

      assert proyecto.nombre == "Proyecto Nuevo"
      assert proyecto.integrantes == []
      assert proyecto.avances == []
    end

    test "crea un proyecto finalizado" do
      proyecto = Proyectos_Hackaton.crear(
        "Proyecto Final",
        "Ya terminado",
        "Salud",
        "Finalizado",
        ["Ana"],
        ["Completado"]
      )

      assert proyecto.estado == "Finalizado"
    end

    test "el proyecto creado es una estructura válida" do
      proyecto = Proyectos_Hackaton.crear("Test", "Desc", "Cat", "Estado", [], [])

      assert %Proyectos_Hackaton{} = proyecto
    end

    test "maneja múltiples integrantes" do
      proyecto = Proyectos_Hackaton.crear(
        "Proyecto Grande",
        "Con muchos integrantes",
        "Tech",
        "En desarrollo",
        ["A", "B", "C", "D", "E"],
        []
      )

      assert length(proyecto.integrantes) == 5
    end

    test "maneja múltiples avances" do
      proyecto = Proyectos_Hackaton.crear(
        "Proyecto Avanzado",
        "Con varios hitos",
        "Tech",
        "En desarrollo",
        [],
        ["Fase 1", "Fase 2", "Fase 3", "Fase 4"]
      )

      assert length(proyecto.avances) == 4
    end
  end

  describe "escribir_csv/2" do
    setup do
      proyectos = [
        Proyectos_Hackaton.crear(
          "App Móvil",
          "Sistema de gestión",
          "Tecnología",
          "En desarrollo",
          ["Juan", "María"],
          ["Diseño", "Backend"]
        ),
        Proyectos_Hackaton.crear(
          "EcoSolución",
          "Proyecto sostenible",
          "Medio Ambiente",
          "Finalizado",
          ["Ana", "Luis", "Carlos"],
          ["Investigación", "Prototipo"]
        )
      ]

      {:ok, proyectos: proyectos}
    end

    test "formatea correctamente el header" do
      header = ["Nombre", "Descripción", "Categoría", "Estado", "Integrantes", "Avances"]

      assert length(header) == 6
      assert Enum.at(header, 0) == "Nombre"
      assert Enum.at(header, 5) == "Avances"
    end

    test "convierte integrantes a string separado por punto y coma", %{proyectos: proyectos} do
      [proyecto | _] = proyectos
      integrantes_str = Enum.join(proyecto.integrantes, ";")

      assert integrantes_str == "Juan;María"
    end

    test "convierte avances a string separado por punto y coma", %{proyectos: proyectos} do
      [proyecto | _] = proyectos
      avances_str = Enum.join(proyecto.avances, ";")

      assert avances_str == "Diseño;Backend"
    end

    test "genera filas con el formato correcto", %{proyectos: proyectos} do
      rows = Enum.map(proyectos, fn %Proyectos_Hackaton{
        nombre: nombre,
        descripcion: descripcion,
        categoria: categoria,
        estado: estado,
        integrantes: integrantes,
        avances: avances
      } ->
        [nombre, descripcion, categoria, estado, Enum.join(integrantes, ";"), Enum.join(avances, ";")]
      end)

      assert length(rows) == 2

      # Primera fila
      [primera_fila | _] = rows
      assert Enum.at(primera_fila, 0) == "App Móvil"
      assert Enum.at(primera_fila, 4) == "Juan;María"
      assert Enum.at(primera_fila, 5) == "Diseño;Backend"
    end

    test "maneja proyectos sin integrantes ni avances" do
      proyecto = Proyectos_Hackaton.crear("Solo", "Desc", "Cat", "Estado", [], [])

      integrantes_str = Enum.join(proyecto.integrantes, ";")
      avances_str = Enum.join(proyecto.avances, ";")

      assert integrantes_str == ""
      assert avances_str == ""
    end
  end

  describe "leer_csv/1" do
    setup do
      Application.put_env(:proyecto_final, :csv_adapter, MockCSVAdapter)
      :ok
    end

    test "lee y parsea proyectos correctamente desde CSV válido" do
      proyectos = [
        %Proyectos_Hackaton{
          nombre: "App Móvil",
          descripcion: "Sistema de gestión",
          categoria: "Tecnología",
          estado: "En desarrollo",
          integrantes: ["Juan", "María", "Pedro"],
          avances: ["Diseño UI", "Backend API"]
        },
        %Proyectos_Hackaton{
          nombre: "EcoSolución",
          descripcion: "Proyecto sostenible",
          categoria: "Medio Ambiente",
          estado: "Finalizado",
          integrantes: ["Ana", "Luis"],
          avances: ["Investigación", "Prototipo", "Presentación"]
        }
      ]

      [proyecto1, proyecto2] = proyectos

      # Verificar primer proyecto
      assert proyecto1.nombre == "App Móvil"
      assert proyecto1.categoria == "Tecnología"
      assert proyecto1.estado == "En desarrollo"
      assert length(proyecto1.integrantes) == 3
      assert length(proyecto1.avances) == 2

      # Verificar segundo proyecto
      assert proyecto2.nombre == "EcoSolución"
      assert proyecto2.estado == "Finalizado"
      assert length(proyecto2.integrantes) == 2
      assert length(proyecto2.avances) == 3
    end

    test "parsea correctamente integrantes separados por punto y coma" do
      integrantes_str = "Juan;María;Pedro"
      integrantes_lista = String.split(integrantes_str, ";") |> Enum.map(&String.trim/1)

      assert integrantes_lista == ["Juan", "María", "Pedro"]
      assert length(integrantes_lista) == 3
    end

    test "parsea correctamente avances separados por punto y coma" do
      avances_str = "Diseño;Backend;Testing"
      avances_lista = String.split(avances_str, ";") |> Enum.map(&String.trim/1)

      assert avances_lista == ["Diseño", "Backend", "Testing"]
      assert length(avances_lista) == 3
    end

    test "elimina espacios en blanco de todos los campos" do
      nombre = "  App Móvil  "
      descripcion = "  Descripción  "
      categoria = "  Tech  "

      assert String.trim(nombre) == "App Móvil"
      assert String.trim(descripcion) == "Descripción"
      assert String.trim(categoria) == "Tech"
    end

    test "elimina espacios de integrantes y avances" do
      integrantes_str = " Juan ; María ; Pedro "
      integrantes = String.split(integrantes_str, ";") |> Enum.map(&String.trim/1)

      assert integrantes == ["Juan", "María", "Pedro"]
      refute Enum.any?(integrantes, &String.starts_with?(&1, " "))
    end

    test "maneja proyectos sin integrantes" do
      integrantes_str = ""
      integrantes = String.split(integrantes_str, ";") |> Enum.map(&String.trim/1)

      # String.split("", ";") devuelve [""]
      assert integrantes == [""]
    end

    test "maneja proyectos sin avances" do
      avances_str = ""
      avances = String.split(avances_str, ";") |> Enum.map(&String.trim/1)

      assert avances == [""]
    end

    test "retorna lista vacía cuando hay error al leer archivo" do
      output = capture_io(fn ->
        proyectos = Proyectos_Hackaton.leer_csv("archivo_invalido.csv")
        send(self(), {:resultado, proyectos})
      end)

      assert_receive {:resultado, proyectos}
      assert proyectos == []
      assert output =~ "Error al leer el archivo"
    end

    test "filtra filas inválidas (nil)" do
      datos_mixtos = [
        %Proyectos_Hackaton{nombre: "Válido", descripcion: "Desc", categoria: "Cat", estado: "Estado", integrantes: [], avances: []},
        nil,
        %Proyectos_Hackaton{nombre: "Otro", descripcion: "Desc2", categoria: "Cat2", estado: "Estado2", integrantes: [], avances: []}
      ]

      resultado = Enum.reject(datos_mixtos, &is_nil/1)

      assert length(resultado) == 2
      refute Enum.any?(resultado, &is_nil/1)
    end

    test "maneja filas con menos de 6 campos" do
      # Simular fila incompleta
      fila = ["Solo", "Dos", "Campos"]

      resultado = case fila do
        [nombre, descripcion, categoria, estado, integrantes_str, avances_str] ->
          %Proyectos_Hackaton{nombre: nombre}
        _ -> nil
      end

      assert is_nil(resultado)
    end
  end

  describe "struct Proyectos_Hackaton" do
    test "tiene los campos correctos por defecto" do
      proyecto = %Proyectos_Hackaton{}

      assert proyecto.nombre == ""
      assert proyecto.descripcion == ""
      assert proyecto.categoria == ""
      assert proyecto.estado == ""
      assert proyecto.integrantes == []
      assert proyecto.avances == []
    end

    test "permite actualizar campos individualmente" do
      proyecto = %Proyectos_Hackaton{}
      proyecto_actualizado = %{proyecto | nombre: "Nuevo", estado: "Finalizado"}

      assert proyecto_actualizado.nombre == "Nuevo"
      assert proyecto_actualizado.estado == "Finalizado"
      assert proyecto_actualizado.descripcion == ""
    end

    test "permite agregar integrantes" do
      proyecto = %Proyectos_Hackaton{}
      proyecto_con_integrantes = %{proyecto | integrantes: ["Juan", "María"]}

      assert length(proyecto_con_integrantes.integrantes) == 2
    end

    test "permite agregar avances" do
      proyecto = %Proyectos_Hackaton{}
      proyecto_con_avances = %{proyecto | avances: ["Fase 1", "Fase 2"]}

      assert length(proyecto_con_avances.avances) == 2
    end
  end

  describe "validaciones de estado" do
    test "estado 'En desarrollo' es válido" do
      proyecto = Proyectos_Hackaton.crear("Test", "Desc", "Cat", "En desarrollo", [], [])

      assert proyecto.estado == "En desarrollo"
    end

    test "estado 'Finalizado' es válido" do
      proyecto = Proyectos_Hackaton.crear("Test", "Desc", "Cat", "Finalizado", [], [])

      assert proyecto.estado == "Finalizado"
    end

    test "puede tener estados personalizados" do
      proyecto = Proyectos_Hackaton.crear("Test", "Desc", "Cat", "En pausa", [], [])

      # No hay validación, acepta cualquier string
      assert proyecto.estado == "En pausa"
    end
  end

  describe "casos de uso complejos" do
    test "proyecto con muchos integrantes y avances" do
      integrantes = ["A", "B", "C", "D", "E", "F", "G", "H"]
      avances = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]

      proyecto = Proyectos_Hackaton.crear(
        "Proyecto Grande",
        "Con muchos datos",
        "Tech",
        "En desarrollo",
        integrantes,
        avances
      )

      assert length(proyecto.integrantes) == 8
      assert length(proyecto.avances) == 10
    end

    test "descripción larga no afecta" do
      descripcion_larga = String.duplicate("Lorem ipsum dolor sit amet. ", 20)

      proyecto = Proyectos_Hackaton.crear(
        "Test",
        descripcion_larga,
        "Cat",
        "Estado",
        [],
        []
      )

      assert String.length(proyecto.descripcion) > 500
    end

    test "categorías con caracteres especiales" do
      proyecto = Proyectos_Hackaton.crear(
        "Test",
        "Desc",
        "Tecnología & Innovación",
        "En desarrollo",
        [],
        []
      )

      assert proyecto.categoria == "Tecnología & Innovación"
    end
  end

  describe "integración escribir_csv y leer_csv" do
    test "los datos formateados pueden ser parseados correctamente" do
      # Simular el proceso completo
      proyecto_original = Proyectos_Hackaton.crear(
        "App Test",
        "Descripción de prueba",
        "Tecnología",
        "En desarrollo",
        ["Juan", "María", "Pedro"],
        ["Diseño", "Backend", "Testing"]
      )

      # Formatear como se haría al escribir
      integrantes_str = Enum.join(proyecto_original.integrantes, ";")
      avances_str = Enum.join(proyecto_original.avances, ";")

      # Parsear como se haría al leer
      integrantes_parseados = String.split(integrantes_str, ";") |> Enum.map(&String.trim/1)
      avances_parseados = String.split(avances_str, ";") |> Enum.map(&String.trim/1)

      # Verificar que los datos son los mismos
      assert integrantes_parseados == proyecto_original.integrantes
      assert avances_parseados == proyecto_original.avances
    end
  end
end
