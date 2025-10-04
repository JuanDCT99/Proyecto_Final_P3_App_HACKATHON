#Logica para la creación de proyectos

defmodule Proyectos_Hackathon do

  defstruct nombre: "", descripcion: "", categoria: "", estado: "", integrantes: [], avances: []

  def crear_Proyecto() do
    nombre = Funcional.input("Ingrese el nombre del proyecto: ", :string)
    descripcion = Funcional.input("Ingrese la descripcion del proyecto: ", :string)
    categoria = Funcional.input("Ingrese la categoria del proyecto: ", :string)
    estado = Funcional.input("Ingrese el estado del proyecto (En desarrollo/Finalizado): ", :string)
    crear(nombre, descripcion, categoria, estado, [], [])
  end

  def crear(nombre, descripcion, categoria, estado, integrantes, avances) do
    %Proyectos_Hackathon{nombre: nombre, descripcion: descripcion, categoria: categoria, estado: estado, integrantes: integrantes, avances: avances}
  end

  def escrivir_csv(lista_proyectos, nombre_archivo) do
    encabezados = "Nombre,Descripción,Categoría,Estado,Integrantes,Avances\n"

    contenido =
      Enum.map(lista_proyectos,
        fn %Proyectos_Hackathon{nombre: nombre, descripcion: descripcion, categoria: categoria, estado: estado, integrantes: integrantes, avances: avances} ->
          "#{nombre},#{descripcion},#{categoria},#{estado},#{integrantes |> Enum.join(";")},#{avances |> Enum.join(";")}\n"
      end)
      |> Enum.join("")
    File.write!(nombre_archivo, encabezados <> contenido)
  end

  def leer_csv(nombre_archivo) do
    case File.read(nombre_archivo) do
      {:ok, contenido} ->
        String.split(contenido, "\n", trim: true)
        |> Enum.drop(1) # Omitir la línea de encabezados
        |> Enum.map(fn linea ->
          case String.split(linea, ",") do
            [nombre, descripcion, categoria, estado, integrantes_str, avances_str] ->
              integrantes = String.split(integrantes_str, ";")
              avances = String.split(avances_str, ";")
              %Proyectos_Hackathon{
                nombre: nombre,
                descripcion: descripcion,
                categoria: categoria,
                estado: estado,
                integrantes: integrantes,
                avances: avances
              }
            _ ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      {:error, _reason} ->
        IO.puts("Error al leer el archivo #{nombre_archivo}")
        []
    end
  end

end
