#Logica de mensajeria

defmodule ProyectoFinal.Chat.Server do

  use GenServer
  alias ProyectoFinal.Domain.Mensaje

  #Interfaz Publica (API del Cliente)
   @doc"""

   Inicio del GenServer para el chat en tiempo real

   ¿Y que es GenServer?

    Un GenServer es un proceso que sigue el modelo de servidor genérico en Elixir.
    Permite manejar el estado y la comunicación entre procesos de manera concurrente y segura.

   """

   def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
   end

   @doc """

   Envia un mensaje al chat. Esta es una operacion asincrona

   ¿Que significa asincrona?
    Una operacion asincrona significa que el remitente
    NO espera una respuesta inmediata del destinatario.
   """

   def enviar_mensaje(remitente, destinatario, contenido) do
    GenServer.cast(__MODULE__, {:enviar_mensaje, remitente, destinatario, contenido})
   end

   @doc """

   Obtiene todos los mensajes del estado del servidor. Esto es una operacion sincrona

   ¿Que significa sincrona?
    Una operacion sincrona significa que el remitente
    SI espera una respuesta inmediata del destinatario.
   """

   def obtener_mensajes() do
    GenServer.call(__MODULE__, :obtener_mensajes)
   end


   # --- Callbacks del GenServer ----

   @doc """

    Inicializa el estado del GenServer con una lista vacia de mensajes

    ¿Que es el Callback?
    Un Callback es una funcion que se llama
    automaticamente en respuesta a ciertos eventos o acciones.

    ¿Que es el estado?
    El estado es la informacion que el GenServer mantiene internamente
    para rastrear datos relevantes durante su ciclo de vida.
   """

   @impl true
   def init(_args) do
    #Se cargan los mensajes desde el archivo CSV al iniciar el servidor
    mensajes = Mensaje.leer_csv("priv/mensajes.csv")
    IO.puts("Servidor de chat iniciado. Mensajes cargados desde CSV. En total se cargaron #{length(mensajes)} mensajes.")
    {:ok, mensajes}
   end

   @impl true
   def handle_cast({:enviar_mensaje, remitente, destinatario, contenido}, mensajes) do



    #Crear un nuevo mensaje
    nuevo_mensaje = Mensaje.crear(remitente, destinatario, contenido)

    #Guardar el mensaje en el estado actual
    nuevos_mensajes = [nuevo_mensaje | mensajes]

    #Guardar el mensaje en el archivo CSV
    Mensaje.escribir_csv(nuevos_mensajes, "priv/mensajes.csv")

    #Mostrar mensaje en consola
    IO.puts("[CHAT] Mensaje enviado de #{remitente} a #{destinatario}: #{contenido}")

    {:noreply, nuevos_mensajes}
   end

   @impl true
   def handle_call(:obtener_mensajes, _from, mensajes) do
    {:reply, mensajes, mensajes}
   end
end
