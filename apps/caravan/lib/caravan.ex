defmodule Caravan do
  import Emulation, only: [send: 2]

  import Kernel, except: [send: 2]

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

  @spec handle_client_command(%Caravan{cmd_seq: non_neg_integer()}, atom(), any()) :: %Caravan{
          cmd_seq: non_neg_integer()
        }
  defp handle_client_command(state = %Caravan{cmd_seq: id}, client, cmd) do
    requirements = Caravan.Requirements.new(200)
    schedule_request = Caravan.ScheduleRequest.new(id, cmd, requirements)
    broadcast_to_workers(state, schedule_request)

    IO.puts("Broadcasting work request #{id}")

    worker =
      receive do
        {worker, response = %Caravan.ScheduleResponse{}} when response.id == id ->
          worker
      end

    IO.puts("Worker #{worker} responded to work request #{id}")

    release_request = Caravan.ReleaseRequest.new(id)
    broadcast_to_workers_except(state, worker, release_request)

    reserve_request = Caravan.ReserveRequest.new(id, cmd)
    send(worker, reserve_request)

    response =
      receive do
        {w, response = %Caravan.ReserveResponse{}} when w == worker and response.id == id ->
          response
      end

    send(client, response)

    %{state | cmd_seq: id + 1}
  end

  @spec run(%Caravan{cmd_seq: non_neg_integer()}) :: no_return()
  def run(state = %Caravan{cmd_seq: id}) do
    receive do
      # ignore late schedule responses
      {_, %Caravan.ScheduleResponse{id: response_id}} when response_id != id ->
        state

      # ignore late reserve responses
      {_, %Caravan.ReserveResponse{id: response_id}} when response_id != id ->
        state

      {client, msg} ->
        run(handle_client_command(state, client, msg))
    end
  end
end
