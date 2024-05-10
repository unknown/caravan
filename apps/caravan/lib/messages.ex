defmodule Caravan.Task do
  alias __MODULE__

  @type t :: %Task{
          task: atom(),
          payload: any()
        }

  @enforce_keys [:task, :payload]
  defstruct(task: nil, payload: nil)

  @spec new(atom(), any()) :: t()
  def new(task, payload) do
    %Task{task: task, payload: payload}
  end
end

defmodule Caravan.ReserveRequest do
  alias __MODULE__

  @type t :: %ReserveRequest{
          client: atom(),
          task: Caravan.Task.t()
        }

  @enforce_keys [:client, :task]
  defstruct(client: nil, task: nil)

  @spec new(atom(), Caravan.Task.t()) :: t()
  def new(client, task) do
    %ReserveRequest{client: client, task: task}
  end
end

defmodule Caravan.ReserveResponse do
  alias __MODULE__

  @type t :: %ReserveResponse{
          client: atom(),
          error: atom() | nil,
          payload: any() | nil
        }

  @enforce_keys [:client]
  defstruct(client: nil, error: nil, payload: nil)

  @spec new(atom(), atom(), nil) :: t()
  def new(client, error, nil) when is_atom(error) do
    %ReserveResponse{client: client, error: error}
  end

  @spec new(atom(), nil, any()) :: t()
  def new(client, nil, payload) do
    %ReserveResponse{client: client, payload: payload}
  end
end
