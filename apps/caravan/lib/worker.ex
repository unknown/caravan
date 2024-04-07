defmodule Caravan.Worker do
  import Emulation, only: [send: 2]

  import Kernel, except: [send: 2]

  alias __MODULE__

  defstruct(available: true)

  def new() do
    %Worker{available: true}
  end

  def handle_schedule_request(state = %Worker{available: available}, id, server) do
    if available do
      response = Caravan.ScheduleResponse.new(id)
      send(server, response)
      %{state | available: false}
    else
      state
    end
  end

  def handle_release_request(state = %Worker{}) do
    %{state | available: true}
  end

  def handle_reserve_request(state = %Worker{}, id, _task, server) do
    response = Caravan.ReserveResponse.new(id, nil)
    send(server, response)
    %{state | available: true}
  end

  def run(state = %Worker{}) do
    receive do
      {server, %Caravan.ScheduleRequest{id: id}} ->
        run(handle_schedule_request(state, id, server))

      {_server, %Caravan.ReleaseRequest{}} ->
        run(handle_release_request(state))

      {server, %Caravan.ReserveRequest{id: id, task: task}} ->
        run(handle_reserve_request(state, id, task, server))
    end
  end
end
