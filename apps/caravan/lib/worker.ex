defmodule Caravan.Worker do
  import Emulation, only: [send: 2, whoami: 0]
  import Kernel, except: [send: 2]

  require Logger

  alias __MODULE__

  @type t :: %Worker{tasks: :queue.queue()}

  @enforce_keys [:tasks]
  defstruct(tasks: nil)

  @spec new() :: t()
  def new() do
    %Worker{tasks: :queue.new()}
  end

  @spec handle_reserve_request(t(), atom(), Caravan.ReserveRequest.t()) :: t()
  defp handle_reserve_request(
         state = %Worker{tasks: tasks},
         server,
         reserve_request = %Caravan.ReserveRequest{}
       ) do
    Logger.debug("Worker #{whoami()} received task #{inspect(reserve_request.task)}")

    send(whoami(), :work)

    %{state | tasks: :queue.in({server, reserve_request}, tasks)}
  end

  @spec handle_work(t()) :: t()
  defp handle_work(state = %Worker{tasks: tasks}) do
    case :queue.out(tasks) do
      {{:value, {server, %Caravan.ReserveRequest{client: client, task: task}}}, tasks} ->
        {error, result} = perform_task(task)
        response = Caravan.ReserveResponse.new(client, error, result)
        send(server, response)
        %{state | tasks: tasks}

      {:empty, _} ->
        state
    end
  end

  @spec perform_task(Caravan.Task.t()) :: {nil, any()} | {any(), nil}
  defp perform_task(%Caravan.Task{task: :double, payload: payload}), do: {nil, payload * 2}
  defp perform_task(%Caravan.Task{task: _}), do: {"Unimplemented task", nil}

  @spec run(t()) :: no_return()
  def run(state = %Worker{}) do
    receive do
      {server, reserve_request = %Caravan.ReserveRequest{}} ->
        state
        |> handle_reserve_request(server, reserve_request)
        |> run()

      {_, :work} ->
        state
        |> handle_work()
        |> run()
    end
  end
end
