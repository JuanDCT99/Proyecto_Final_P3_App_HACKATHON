#Logica para la creacion de personas

defmodule ProyectoFinal.Domain.Persona do
  alias ProyectoFinal.Services.Util, as: Funcional

  defstruct nombre: "", identificacion: "", edad: "", equipo: ""



  def crear_Usuario() do
    nombre = Funcional.input("Ingrese su nombre: ", :string)
    identificacion = Funcional.input("Ingrese su identificacion: ", :string)
    edad = Funcional.input("Ingrese su edad: ", :string)
    equipo = Funcional.input("Ingrese el nombre de su equipo: ", :string)
    crear(nombre, identificacion, edad, equipo)
  end

  def crear(nombre, identificacion, edad, equipo) do
    %__MODULE__{nombre: nombre, identificacion: identificacion, edad: edad, equipo: equipo}
  end

  def escribir_csv(lista_personas, nombre_archivo) do
    header = ["Nombre", "Identificacion", "Edad", "Equipo"]
    rows = Enum.map(lista_personas, fn %__MODULE__{nombre: nombre, identificacion: identificacion, edad: edad, equipo: equipo} ->
      [nombre, identificacion, edad, equipo]
    end)
    Adapters.CSVAdapter.write(nombre_archivo, header, rows)
  end

  def leer_csv(nombre_archivo) do
    case Adapters.CSVAdapter.read(nombre_archivo) do
      {:ok, {_header, rows}} ->
        Enum.map(rows, fn
          [nombre, identificacion, edad, equipo] ->
            %__MODULE__{
              nombre: String.trim(nombre),
              identificacion: String.trim(identificacion),
              edad: String.trim(edad),
              equipo: String.trim(equipo)
            }
          _ -> nil
        end)
        |> Enum.reject(&is_nil/1)
      {:error, _reason} ->
        IO.puts("Error al leer el archivo #{nombre_archivo}")
        []
    end
  end

  def asigar_persona_a_equipo(persona, nombre_equipo) do
    %{persona | equipo: nombre_equipo}
  end

end
