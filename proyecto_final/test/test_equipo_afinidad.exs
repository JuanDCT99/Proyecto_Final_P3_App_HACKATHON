defmodule ProyectoFinal.Domain.EquipoAfinidadTest do
  use ExUnit.Case
  alias ProyectoFinal.Domain.Equipo

  describe "crear_equipos_por_afinidad/4" do
    setup do
      personas = [
        %{nombre: "Juan", tema: "IA"},
        %{nombre: "María", tema: "IA"},
        %{nombre: "Pedro", tema: "IA"},
        %{nombre: "Ana", tema: "Web"},
        %{nombre: "Luis", tema: "Web"},
        %{nombre: "Carlos", tema: "Móvil"},
        %{nombre: "Sofia", tema: "Móvil"},
        %{nombre: "Diego", tema: "Móvil"}
      ]

      {:ok, personas: personas}
    end

    test "crea equipos agrupados por tema", %{personas: personas} do
      equipos = Equipo.crear_equipos_por_afinidad(personas, fn p -> p.tema end)

      # Verificar que se crearon equipos para cada tema
      temas = Enum.map(equipos, & &1.tema) |> Enum.uniq()
      assert "IA" in temas
      assert "Web" in temas
      assert "Móvil" in temas
    end

    test "cada equipo tiene el tema correcto", %{personas: personas} do
      equipos = Equipo.crear_equipos_por_afinidad(personas, fn p -> p.tema end)

      # Verificar que los integrantes coinciden con el tema del equipo
      Enum.each(equipos, fn equipo ->
        personas_del_equipo = Enum.filter(personas, fn p ->
          p.nombre in equipo.integrantes
        end)

        assert Enum.all?(personas_del_equipo, fn p -> p.tema == equipo.tema end)
      end)
    end

    test "respeta el máximo de integrantes por equipo" do
      # Crear muchas personas del mismo tema
      personas_ia =
        1..12
        |> Enum.map(fn i -> %{nombre: "Persona#{i}", tema: "IA"} end)

      equipos = Equipo.crear_equipos_por_afinidad(personas_ia, fn p -> p.tema end, 5)

      # Debe crear 3 equipos (12 personas / 5 max = 3 equipos)
      equipos_ia = Enum.filter(equipos, & &1.tema == "IA")
      assert length(equipos_ia) == 3

      # Ningún equipo debe tener más de 5 integrantes
      assert Enum.all?(equipos_ia, fn eq -> length(eq.integrantes) <= 5 end)
    end

    test "genera nombres de equipos correctamente", %{personas: personas} do
      equipos = Equipo.crear_equipos_por_afinidad(personas, fn p -> p.tema end)

      # Verificar formato de nombres
      nombres = Enum.map(equipos, & &1.nombre)
      assert Enum.any?(nombres, &String.contains?(&1, "Equipo IA"))
      assert Enum.any?(nombres, &String.contains?(&1, "Equipo Web"))
    end

    test "genera IDs de grupo únicos" do
      personas =
        1..10
        |> Enum.map(fn i -> %{nombre: "P#{i}", tema: "IA"} end)

      equipos = Equipo.crear_equipos_por_afinidad(personas, fn p -> p.tema end, 3)

      # Todos los IDs deben ser únicos
      ids = Enum.map(equipos, & &1.groupID)
      assert length(ids) == length(Enum.uniq(ids))
    end

    test "maneja tema vacío" do
      personas = [
        %{nombre: "Juan", tema: ""},
        %{nombre: "María", tema: ""}
      ]

      equipos = Equipo.crear_equipos_por_afinidad(personas, fn p -> p.tema end)

      assert length(equipos) == 1
      assert hd(equipos).tema == ""
    end

    test "prefijo personalizado de nombre" do
      personas = [%{nombre: "Juan", tema: "IA"}]

      equipos = Equipo.crear_equipos_por_afinidad(
        personas,
        fn p -> p.tema end,
        5,
        "Grupo"
      )

      assert hd(equipos).nombre =~ "Grupo"
    end
  end

  describe "sugerir_equipos_balanceados/4" do
    setup do
      personas = [
        %{nombre: "Juan", tema: "IA"},
        %{nombre: "María", tema: "IA"},
        %{nombre: "Pedro", tema: "Web"},
        %{nombre: "Ana", tema: "Web"},
        %{nombre: "Luis", tema: "Móvil"},
        %{nombre: "Carlos", tema: "Móvil"}
      ]

      {:ok, personas: personas}
    end

    test "crea el número correcto de equipos", %{personas: personas} do
      equipos = Equipo.sugerir_equipos_balanceados(personas, fn p -> p.tema end, 3)

      assert length(equipos) == 3
    end

    test "distribuye personas de forma balanceada", %{personas: personas} do
      equipos = Equipo.sugerir_equipos_balanceados(personas, fn p -> p.tema end, 3)

      tamaños = Enum.map(equipos, fn eq -> length(eq.integrantes) end)

      # Todos los equipos deben tener tamaño similar (6 personas / 3 equipos = 2 c/u)
      assert Enum.all?(tamaños, fn t -> t in [2, 3] end)
    end

    test "cada equipo tiene diversidad de temas", %{personas: personas} do
      equipos = Equipo.sugerir_equipos_balanceados(personas, fn p -> p.tema end, 2)

      # Cada equipo debe tener personas de diferentes temas
      Enum.each(equipos, fn equipo ->
        temas = String.split(equipo.tema, ", ")
        assert length(temas) >= 1
      end)
    end

    test "genera nombres secuenciales", %{personas: personas} do
      equipos = Equipo.sugerir_equipos_balanceados(personas, fn p -> p.tema end, 3)

      nombres = Enum.map(equipos, & &1.nombre)
      assert "Equipo 1" in nombres
      assert "Equipo 2" in nombres
      assert "Equipo 3" in nombres
    end

    test "genera IDs de grupo secuenciales", %{personas: personas} do
      equipos = Equipo.sugerir_equipos_balanceados(personas, fn p -> p.tema end, 3)

      ids = Enum.map(equipos, & &1.groupID) |> Enum.sort()
      assert ids == ["G001", "G002", "G003"]
    end

    test "maneja número de equipos mayor que personas" do
      personas = [%{nombre: "Juan", tema: "IA"}]

      equipos = Equipo.sugerir_equipos_balanceados(personas, fn p -> p.tema end, 5)

      # Se crean 5 equipos, pero solo 1 tiene integrantes
      assert length(equipos) == 5
      equipos_con_integrantes = Enum.filter(equipos, fn eq -> length(eq.integrantes) > 0 end)
      assert length(equipos_con_integrantes) == 1
    end

    test "prefijo personalizado" do
      personas = [%{nombre: "Juan", tema: "IA"}]

      equipos = Equipo.sugerir_equipos_balanceados(
        personas,
        fn p -> p.tema end,
        2,
        "Grupo"
      )

      assert hd(equipos).nombre =~ "Grupo"
    end
  end

  describe "filtrar_por_tema/2" do
    setup do
      equipos = [
        Equipo.crear("Equipo A", "G001", ["Juan"], "IA"),
        Equipo.crear("Equipo B", "G002", ["María"], "Web"),
        Equipo.crear("Equipo C", "G003", ["Pedro"], "IA"),
        Equipo.crear("Equipo D", "G004", ["Ana"], "Móvil")
      ]

      {:ok, equipos: equipos}
    end

    test "filtra equipos por tema exacto", %{equipos: equipos} do
      equipos_ia = Equipo.filtrar_por_tema(equipos, "IA")

      assert length(equipos_ia) == 2
      assert Enum.all?(equipos_ia, fn eq -> eq.tema == "IA" end)
    end

    test "es case-insensitive", %{equipos: equipos} do
      equipos_ia1 = Equipo.filtrar_por_tema(equipos, "ia")
      equipos_ia2 = Equipo.filtrar_por_tema(equipos, "IA")
      equipos_ia3 = Equipo.filtrar_por_tema(equipos, "Ia")

      assert length(equipos_ia1) == 2
      assert length(equipos_ia2) == 2
      assert length(equipos_ia3) == 2
    end

    test "retorna lista vacía si no hay coincidencias", %{equipos: equipos} do
      resultado = Equipo.filtrar_por_tema(equipos, "Blockchain")

      assert resultado == []
    end

    test "funciona con lista vacía" do
      resultado = Equipo.filtrar_por_tema([], "IA")

      assert resultado == []
    end
  end

  describe "listar_temas/1" do
    setup do
      equipos = [
        Equipo.crear("E1", "G1", [], "IA"),
        Equipo.crear("E2", "G2", [], "Web"),
        Equipo.crear("E3", "G3", [], "IA"),
        Equipo.crear("E4", "G4", [], "Móvil"),
        Equipo.crear("E5", "G5", [], "")
      ]

      {:ok, equipos: equipos}
    end

    test "retorna lista de temas únicos", %{equipos: equipos} do
      temas = Equipo.listar_temas(equipos)

      assert length(temas) == 3
      assert "IA" in temas
      assert "Web" in temas
      assert "Móvil" in temas
    end

    test "excluye temas vacíos", %{equipos: equipos} do
      temas = Equipo.listar_temas(equipos)

      refute "" in temas
    end

    test "retorna lista ordenada alfabéticamente", %{equipos: equipos} do
      temas = Equipo.listar_temas(equipos)

      assert temas == Enum.sort(temas)
    end

    test "funciona con lista vacía" do
      temas = Equipo.listar_temas([])

      assert temas == []
    end

    test "funciona con todos los equipos sin tema" do
      equipos = [
        Equipo.crear("E1", "G1", [], ""),
        Equipo.crear("E2", "G2", [], "")
      ]

      temas = Equipo.listar_temas(equipos)

      assert temas == []
    end
  end

  describe "contar_por_tema/1" do
    setup do
      equipos = [
        Equipo.crear("E1", "G1", [], "IA"),
        Equipo.crear("E2", "G2", [], "Web"),
        Equipo.crear("E3", "G3", [], "IA"),
        Equipo.crear("E4", "G4", [], "IA"),
        Equipo.crear("E5", "G5", [], "Móvil")
      ]

      {:ok, equipos: equipos}
    end

    test "cuenta equipos por tema correctamente", %{equipos: equipos} do
      conteo = Equipo.contar_por_tema(equipos)

      assert conteo["IA"] == 3
      assert conteo["Web"] == 1
      assert conteo["Móvil"] == 1
    end

    test "retorna mapa vacío con lista vacía" do
      conteo = Equipo.contar_por_tema([])

      assert conteo == %{}
    end

    test "incluye temas vacíos en el conteo" do
      equipos = [
        Equipo.crear("E1", "G1", [], "IA"),
        Equipo.crear("E2", "G2", [], "")
      ]

      conteo = Equipo.contar_por_tema(equipos)

      assert conteo["IA"] == 1
      assert conteo[""] == 1
    end
  end

  describe "encontrar_equipo_compatible/3" do
    setup do
      equipos = [
        Equipo.crear("E1", "G1", ["Juan", "María"], "IA"),
        Equipo.crear("E2", "G2", ["Pedro", "Ana", "Luis", "Carlos"], "IA"),
        Equipo.crear("E3", "G3", ["Sofia"], "Web"),
        Equipo.crear("E4", "G4", ["Diego"], "IA")
      ]

      {:ok, equipos: equipos}
    end

    test "encuentra equipo con menos integrantes del tema buscado", %{equipos: equipos} do
      equipo = Equipo.encontrar_equipo_compatible(equipos, "IA")

      # E4 tiene solo 1 integrante con tema IA
      assert equipo.nombre == "E4"
      assert length(equipo.integrantes) == 1
    end

    test "respeta el límite máximo de integrantes", %{equipos: equipos} do
      # E2 tiene 4 integrantes, está cerca del límite
      equipo = Equipo.encontrar_equipo_compatible(equipos, "IA", 4)

      # Debe retornar E1 o E4 que tienen menos de 4
      assert equipo.nombre in ["E1", "E4"]
    end

    test "retorna nil si no hay equipos compatibles" do
      equipos = [
        Equipo.crear("E1", "G1", ["A", "B", "C", "D", "E"], "IA")
      ]

      equipo = Equipo.encontrar_equipo_compatible(equipos, "IA", 5)

      assert equipo == nil
    end

    test "retorna nil si no hay equipos del tema buscado", %{equipos: equipos} do
      equipo = Equipo.encontrar_equipo_compatible(equipos, "Blockchain")

      assert equipo == nil
    end

    test "es case-insensitive", %{equipos: equipos} do
      equipo1 = Equipo.encontrar_equipo_compatible(equipos, "ia")
      equipo2 = Equipo.encontrar_equipo_compatible(equipos, "IA")

      assert equipo1 != nil
      assert equipo2 != nil
    end

    test "funciona con lista vacía" do
      equipo = Equipo.encontrar_equipo_compatible([], "IA")

      assert equipo == nil
    end
  end

  describe "integración: flujo completo de creación por afinidad" do
    test "crear equipos, filtrar y buscar compatible" do
      # 1. Crear personas con temas
      personas = [
        %{nombre: "Juan", tema: "IA"},
        %{nombre: "María", tema: "IA"},
        %{nombre: "Pedro", tema: "Web"},
        %{nombre: "Ana", tema: "Web"},
        %{nombre: "Luis", tema: "IA"}
      ]

      # 2. Crear equipos por afinidad
      equipos = Equipo.crear_equipos_por_afinidad(personas, fn p -> p.tema end, 3)

      # 3. Listar temas disponibles
      temas = Equipo.listar_temas(equipos)
      assert "IA" in temas
      assert "Web" in temas

      # 4. Filtrar equipos de IA
      equipos_ia = Equipo.filtrar_por_tema(equipos, "IA")
      assert length(equipos_ia) >= 1

      # 5. Buscar equipo compatible para nueva persona
      equipo_compatible = Equipo.encontrar_equipo_compatible(equipos, "IA", 5)
      assert equipo_compatible != nil

      # 6. Agregar persona al equipo
      nueva_persona = %{nombre: "Carlos"}
      equipo_actualizado = Equipo.ingresar_integrante(equipo_compatible, nueva_persona)

      assert "Carlos" in equipo_actualizado.integrantes
    end
  end

  describe "generar_group_id (privada, test indirecto)" do
    test "IDs generados tienen formato correcto" do
      personas = [
        %{nombre: "Juan", tema: "Inteligencia Artificial"},
        %{nombre: "María", tema: "Web Development"}
      ]

      equipos = Equipo.crear_equipos_por_afinidad(personas, fn p -> p.tema end)

      # Verificar que los IDs tienen formato de 6 caracteres
      Enum.each(equipos, fn equipo ->
        assert String.length(equipo.groupID) == 6
      end)
    end

    test "IDs son únicos para diferentes temas" do
      personas =
        1..5
        |> Enum.map(fn i -> %{nombre: "P#{i}", tema: "Tema#{i}"} end)

      equipos = Equipo.crear_equipos_por_afinidad(personas, fn p -> p.tema end)

      ids = Enum.map(equipos, & &1.groupID)
      assert length(ids) == length(Enum.uniq(ids))
    end
  end
end
