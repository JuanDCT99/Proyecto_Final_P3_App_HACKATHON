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


  #   FUNCIONES PARA CONSULTAR PROYECTOS


  def leer_proyectos() do
    path = "priv/proyectos.csv"

    path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.drop(1)
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

  def consultar_proyectos_por_estado(estado_buscado) do
    leer_proyectos()
    |> Enum.filter(fn proyecto ->
      String.downcase(proyecto.estado) == String.downcase(estado_buscado)
    end)
  end

  def consultar_proyectos_por_categoria(categoria_buscada) do
    leer_proyectos()
    |> Enum.filter(fn proyecto ->
      String.downcase(proyecto.categoria) == String.downcase(categoria_buscada)
    end)
  end



  #   CREACIÓN DE "EQUIPOS POR AFINIDAD"
  #   Agrupa proyectos según su categoría

  def crear_equipos_por_afinidad() do
    leer_proyectos()
    |> Enum.group_by(fn proyecto ->
      proyecto.categoria
    end)
  end

  #   NUEVO: MOSTRAR RESULTADO EN CONSOLA


  def mostrar_equipos_por_afinidad() do
    grupos = crear_equipos_por_afinidad()

    IO.puts("\n=== EQUIPOS AGRUPADOS POR AFINIDAD (CATEGORÍA) ===\n")

    Enum.each(grupos, fn {categoria, proyectos} ->
      IO.puts("Categoría: #{categoria}")
      IO.puts("Equipos relacionados:")

      Enum.each(proyectos, fn p ->
        IO.puts("  - #{p.nombre}: #{p.descripcion} (#{p.estado})")
      end)

      IO.puts("")
    end)

    :ok
  end

end
