#Logica para la creacion de personas

defmodule ProyectoFinal.Domain.Persona do
  alias ProyectoFinal.Services.Util, as: Funcional

  defstruct nombre: "", identificacion: "", edad: "", equipo: "", tema: ""



  def crear_Usuario() do
    nombre = Funcional.input("Ingrese su nombre: ", :string)
    identificacion = Funcional.input("Ingrese su identificacion: ", :string)
    edad = Funcional.input("Ingrese su edad: ", :string)
    equipo = Funcional.input("Ingrese el nombre de su equipo: ", :string)
    tema = Funcional.input("Ingrese el tema de interes: ", :string)
    crear(nombre, identificacion, edad, equipo, tema)
  end

  def crear(nombre, identificacion, edad, equipo, tema) do
    %__MODULE__{nombre: nombre, identificacion: identificacion, edad: edad, equipo: equipo, tema: tema}
  end

  def escribir_csv(lista_personas, nombre_archivo) do
    header = ["Nombre", "Identificacion", "Edad", "Equipo", "Tema"]
    rows = Enum.map(lista_personas, fn %__MODULE__{nombre: nombre, identificacion: identificacion, edad: edad, equipo: equipo, tema: tema} ->
      [nombre, identificacion, edad, equipo, tema]
    end)
    Adapters.CSVAdapter.write(nombre_archivo, header, rows)
  end

  def leer_csv(nombre_archivo) do
    case Adapters.CSVAdapter.read(nombre_archivo) do
      {:ok, {_header, rows}} ->
        Enum.map(rows, fn
          [nombre, identificacion, edad, equipo, tema] ->
            %__MODULE__{
              nombre: String.trim(nombre),
              identificacion: String.trim(identificacion),
              edad: String.trim(edad),
              equipo: String.trim(equipo),
              tema: String.trim(tema)
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
