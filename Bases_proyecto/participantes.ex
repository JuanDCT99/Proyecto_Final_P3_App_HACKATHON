#Implementacion de la logica para registrar participantes



defmodule Participantes do

  @moduledoc"""
  Modulo encargado de la creacion de participantes en el hackathon
  y el manejo de sus datos personales.
  """

  #Creación de los participantes usando structs
  defstruct nombre: "", identificacion: "", edad: 0, correo: "", telefono: ""

  def crear_participante(nombre, identificacion, edad, correo, telefono) do
    %Participantes{
      nombre: nombre,
      identificacion: identificacion,
      edad: edad,
      correo: correo,
      telefono: telefono
    }
  end
end
