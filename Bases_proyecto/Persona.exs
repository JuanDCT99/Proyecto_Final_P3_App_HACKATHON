#Logica del registro de personas

defmodule Persona do
  defstruct nombre: "", identificacion: 0, edad: 0, correo: "", telefono: 0
end

defmodule Equipo do
  defstruct nombre: "", participantes: [], activo: true
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

    def GestorEquipos do
      Util.show_message("Menu Principal")
      Util.show_message("1. /teams Listar equipos")
      Util.show_message("2. crear nuevo equipo")
      Util.show_message("3. /Join equipo - unirse")
      Util.show_message("4. Salir")

      opcion = Util.input("seleccione una opción:", :integer)

      case opcion do

      end
    end

    def crear_equipo do
      Util.show_message("Crear nuevo equipo")
      nombre_equipo = Util.input("Ingresa el nombre del equipo:", :String)

      %Equipo{
        nombre: nombre_equipo,
        participantes: [],
        activo: true
      }
    end
  end


Main.registrar_persona()
