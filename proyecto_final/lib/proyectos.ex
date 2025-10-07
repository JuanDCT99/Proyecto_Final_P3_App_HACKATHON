#Logica para la creación de proyectos

defmodule Proyectos_Hackathon do

  defstruct nombre: "", descripcion: "", categoria: "", estado: "", integrantes: [], avances: []

  def crear_Proyecto() do
    nombre = Funcional.input("Ingrese el nombre del proyecto: ", :string)
    descripcion = Funcional.input("Ingrese la descripcion del proyecto: ", :string)
    categoria = Funcional.input("Ingrese la categoria del proyecto: ", :string)
    estado = Funcional.input("Ingrese el estado del proyecto (En desarrollo/Finalizado): ", :string)
    crear(nombre, descripcion, categoria, estado, [], [])
  end

  def crear(nombre, descripcion, categoria, estado, integrantes, avances) do
    %Proyectos_Hackathon{nombre: nombre, descripcion: descripcion, categoria: categoria, estado: estado, integrantes: integrantes, avances: avances}
  end

  def 
end
