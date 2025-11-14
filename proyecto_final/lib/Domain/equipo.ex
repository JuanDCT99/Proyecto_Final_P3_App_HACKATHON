#Logica para la creación de equipos

defmodule ProyectoFinal.Domain.Equipo do
  alias ProyectoFinal.Services.Util, as: Funcional

  defstruct nombre: "", groupID: "", integrantes: []


  def crearEquipo() do
    nombre = Funcional.input("Ingrese el nombre del equipo: ", :string)
    groupID = Funcional.input("Ingrese el ID del grupo: ", :string)
    integrantes = []

    crear(nombre, groupID, integrantes)

  end

  def crear(nombre, groupID, integrantes) do
    %__MODULE__{nombre: nombre, groupID: groupID, integrantes: integrantes}
  end

  def escribir_csv(lista_equipos, nombre_archivo) do
    header = ["Nombre del Equipo", "Numero de Grupo", "Lista de Integrantes"]
    rows = Enum.map(lista_equipos, fn %__MODULE__{nombre: nombre, groupID: groupID, integrantes: integrantes} ->
      [nombre, groupID, Enum.join(integrantes, ";")]
    end)
    Adapters.CSVAdapter.write(nombre_archivo, header, rows)
  end

  def leer_csv(nombre_archivo) do
    case Adapters.CSVAdapter.read(nombre_archivo) do
      {:ok, {_header, rows}} ->
        Enum.map(rows, fn
          [nombre, groupID, integrantes] ->
            integrantes_lista = String.split(integrantes, ";") |> Enum.map(&String.trim/1)
            %__MODULE__{nombre: String.trim(nombre), groupID: String.trim(groupID), integrantes: integrantes_lista}
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


end
