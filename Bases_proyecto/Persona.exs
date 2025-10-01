#Logica del registro de personas

defmodule Persona do
  defstruct nombre: "", identificacion: 0, edad: 0, correo: "", telefono: 0
end

  defmodule Main do
    def registrar_persona do
      Util.show_message("Registro de persona")

      nombre = Util.input("Ingrese el nombre:", :string)
      identificacion = Util.input("Ingrese su identificacion", :integer)
      edad = Util.input("Ingrese su edad", :integer)
      correo = Util.input("Ingrese su correo", :string)
      telefono = Util.input("Ingrese su telefono", :integer)

      persona = %Persona{nombre: nombre, identificacion: identificacion, edad: edad, correo: correo, telefono: telefono}

      Util.show_message("La persona ha sido registrada exitosamente")
      IO.inspect(persona, label: "Persona")
      persona

    end
  end


Main.registrar_persona()
