#Logica para la creación de proyectos

defmodule ProyectoFinal.Domain.Proyectos_Hackaton do
  alias ProyectoFinal.Services.Util, as: Funcional

  defstruct nombre: "", descripcion: "", categoria: "", estado: "", integrantes: [], avances: []

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
            integrantes = String.split(integrantes_str, ";") |> Enum.map(&String.trim/1)
            avances = String.split(avances_str, ";") |> Enum.map(&String.trim/1)
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

end
