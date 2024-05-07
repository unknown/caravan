defmodule Caravan.Worker do
  import Emulation, only: [send: 2, whoami: 0]

  import Kernel, except: [send: 2]

  require Logger

  alias __MODULE__

  defstruct(tasks: :queue.new())

  @spec new() :: %Worker{tasks: :queue.queue()}
  def new() do
    %Worker{tasks: :queue.new()}
  end

  @spec handle_reserve_request(%Worker{}, atom(), %Caravan.ReserveRequest{}) :: %Worker{}
  def handle_reserve_request(
        state = %Worker{tasks: tasks},
        server,
        reserve_request = %Caravan.ReserveRequest{}
      ) do
    Logger.debug("Worker #{whoami()} received task #{inspect(reserve_request.task)}")

    send(whoami(), :work)

    %{state | tasks: :queue.in({server, reserve_request}, tasks)}
  end

  @spec handle_work(%Worker{}) :: %Worker{}
  def handle_work(state = %Worker{tasks: tasks}) do
    {task, tasks} = :queue.out(tasks)

    case task do
      {:value, {server, %Caravan.ReserveRequest{client: client, task: task}}} ->
        {error, result} = perform_task(task)
        response = Caravan.ReserveResponse.new(client, error, result)
        send(server, response)
        nil

      :empty ->
        nil
    end

    %{state | tasks: tasks}
  end

  @spec perform_task(%Caravan.Task{}) :: {any(), nil} | {nil | any()}
  def perform_task(%Caravan.Task{task: task, payload: payload}) do
    case task do
      :double -> {nil, payload * 2}
      _ -> {"Unimplemented task", nil}
    end
  end

  @spec run(%Worker{}) :: no_return()
  def run(state = %Worker{}) do
    receive do
      {server, reserve_request = %Caravan.ReserveRequest{}} ->
        run(handle_reserve_request(state, server, reserve_request))

      {_, :work} ->
        run(handle_work(state))
    end
  end
end
