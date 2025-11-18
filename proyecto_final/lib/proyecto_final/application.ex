defmodule ProyectoFinal.Application do

  use Application

  @impl true
  def start(_type, _args) do
    children = [

      # Inicia nuestro nuevo servidor de chat cuando la aplicación arranca.
      ProyectoFinal.Chat.ChatServer
    ]


    opts = [strategy: :one_for_one, name: ProyectoFinal.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
