#Pruebas de funcionalidades

defmodule PruebaCode do
  require Equipo
  require Persona

  def prueba() do
    persona1 = Persona.crear_Usuario()
    persona2 = Persona.crear_Usuario()
    IO.inspect(persona1)
    IO.inspect(persona2)

    equipo1 = Equipo.crearEquipo()
    IO.inspect(equipo1)

    equipo1 = Equipo.ingresar_integrante(equipo1, persona1)
    equipo1 = Equipo.ingresar_integrante(equipo1, persona2)
    IO.inspect(equipo1)

    lista_personas = [persona1, persona2]
    Persona.escribir_csv(lista_personas, "personas.csv")
    lista_equipos = [equipo1]
    Equipo.escribir_csv(lista_equipos, "equipos.csv")

    personas_leidas = Persona.leer_csv("personas.csv")
    equipos_leidos = Equipo.leer_csv("equipos.csv")
    IO.inspect(personas_leidas)
    IO.inspect(equipos_leidos)
  end

end

PruebaCode.prueba()

