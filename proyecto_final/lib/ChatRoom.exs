defmodule TeamChat.RoomServer do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{rooms: %{}, equipos: %{}}, name: __MODULE__)
  end

  def join_team(id_equipo, id_usuario, username) do
    GenServer.call(__MODULE__, {:join_team, id_equipo, id_usuario, username})
  end

   def join_room(id_sala, username) do
    GenServer.call(__MODULE__, {:join_room, id_sala, username})
  end

  def leave_room(id_sala, username) do
    GenServer.cast(__MODULE__, {:leave_room, id_sala, username})
  end

  def get_room_info(id_sala) do
    GenServer.call(__MODULE__, {:get_room_info, id_sala})
  end

  def create_room(id_sala, nombre, tema) do
    GenServer.call(__MODULE__, {:create_room, id_sala, nombre, tema})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:join_team, id_equipo, id_usuario, username}, _from, state) do
    equipo = Map.get(state.teams, id_equipo, %{nombre: "Equipo #{id_equipo}", miembros: []})

    if Enum.any?(miembros.equipo, fn m -> m.id == id_usuario end) do
      {reply, {:ok, equipo}, state}
    else
      miembro = %{id: id_usuario, username: username, joined_at: DateTime.utc_now()}
      equipo_actualizado = Map.update!(equipo, :miembros, &[miembro | &1])
      new_state = put_in(state, [:teams, id_equipo], equipo_actualizado)

      {:reply, {:ok, equipo_actualizado}, new_state}
    end
  end

  def handle_call({:create_room, id_sala, nombre, tema}, _from, state)
  sala = %{
    id: id_sala,
    nombre: nombre,
    tema: tema,
    participantes: [],
    created_at: DateTime.utc_now()
  }

  new_state = put_in(state, [:rooms, id_sala], sala)
  {:reply, {:ok, sala}, new_state}
end

 def handle_call({:join_room, is_sala, id_usuario}, _from, state) do
    case Map.get(state.rooms, id_sala) do
      nil ->
        {:reply, {:error, :room_not_found}, state}

      sala ->
        if id_sala in participantes_sala do
          {:reply, {:ok, sala}, state}
        else
          sala_actualizada = Map.update!(sala, :participants, &[id_usuario | &1])
          new_state = put_in(state, [:rooms, id_sala], sala_actualizada)
          {:reply, {:ok, sala_actualizada}, new_state}
        end
    end
  end

  def handle_call({:get_room_info, id_sala}, _from, state) do
    sala = Map.get(state.rooms, id_sala)
    {:reply, sala, state}
  end

  def handle_cast({:leave_room, id_sala, id_usuario}, state) do
    case Map.get(state.rooms, id_sala) do
      nil ->
        {:noreply, state}

      sala ->
        sala_actualizada = Map.update!(sala, :participants, &List.delete(&1, id_usuario))
        new_state = put_in(state, [:rooms, id_sala], sala_actualizada)
        {:noreply, new_state}
    end
  end
