#Logica para la creación de proyectos

defmodule ProyectoFinal.Domain.Proyectos_Hackaton do
  alias ProyectoFinal.Services.Util, as: Funcional

  defstruct nombre: "", descripcion: "", categoria: "", estado: "", integrantes: [], avances: []

  # ============ FUNCIONES EXISTENTES (SIN CAMBIOS) ============

  def crear_Proyecto() do
    nombre = Funcional.input("Ingrese el nombre del equipo al cual se le asignara el proyecto: ", :string)
    descripcion = Funcional.input("Ingrese la descripcion del proyecto: ", :string)
    categoria = Funcional.input("Ingrese la categoria del proyecto: ", :string)
    estado = Funcional.input("Ingrese el estado del proyecto (En desarrollo/Finalizado): ", :string)
    crear(nombre, descripcion, categoria, estado, [], [])
  end

  def crear(nombre, descripcion, categoria, estado, integrantes, avances) do
    %__MODULE__{nombre: nombre, descripcion: descripcion, categoria: categoria, estado: estado, integrantes: integrantes, avances: avances}
  end

  def escribir_csv(lista_proyectos, nombre_archivo) do
    header = ["Nombre", "Descripción", "Categoría", "Estado", "Integrantes", "Avances"]
    rows = Enum.map(lista_proyectos, fn %__MODULE__{nombre: nombre, descripcion: descripcion, categoria: categoria, estado: estado, integrantes: integrantes, avances: avances} ->
      [nombre, descripcion, categoria, estado, Enum.join(integrantes, ";"), Enum.join(avances, ";")]
    end)
    Adapters.CSVAdapter.write(nombre_archivo, header, rows)
  end

  def leer_csv(nombre_archivo) do
    case Adapters.CSVAdapter.read(nombre_archivo) do
      {:ok, {_header, rows}} ->
        Enum.map(rows, fn
          [nombre, descripcion, categoria, estado, integrantes_str, avances_str] ->
            integrantes = if integrantes_str == "" or is_nil(integrantes_str), do: [], else: String.split(integrantes_str, ";") |> Enum.map(&String.trim/1)
            avances = if avances_str == "" or is_nil(avances_str), do: [], else: String.split(avances_str, ";") |> Enum.map(&String.trim/1)
            %__MODULE__{
              nombre: String.trim(nombre),
              descripcion: String.trim(descripcion),
              categoria: String.trim(categoria),
              estado: String.trim(estado),
              integrantes: integrantes,
              avances: avances
            }
          _ -> nil
        end)
        |> Enum.reject(&is_nil/1)
      {:error, _reason} ->
        IO.puts("Error al leer el archivo #{nombre_archivo}")
        []
    end
  end

  # ============ NUEVAS FUNCIONES AGREGADAS ============

  @doc """
  Agrega un avance al proyecto de un equipo específico.
  Retorna :ok si se actualiza correctamente, {:error, :not_found} si no existe el proyecto,
  o {:error, reason} si hay otro error.
  """
  def agregar_avance(nombre_equipo, texto_avance, csv_path \\ "priv/proyectos.csv") do
    proyectos = leer_csv(csv_path)

    case Enum.find_index(proyectos, fn p -> String.downcase(p.nombre) == String.downcase(nombre_equipo) end) do
      nil ->
        {:error, :not_found}

      index ->
        proyecto = Enum.at(proyectos, index)
        proyecto_actualizado = %{proyecto | avances: proyecto.avances ++ [texto_avance]}

        proyectos_actualizados = List.replace_at(proyectos, index, proyecto_actualizado)

        case escribir_csv(proyectos_actualizados, csv_path) do
          :ok -> :ok
          error -> error
        end
    end
  end

  @doc """
  Actualiza el estado de un proyecto (En desarrollo/Finalizado/etc).
  """
  def actualizar_estado(nombre_equipo, nuevo_estado, csv_path \\ "priv/proyectos.csv") do
    proyectos = leer_csv(csv_path)

    case Enum.find_index(proyectos, fn p -> String.downcase(p.nombre) == String.downcase(nombre_equipo) end) do
      nil ->
        {:error, :not_found}

      index ->
        proyecto = Enum.at(proyectos, index)
        proyecto_actualizado = %{proyecto | estado: nuevo_estado}

        proyectos_actualizados = List.replace_at(proyectos, index, proyecto_actualizado)

        case escribir_csv(proyectos_actualizados, csv_path) do
          :ok -> :ok
          error -> error
        end
    end
  end

  @doc """
  Lista proyectos filtrados por categoría.
  """
  def listar_por_categoria(categoria, csv_path \\ "priv/proyectos.csv") do
    leer_csv(csv_path)
    |> Enum.filter(fn p -> String.downcase(p.categoria) == String.downcase(categoria) end)
  end

  @doc """
  Lista proyectos filtrados por estado.
  """
  def listar_por_estado(estado, csv_path \\ "priv/proyectos.csv") do
    leer_csv(csv_path)
    |> Enum.filter(fn p -> String.downcase(p.estado) == String.downcase(estado) end)
  end

  @doc """
  Obtiene las consultas (avances que comienzan con "CONSULTA") de un proyecto.
  """
  def obtener_consultas(nombre_equipo, csv_path \\ "priv/proyectos.csv") do
    proyectos = leer_csv(csv_path)

    case Enum.find(proyectos, fn p -> String.downcase(p.nombre) == String.downcase(nombre_equipo) end) do
      nil -> []
      proyecto -> Enum.filter(proyecto.avances, fn av -> String.starts_with?(av, "CONSULTA") end)
    end
  end

  @doc """
  Obtiene las respuestas (avances que comienzan con "RESPUESTA") de un proyecto.
  """
  def obtener_respuestas(nombre_equipo, csv_path \\ "priv/proyectos.csv") do
    proyectos = leer_csv(csv_path)

    case Enum.find(proyectos, fn p -> String.downcase(p.nombre) == String.downcase(nombre_equipo) end) do
      nil -> []
      proyecto -> Enum.filter(proyecto.avances, fn av -> String.starts_with?(av, "RESPUESTA") end)
    end
  end

end
