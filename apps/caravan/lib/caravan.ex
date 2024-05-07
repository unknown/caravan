defmodule Caravan do
  import Emulation, only: [send: 2]

  import Kernel, except: [send: 2]

  require Logger

  alias __MODULE__

  defstruct(
    # configuration: workers
    workers: [],
    # next command id
    cmd_seq: 1
  )

  @spec new_configuration(list()) :: %Caravan{workers: list()}
  def new_configuration(workers) do
    %Caravan{workers: workers}
  end

  @spec broadcast_to_workers(%Caravan{workers: list()}, any()) :: list()
  defp broadcast_to_workers(%Caravan{workers: workers}, msg) do
    workers
    |> Enum.map(fn pid -> send(pid, msg) end)
  end

  @spec broadcast_to_workers_except(%Caravan{workers: list()}, atom(), any()) :: list()
  defp broadcast_to_workers_except(%Caravan{workers: workers}, worker, msg) do
    workers
    |> Enum.filter(fn pid -> pid != worker end)
    |> Enum.map(fn pid -> send(pid, msg) end)
  end

  @spec handle_client_command(%Caravan{cmd_seq: non_neg_integer()}, atom(), %Caravan.Task{}) ::
          %Caravan{
            cmd_seq: non_neg_integer()
          }
  defp handle_client_command(state = %Caravan{cmd_seq: id}, client, task) do
    Logger.debug("Client #{client} sent command #{id}")

    requirements = Caravan.Requirements.new(200)
    schedule_request = Caravan.ScheduleRequest.new(id, task, requirements)
    broadcast_to_workers(state, schedule_request)

    worker =
      receive do
        {worker, response = %Caravan.ScheduleResponse{}} when response.id == id ->
          release_request = Caravan.ReleaseRequest.new(id)
          broadcast_to_workers_except(state, worker, release_request)
          worker
      after
        1_000 -> nil
      end

    if worker do
      Logger.debug("Worker #{worker} responded to work request #{id}")
      reserve_request = Caravan.ReserveRequest.new(id, client, task)
      send(worker, reserve_request)
    else
      Logger.warning("No worker responded to work request #{id} within timeout")
      send(client, {:error, :no_worker_available})
    end

    %{state | cmd_seq: id + 1}
  end

  @spec handle_reserve_response(%Caravan{}, %Caravan.ReserveResponse{}) :: %Caravan{}
  defp handle_reserve_response(state, %Caravan.ReserveResponse{
         client: client,
         error: error,
         payload: payload
       }) do
    send(client, {error, payload})
    state
  end

  @spec run(%Caravan{cmd_seq: non_neg_integer()}) :: no_return()
  def run(state = %Caravan{cmd_seq: id}) do
    receive do
      # ignore late schedule responses
      {_worker, %Caravan.ScheduleResponse{id: response_id}} when response_id != id ->
        run(state)

      {_worker, reserve_response = %Caravan.ReserveResponse{}} ->
        run(handle_reserve_response(state, reserve_response))

      {client, task = %Caravan.Task{}} ->
        run(handle_client_command(state, client, task))

      {_, _} ->
        Logger.error("Unhandled message")
        run(state)
    end
  end
end
