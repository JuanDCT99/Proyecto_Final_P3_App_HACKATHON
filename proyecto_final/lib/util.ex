defmodule Util do
  # Muestra un mensaje a través de Java
  def show_message(message) when is_binary(message) do
    System.cmd("java", ["-cp", ".", "Mensaje", message])
  end

  # Lee texto (string) desde Java
  def input(message, :string) when is_binary(message) do
    {output, _exit_code} =
      System.cmd("java", ["-cp", ".", "Mensaje", "input", message, ":string"])

    output |> String.trim()
  end

  # Lee entero con reintento si el usuario se equivoca
  def input(message, :integer) when is_binary(message) do
    try do
      message
      |> input(:string)
      |> String.trim()
      |> String.to_integer()
    rescue
      ArgumentError ->
        show_message("Error: Debe ingresar un entero válido.")
        input(message, :integer)
    end
  end

  # Lee flotante con reintento si el usuario se equivoca
  def input(message, :float) when is_binary(message) do
    try do
      message
      |> input(:string)
      |> String.trim()
      |> String.to_float()
    rescue
      ArgumentError ->
        show_message("Error: Debe ingresar un número real válido (use punto decimal).")
        input(message, :float)
    end
  end

  # Guardas de error para el primer argumento no binario
  def input(message, _type) when not is_binary(message) do
    raise ArgumentError, "El mensaje debe ser una cadena de texto"
  end

  # Guardas de error para tipos no soportados
  def input(_message, type) do
    raise ArgumentError,
          "Tipo no soportado: #{inspect(type)}. Use :string, :integer, o :float"
  end

end
