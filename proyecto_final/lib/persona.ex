#Logica para la creacion de personas

defmodule Persona do

  defstruct nombre: "", identificacion: "", edad: "", equipo: ""


  def crear_Usuario() do
    nombre = Funcional.input("Ingrese su nombre: ", :string)
    identificacion = Funcional.input("Ingrese su identificacion: ", :string)
    edad = Funcional.input("Ingrese su edad: ", :string)
    equipo = Funcional.input("Ingrese el nombre de su equipo: ", :string)
    crear(nombre, identificacion, edad, equipo)
  end

  def crear(nombre, identificacion, edad, equipo) do
    %Persona{nombre: nombre, identificacion: identificacion, edad: edad, equipo: equipo}
  end

  def escribir_csv(lista_personas, nombre_archivo) do
    encabezado = "Nombre, Identificacion, Edad, Equipo\n"
    contenido =
      Enum.map(lista_personas,
        fn %Persona{nombre: nombre, identificacion: identificacion, edad: edad, equipo: equipo} ->
          "#{nombre},#{identificacion},#{edad},#{equipo}\n"
      end)
      |> Enum.join("")
    File.write!(nombre_archivo, encabezado <> contenido)
  end

  def leer_csv(nombre_archivo) do
    case File.read(nombre_archivo) do
      {:ok, contenido} ->
        String.split(contenido, "\n")
        |> Enum.map(fn linea ->
          case String.split(linea, ",") do
            [nombre, identificacion, edad, equipo] when is_binary(nombre) and is_binary(identificacion) and is_binary(edad) and is_binary(equipo) ->
              %Persona{nombre: String.trim(nombre), identificacion: String.trim(identificacion), edad: String.trim(edad), equipo: String.trim(equipo)}
            _ -> nil
          end
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
