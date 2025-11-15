# Definicion de las funciones empleadas para este trabajo de seguimiento
defmodule ProyectoFinal.Services.Util do

  def mostrar_mensaje(mensaje) do
    System.cmd("java", ["-cp", ".", "Mensaje", mensaje])
  end

  def input(mensaje, :string) do
    {output, _} = System.cmd("java", ["-cp", ".", "Mensaje", "input", mensaje])
    String.trim(output)
  end

  def input(mensaje, :integer) do
    try do
      (
        {output, _} = System.cmd("java", ["-cp", ".", "Mensaje", "input", mensaje])
        String.trim(output)
        |> String.to_integer()
      )
    rescue
      ArgumentError ->
        IO.puts("Error: El valor ingresado no es un número entero. Inténtalo de nuevo.")
        input(mensaje, :integer)
    end
  end

  def input(mensaje, :float) do
    try do
      (
        {output, _} = System.cmd("java", ["-cp", ".", "Mensaje", "input", mensaje])
        String.trim(output)
        |> String.to_float()
      )
    rescue
      ArgumentError ->
        IO.puts("Error: El valor ingresado no es un número en formato valido. Inténtalo de nuevo.")
        input(mensaje, :float)
    end
  end

  def pedir_informacion() do
    input("Ingrese su nombre: ", :string)
  end


  # FUNCIONES AÑADIDAS PARA CONSULTAR PROYECTOS


  # Lee proyectos desde priv/proyectos.csv
  def leer_proyectos() do
    path = "priv/proyectos.csv"

    path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.drop(1) # Quita encabezado
    |> Enum.map(fn linea ->
      [nombre, descripcion, categoria, estado, integrantes, avances] =
        String.split(linea, ",", parts: 6)

      %{
        nombre: nombre,
        descripcion: descripcion,
        categoria: categoria,
        estado: estado,
        integrantes: integrantes,
        avances: avances
      }
    end)
  end

  # CONSULTAR PROYECTOS POR ESTADO
  def consultar_proyectos_por_estado(estado_buscado) do
    leer_proyectos()
    |> Enum.filter(fn proyecto ->
      String.downcase(proyecto.estado) == String.downcase(estado_buscado)
    end)
  end

  # CONSULTAR PROYECTOS POR CATEGORÍA
  def consultar_proyectos_por_categoria(categoria_buscada) do
    leer_proyectos()
    |> Enum.filter(fn proyecto ->
      String.downcase(proyecto.categoria) == String.downcase(categoria_buscada)
    end)
  end
end
