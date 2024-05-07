defmodule Caravan.Worker do
  import Emulation, only: [send: 2, whoami: 0]

  import Kernel, except: [send: 2]

  require Logger

  alias __MODULE__

  defstruct(available: true)

  @spec new() :: %Worker{available: boolean()}
  def new() do
    %Worker{available: true}
  end

  @spec handle_schedule_request(%Worker{available: boolean()}, atom(), %Caravan.ScheduleRequest{}) ::
          %Worker{
            available: boolean()
          }
  def handle_schedule_request(
        state = %Worker{available: available},
        server,
        %Caravan.ScheduleRequest{id: id}
      ) do
    Logger.debug("Worker #{whoami()} received schedule request #{id}")

    if available do
      response = Caravan.ScheduleResponse.new(id)
      send(server, response)
      %{state | available: false}
    else
      state
    end
  end

  @spec handle_release_request(%Worker{}) :: %Worker{available: true}
  def handle_release_request(state = %Worker{}) do
    Logger.debug("Worker #{whoami()} received release request")
    %{state | available: true}
  end

  @spec handle_reserve_request(%Worker{}, atom(), %Caravan.ReserveRequest{}) ::
          %Worker{
            available: true
          }
  def handle_reserve_request(
        state = %Worker{},
        server,
        %Caravan.ReserveRequest{id: id, client: client, task: task}
      ) do
    Logger.debug("Worker #{whoami()} received reserve request #{id}")

    {error, result} =
      case task.task do
        :double -> {nil, task.payload * 2}
        _ -> {"Unimplemented task", nil}
      end

    response = Caravan.ReserveResponse.new(id, client, error, result)
    send(server, response)
    %{state | available: true}
  end

  @spec run(%Worker{}) :: no_return()
  def run(state = %Worker{}) do
    receive do
      {server, schedule_request = %Caravan.ScheduleRequest{}} ->
        run(handle_schedule_request(state, server, schedule_request))

      {_server, %Caravan.ReleaseRequest{}} ->
        run(handle_release_request(state))

      {server, reserve_request = %Caravan.ReserveRequest{}} ->
        run(handle_reserve_request(state, server, reserve_request))
    end
  end
end
