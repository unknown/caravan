defmodule Caravan.Task do
  alias __MODULE__

  defstruct(task: nil, payload: nil)

  @spec new(atom(), any()) :: %Task{task: atom(), payload: any()}
  def new(task, payload) do
    %Task{task: task, payload: payload}
  end
end

defmodule Caravan.ReserveRequest do
  alias __MODULE__

  defstruct(client: nil, task: nil)

  @spec new(atom(), %Caravan.Task{}) :: %ReserveRequest{client: atom(), task: %Caravan.Task{}}
  def new(client, task) do
    %ReserveRequest{client: client, task: task}
  end
end

defmodule Caravan.ReserveResponse do
  alias __MODULE__

  defstruct(client: nil, error: nil, payload: nil)

  @spec new(atom(), atom() | nil, any()) :: %ReserveResponse{
          client: atom(),
          error: atom() | nil,
          payload: any()
        }
  def new(client, error, payload) do
    %ReserveResponse{client: client, error: error, payload: payload}
  end
end
