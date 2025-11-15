defmodule Cookie do
  @longitud_llave 10

  def main() do
    :crypto.strong_rand_bytes(@longitud_llave)
    |> Base.encode64()
    |> IO.puts()
  end
end

Cookie.main()
