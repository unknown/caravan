defmodule Caravan do
  import Emulation, only: [send: 2]
  import Kernel, except: [send: 2]

  require Logger

  alias __MODULE__

  @type t :: %Caravan{
          workers: list(),
          worker_index: non_neg_integer(),
          cmd_seq: non_neg_integer()
        }

  defstruct(
    # configuration: workers
    workers: [],
    # next worker index for round robin scheduling
    worker_index: 0,
    # next command id
    cmd_seq: 1
  )

  @spec new_configuration(list()) :: t()
  def new_configuration(workers) do
    %Caravan{workers: workers, worker_index: 0}
  end

  @spec broadcast_to_worker(t(), any()) :: boolean()
  defp broadcast_to_worker(%Caravan{workers: workers, worker_index: worker_index}, msg) do
    workers
    |> Enum.at(worker_index)
    |> send(msg)
  end

  @spec handle_client_command(t(), atom(), Caravan.Task.t()) :: t()
  defp handle_client_command(
         state = %Caravan{workers: workers, worker_index: worker_index, cmd_seq: id},
         client,
         task
       ) do
    Logger.debug("Client #{client} sent command #{id}")

    reserve_request = Caravan.ReserveRequest.new(client, task)
    broadcast_to_worker(state, reserve_request)
    next_worker_index = rem(worker_index + 1, length(workers))

    %{state | worker_index: next_worker_index, cmd_seq: id + 1}
  end

  @spec handle_reserve_response(t(), Caravan.ReserveResponse.t()) :: t()
  defp handle_reserve_response(state, %Caravan.ReserveResponse{
         client: client,
         error: error,
         payload: payload
       }) do
    send(client, {error, payload})
    state
  end

  @spec run(t()) :: no_return()
  def run(state = %Caravan{}) do
    receive do
      {_worker, reserve_response = %Caravan.ReserveResponse{}} ->
        state
        |> handle_reserve_response(reserve_response)
        |> run()

      {client, task = %Caravan.Task{}} ->
        run(handle_client_command(state, client, task))

      {_, _} ->
        Logger.error("Unhandled message")
        run(state)
    end
  end
end
