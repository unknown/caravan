defmodule Caravan.Requirements do
  alias __MODULE__

  defstruct(points: nil)

  @spec new(non_neg_integer()) :: %Requirements{points: non_neg_integer()}
  def new(
        # fake resource
        points
      ) do
    %Requirements{points: points}
  end
end

defmodule Caravan.ScheduleRequest do
  alias __MODULE__

  defstruct(id: nil, task: nil, requirements: nil)

  @spec new(non_neg_integer(), atom(), %Caravan.Requirements{}) :: %ScheduleRequest{
          id: non_neg_integer(),
          task: atom(),
          requirements: %Caravan.Requirements{}
        }
  def new(id, task, requirements) do
    %ScheduleRequest{id: id, task: task, requirements: requirements}
  end
end

defmodule Caravan.ScheduleResponse do
  alias __MODULE__

  defstruct(id: nil)

  @spec new(non_neg_integer()) :: %ScheduleResponse{id: non_neg_integer()}
  def new(id) do
    %ScheduleResponse{id: id}
  end
end

defmodule Caravan.ReleaseRequest do
  alias __MODULE__

  defstruct(id: nil)

  @spec new(non_neg_integer()) :: %ReleaseRequest{id: non_neg_integer()}
  def new(id) do
    %ReleaseRequest{id: id}
  end
end

defmodule Caravan.ReserveRequest do
  alias __MODULE__

  defstruct(id: nil, task: nil)

  @spec new(non_neg_integer(), atom()) :: %ReserveRequest{id: non_neg_integer(), task: atom()}
  def new(id, task) do
    %ReserveRequest{id: id, task: task}
  end
end

defmodule Caravan.ReserveResponse do
  alias __MODULE__

  defstruct(id: nil, error: nil)

  @spec new(non_neg_integer(), atom() | nil) :: %ReserveResponse{
          id: non_neg_integer(),
          error: atom() | nil
        }
  def new(id, error) do
    %ReserveResponse{id: id, error: error}
  end
end
