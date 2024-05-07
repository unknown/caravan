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

  defstruct(id: nil, client: nil, task: nil)

  @spec new(non_neg_integer(), atom(), %Caravan.Task{}) :: %ReserveRequest{
          id: non_neg_integer(),
          client: atom(),
          task: %Caravan.Task{}
        }
  def new(id, client, task) do
    %ReserveRequest{id: id, client: client, task: task}
  end
end

defmodule Caravan.ReserveResponse do
  alias __MODULE__

  defstruct(id: nil, client: nil, error: nil, payload: nil)

  @spec new(non_neg_integer(), atom(), atom() | nil, any()) :: %ReserveResponse{
          id: non_neg_integer(),
          client: atom(),
          error: atom() | nil,
          payload: any()
        }
  def new(id, client, error, payload) do
    %ReserveResponse{id: id, client: client, error: error, payload: payload}
  end
end
