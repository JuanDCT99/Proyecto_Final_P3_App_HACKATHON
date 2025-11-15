#Logica de mentores

defmodule ProyectoFinal.Domain.Mentor do

  alias ProyectoFinal.Services.Util, as: Funcional
  @moduledoc """

  Define la estructura, la funcionalidad y la logica de un mentor
  """

  defstruct nombre: "", identificacion: "", especialidad: "", celular: "", edad: "", equipo: ""

  @doc """

  Crear una nueva estructura de mentor

  """
  def crear_mentor() do
    nombre = Funcional.input("Ingrese su nombre: ", :string)
    identificacion = Funcional.input("Ingrese su identificacion: ", :string)
    especialidad = Funcional.input("Ingrese su especialidad: ", :string)
    celular = Funcional.input("Ingrese su numero de celular: ", :string)
    edad = Funcional.input("Ingrese su edad: ", :string)
    equipo = Funcional.input("Ingrese el nombre de su equipo: ", :string)
    crear(nombre, identificacion, especialidad, celular, edad, equipo)
  end


  def crear(nombre, identificacion, especialidad, celular, edad, equipo) do
    %__MODULE__{nombre: nombre, identificacion: identificacion, especialidad: especialidad, celular: celular, edad: edad, equipo: equipo}
  end

  def escribir_csv(lista_mentores, nombre_archivo) do
    header = ["Nombre", "Identificacion", "Especialidad", "Celular", "Edad", "Equipo"]
    rows = Enum.map(lista_mentores, fn %__MODULE__{nombre: nombre, identificacion: identificacion, especialidad: especialidad, celular: celular, edad: edad, equipo: equipo} ->
      [nombre, identificacion, especialidad, celular, edad, equipo]
    end)
    Adapters.CSVAdapter.write(nombre_archivo, header, rows)
  end

  def leer_csv(nombre_archivo) do
    case Adapters.CSVAdapter.read(nombre_archivo) do
      {:ok, {_header, rows}} ->
        Enum.map(rows, fn
          [nombre, identificacion, especialidad, celular, edad, equipo] ->
            %__MODULE__{
              nombre: String.trim(nombre),
              identificacion: String.trim(identificacion),
              especialidad: String.trim(especialidad),
              celular: String.trim(celular),
              edad: String.trim(edad),
              equipo: String.trim(equipo)
            }
            _ -> nil
          end)
        |> Enum.reject(&is_nil/1)
      {:error, _reason} ->
        []
    end
  end

  def asigar_mentor_a_equipo(mentor, nombre_equipo) do
    %{mentor | equipo: nombre_equipo}
  end
end
