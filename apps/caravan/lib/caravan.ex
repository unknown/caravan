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

  @spec broadcast_to_worker(%Caravan{workers: list()}, any()) :: boolean
  defp broadcast_to_worker(%Caravan{workers: workers}, msg) do
    # TODO: round robin the selected worker
    worker = hd(workers)
    send(worker, msg)
  end

  @spec handle_client_command(%Caravan{cmd_seq: non_neg_integer()}, atom(), %Caravan.Task{}) ::
          %Caravan{
            cmd_seq: non_neg_integer()
          }
  defp handle_client_command(state = %Caravan{cmd_seq: id}, client, task) do
    Logger.debug("Client #{client} sent command #{id}")

    reserve_request = Caravan.ReserveRequest.new(id, client, task)
    broadcast_to_worker(state, reserve_request)

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
