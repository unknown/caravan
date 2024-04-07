defmodule Caravan.Worker do
  alias __MODULE__

  defstruct(id: nil)

  def new(id) do
    %Worker{id: id}
  end

  def handle_schedule_request(state = %Worker{id: id}, server) do
    response = Caravan.ScheduleResponse.new(id)
    send(server, response)
    state
  end

  def handle_reserve_request(state = %Worker{id: id}, server) do
    state
  end

  def run(state = %Worker{}) do
    receive do
      {server, %Caravan.ScheduleRequest{}} ->
        run(handle_schedule_request(state, server))

      {server, %Caravan.ReserveRequest{}} ->
        run(handle_reserve_request(state, server))
    end
  end
end
