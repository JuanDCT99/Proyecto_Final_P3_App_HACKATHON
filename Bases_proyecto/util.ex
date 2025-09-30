#Definicion de las funciones empleadas para este trabajo de seguimiento
defmodule Funcional do

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
end
