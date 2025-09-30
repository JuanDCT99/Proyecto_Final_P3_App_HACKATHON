#Logica del registro de personas

defmodule Persona do


  def llamar_persona do
    nombre = pedir_nombre()
    identificacion = pedir_identificacion()
    edad = pedir_edad()
    correo = pedir_correo()
    telefono = pedir_telefono()
    registrar_persona(nombre, identificacion, edad, correo, telefono)
  end

  def pedir_nombre do
    Funcional.input("Ingrese su nombre: ", :string)
  end

  def pedir_identificacion do
    Funcional.input("Ingrese su identificacion: ", :string)
  end

  def pedir_edad do
    Funcional.input("Ingrese su edad: ", :integer)
  end

  def pedir_correo do
    Funcional.input("Ingrese su correo: ", :string)
  end

  def pedir_telefono do
    Funcional.input("Ingrese su telefono: ", :string)
  end

  def registrar_persona(nombre, identificacion, edad, correo, telefono) do
    Funcional.mostrar_mensaje("Se ha registrado la persona con los siguientes datos:")
    Funcional.mostrar_mensaje("\nNombre: #{nombre}, \n
                              Identificacion: #{identificacion}, \n
                              Edad: #{edad}, \n
                              Correo: #{correo}, \n
                              elefono: #{telefono}")
  end

  def registrar_persona(_, _, _, _, _) do
    Funcional.mostrar_mensaje("Error: No se pudo registrar la persona. Inténtalo de nuevo.")
  end


end

Persona.llamar_persona()
