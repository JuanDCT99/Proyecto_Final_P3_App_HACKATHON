defmodule Cookie do
  @longitud_llave 426

  def main() do
    :crypto.strong_rand_bytes(@longitud_llave)
    |> Base.encode64()
    |> Funcional.mostrar_mensaje()
  end
end

Cookie.main()
