#Logica para la creación de equipos
defmodule ProyectoFinal.Domain.Equipo do
  alias ProyectoFinal.Services.Util, as: Funcional

  defstruct nombre: "", groupID: "", integrantes: [], tema: ""


  def crearEquipo() do
    nombre = Funcional.input("Ingrese el nombre del equipo: ", :string)
    groupID = Funcional.input("Ingrese el ID del grupo: ", :string)
    tema = Funcional.input("Ingrese el tema/afinidad del equipo: ", :string)
    integrantes = []

    crear(nombre, groupID, integrantes, tema)
  end

  def crear(nombre, groupID, integrantes, tema \\ "") do
    %__MODULE__{nombre: nombre, groupID: groupID, integrantes: integrantes, tema: tema}
  end

  def escribir_csv(lista_equipos, nombre_archivo) do
    header = ["Nombre del Equipo", "Numero de Grupo", "Lista de Integrantes", "Tema"]
    rows = Enum.map(lista_equipos, fn %__MODULE__{nombre: nombre, groupID: groupID, integrantes: integrantes, tema: tema} ->
      [nombre, groupID, Enum.join(integrantes, ";"), tema]
    end)
    Adapters.CSVAdapter.write(nombre_archivo, header, rows)
  end

  def leer_csv(nombre_archivo) do
    case Adapters.CSVAdapter.read(nombre_archivo) do
      {:ok, {_header, rows}} ->
        Enum.map(rows, fn
          [nombre, groupID, integrantes, tema] ->
            %__MODULE__{
              nombre: String.trim(nombre),
              groupID: String.trim(groupID),
              integrantes: parsear_lista(integrantes),
              tema: String.trim(tema)
            }
          [nombre, groupID, integrantes] ->
            # Soporte para CSVs antiguos sin tema
            %__MODULE__{
              nombre: String.trim(nombre),
              groupID: String.trim(groupID),
              integrantes: parsear_lista(integrantes),
              tema: ""
            }
          _ -> nil
        end)
        |> Enum.reject(&is_nil/1)
      {:error, _reason} ->
        IO.puts("Error al leer el archivo #{nombre_archivo}")
        []
    end
  end

  def ingresar_integrante(equipo, persona) do
    if Enum.member?(equipo.integrantes, persona.nombre) do
      Funcional.mostrar_mensaje("El integrante ya está en el equipo.")
      equipo
    else
      nuevos_integrantes = [persona.nombre | equipo.integrantes]
      %{equipo | integrantes: nuevos_integrantes}
    end
  end

  @doc """
  Agrupa personas por tema/afinidad y crea equipos automáticamente.

  """
  def crear_equipos_por_afinidad(personas, obtener_tema_fn, max_integrantes \\ 5, prefijo_nombre \\ "Equipo") do
    personas
    |> Enum.group_by(obtener_tema_fn)
    |> Enum.flat_map(fn {tema, personas_del_tema} ->
      personas_del_tema
      |> Enum.chunk_every(max_integrantes)
      |> Enum.with_index(1)
      |> Enum.map(fn {grupo, indice} ->
        nombre = "#{prefijo_nombre} #{tema} #{indice}"
        groupID = generar_group_id(tema, indice)
        integrantes = Enum.map(grupo, fn p -> p.nombre end)

        crear(nombre, groupID, integrantes, tema)
      end)
    end)
  end

  @doc """
  Sugiere equipos balanceados basándose en temas/afinidades de las personas.
  Intenta crear equipos de tamaño similar con diversidad de temas.
  """
  def sugerir_equipos_balanceados(personas, obtener_tema_fn, num_equipos, prefijo_nombre \\ "Equipo") do
    # Agrupar por tema
    por_tema = Enum.group_by(personas, obtener_tema_fn)

    # Crear equipos vacíos
    equipos_vacios =
      1..num_equipos
      |> Enum.map(fn i ->
        %{
          nombre: "#{prefijo_nombre} #{i}",
          groupID: "G#{String.pad_leading(Integer.to_string(i), 3, "0")}",
          integrantes: [],
          temas: []
        }
      end)

    # Distribuir personas de manera balanceada
    equipos_llenos =
      por_tema
      |> Enum.reduce(equipos_vacios, fn {tema, personas_tema}, equipos_acc ->
        personas_tema
        |> Enum.with_index()
        |> Enum.reduce(equipos_acc, fn {persona, idx}, equipos ->
          # Asignar a equipo de forma round-robin
          equipo_idx = rem(idx, num_equipos)

          List.update_at(equipos, equipo_idx, fn equipo ->
            %{equipo |
              integrantes: [persona.nombre | equipo.integrantes],
              temas: if(tema in equipo.temas, do: equipo.temas, else: [tema | equipo.temas])
            }
          end)
        end)
      end)

    # Convertir a estructuras Equipo
    Enum.map(equipos_llenos, fn eq ->
      tema_principal = Enum.join(eq.temas, ", ")
      crear(eq.nombre, eq.groupID, Enum.reverse(eq.integrantes), tema_principal)
    end)
  end

  @doc """
  Filtra equipos por tema/afinidad.
  """
  def filtrar_por_tema(equipos, tema) do
    Enum.filter(equipos, fn equipo ->
      String.downcase(equipo.tema) == String.downcase(tema)
    end)
  end

  @doc """
  Lista todos los temas únicos de una lista de equipos.
  """
  def listar_temas(equipos) do
    equipos
    |> Enum.map(& &1.tema)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Cuenta equipos por tema.
  """
  def contar_por_tema(equipos) do
    equipos
    |> Enum.group_by(& &1.tema)
    |> Enum.map(fn {tema, equipos_tema} ->
      {tema, length(equipos_tema)}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Encuentra el equipo más adecuado para una persona basándose en su tema.
  Retorna el equipo con el mismo tema que tenga menos integrantes.
  """
  def encontrar_equipo_compatible(equipos, persona_tema, max_integrantes \\ 5) do
    equipos
    |> Enum.filter(fn eq ->
      String.downcase(eq.tema) == String.downcase(persona_tema) and
      length(eq.integrantes) < max_integrantes
    end)
    |> Enum.min_by(&length(&1.integrantes), fn -> nil end)
  end

  # Función auxiliar privada para parsear listas desde strings
  defp parsear_lista(string) do
    string
    |> String.trim()
    |> case do
      "" -> []
      str -> String.split(str, ";") |> Enum.map(&String.trim/1)
    end
  end

  # Función auxiliar para generar IDs de grupo
  defp generar_group_id(tema, indice) do
    # Tomar las primeras 3 letras del tema y agregar el índice
    prefijo =
      tema
      |> String.upcase()
      |> String.replace(~r/[^A-Z]/, "")
      |> String.slice(0..2)
      |> String.pad_trailing(3, "X")

    "#{prefijo}#{String.pad_leading(Integer.to_string(indice), 3, "0")}"
  end
end
