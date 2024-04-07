defmodule Caravan do
  alias __MODULE__

  defstruct(
    # configuration: workers
    workers: []
  )

  @spec new_configuration(list()) :: %Caravan{workers: list()}
  def new_configuration(workers) do
    %Caravan{workers: workers}
  end

  # TODO: missing spec
  defp broadcast_to_workers(%Caravan{workers: workers}, msg) do
    workers
    |> Enum.map(fn pid -> send(pid, msg) end)
  end

  defp handle_client_command(state = %Caravan{}, client, cmd) do
    requirements = Caravan.Requirements.new(200)
    schedule_request = Caravan.ScheduleRequest.new(:test, cmd, requirements)
    broadcast_to_workers(state, schedule_request)

    {worker, response} =
      receive do
        {worker, response} -> {worker, response}
      end

    IO.puts("Worker #{worker} is responded to work request")

    release_request = Caravan.ReleaseRequest.new(:test, worker)
    broadcast_to_workers(state, release_request)

    reserve_request = Caravan.ReserveRequest.new(cmd)
    send(worker, reserve_request)

    state
  end

  def run(state = %Caravan{}) do
    receive do
      {client, msg} ->
        IO.puts("Server received message #{msg}")
        run(handle_client_command(state, client, msg))
    end
  end
end
