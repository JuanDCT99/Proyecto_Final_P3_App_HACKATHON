defmodule Mentor do

  defstruct nombre: "", identificacion: "", celular: "", edad: "", equipo: ""

  def crear_mentor() do
    nombre = Funcional.input("Ingrese su nombre señor(a) mentor(a): ", :string)
    identificacion = Funcional.input("Ingrese su identificación señor(a) mentor(a): ", :string)
    celular = Funcional.input("Ingrese su número de celular señor(a) mentor(a): ", :string)
    edad = Funcional.input("Ingrese su edad señor(a) mentor(a): ", string)
    equipo = Funcional.input("Ingrese su equipo señor(a) mentor(a): ", :string)
    crear(nombre, identificacion, celular, edad, equipo)
  end

  def crear(nombre, identificacion, celular, edad, equipo) do
  %Mentor{nombre: nombre, identificacion: identificacion, celular: celular, edad: edad, equipo: equipo}
  end

  def escribir_csv(lista_mentores, nombre_archivo) do
    encabezado = "Nombre, Identificacion, celular, Edad, Equipo\n"
    contenido =
      Enum.map(lista_mentores,
        fn %Mentor{nombre: nombre, identificacion: identificacion, celular: celular, edad: edad, equipo: equipo} ->
          "#{nombre},#{identificacion},#{celular},#{edad},#{equipo}\n"
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
            [nombre, identificacion, celular, edad, equipo] when is_binary(nombre) and is_binary(identificacion) and is_binary(celular) and is_binary(edad) and is_binary(equipo) ->
              %Persona{nombre: String.trim(nombre), identificacion: String.trim(identificacion), celular: String.trim(celular), edad: String.trim(edad), equipo: String.trim(equipo)}
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)
      {:error, _reason} ->
        IO.puts("Error al leer el archivo #{nombre_archivo}")
        []
    end
  end

  def asigar_mentor_a_equipo(mentor, nombre_equipo) do
    %{mentor | equipo: nombre_equipo}
  end

end
