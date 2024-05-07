defmodule Caravan do
  import Emulation, only: [send: 2]

  import Kernel, except: [send: 2]

  require Logger

  alias __MODULE__

  defstruct(
    # configuration: workers
    workers: [],
    # next worker index for round robin scheduling
    worker_index: 0,
    # next command id
    cmd_seq: 1
  )

  @spec new_configuration(list()) :: %Caravan{workers: list()}
  def new_configuration(workers) do
    %Caravan{workers: workers}
  end

  @spec broadcast_to_worker(%Caravan{workers: list()}, any()) :: boolean
  defp broadcast_to_worker(%Caravan{workers: workers, worker_index: worker_index}, msg) do
    worker = Enum.at(workers, worker_index)
    send(worker, msg)
  end

  @spec handle_client_command(%Caravan{cmd_seq: non_neg_integer()}, atom(), %Caravan.Task{}) ::
          %Caravan{
            cmd_seq: non_neg_integer()
          }
  defp handle_client_command(
         state = %Caravan{workers: workers, worker_index: worker_index, cmd_seq: id},
         client,
         task
       ) do
    Logger.notice("Client #{client} sent command #{id}")

    reserve_request = Caravan.ReserveRequest.new(client, task)
    broadcast_to_worker(state, reserve_request)
    next_worker_index = rem(worker_index + 1, length(workers))

    %{state | worker_index: next_worker_index, cmd_seq: id + 1}
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
  def run(state = %Caravan{}) do
    receive do
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
