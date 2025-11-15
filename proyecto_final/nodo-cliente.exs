#Implicacion de nodo-cliente para la comunicacion entre nodos


defmodule NodoCliente do
  # Alias para la utilidad

  alias ProyectoFinal.Services.Util, as: Funcional

  @nombre_servicio_local :servicio_respuesta
  @servicio_local {@nombre_servicio_local, Node.self()}
  @nodo_remoto :nodoServidor@localhost
  @servicio_remoto {@nombre_servicio_local, @nodo_remoto}

  #Lista de mensajes a procesar
  @mensajes [
    {:mayusculas, "Juan"},
    {:mayusculas, "Ana"},
    {:minusculas, "Diana"},
    {:revertir, "Julian"},
    "Uniquindio",
    :fin
  ]

  def main() do
    Util.mostrar_mensaje("Proceso principal del nodo cliente iniciado en #{Node.self()}")
    registrar_servicio(@nombre_servicio_local)

    case establecer_conexion(@nodo_remoto) do
      true ->
        Util.mostrar_mensaje("Conexión establecida con el nodo remoto #{@nodo_remoto}")
        iniciar_produccion()
      false ->
        Util.mostrar_mensaje("No se pudo establecer conexión con el nodo remoto #{@nodo_remoto}")
        Util.mostrar_mensaje("Asegúrese de que el nodo servidor esté en ejecución y vuelva a intentarlo.  Saliendo...")
    end
  end

  defp registrar_servicio(nombre_servicio_local),
  do: Process.register(self(), nombre_servicio_local)

  defp establecer_conexion(nodo_remoto) do
    Node.connect(nodo_remoto)
  end

  defp iniciar_produccion() do
    enviar_mensajes()
    recibir_respuestas()
  end

  defp enviar_mensajes() do
    Enum.each(@mensajes, &enviar_mensaje/1)
  end

  defp recibir_respuestas() do
    receive do
      :fin ->
        Util.mostrar_mensaje("Recepción de respuestas finalizada. Saliendo...")
        :ok
      respuesta ->
        Util.mostrar_mensaje("Respuesta recibida del nodo servidor: #{inspect(respuesta)}")

        recibir_respuestas()
      after
        5000 ->
          Util.mostrar_mensaje("Tiempo de espera agotado para recibir respuestas. Saliendo...")
          :timeout
        end
      end
end
