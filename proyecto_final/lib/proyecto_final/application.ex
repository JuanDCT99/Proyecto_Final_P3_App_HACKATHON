defmodule ProyectoFinal.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: ProyectoFinal.Worker.start_link(arg)
      # {ProyectoFinal.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ProyectoFinal.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
