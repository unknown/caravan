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

  @spec new(atom(), atom(), %Caravan.Requirements{}) :: %ScheduleRequest{
          id: atom(),
          task: atom(),
          requirements: %Caravan.Requirements{}
        }
  def new(id, task, requirements) do
    %ScheduleRequest{id: id, task: task, requirements: requirements}
  end
end

defmodule Caravan.ScheduleResponse do
  alias __MODULE__

  defstruct(worker_id: nil)

  @spec new(atom()) :: %ScheduleResponse{worker_id: atom()}
  def new(worker_id) do
    %ScheduleResponse{worker_id: worker_id}
  end
end

defmodule Caravan.ReleaseRequest do
  alias __MODULE__

  defstruct(id: nil, reserved: nil)

  @spec new(atom(), atom()) :: %ReleaseRequest{id: atom(), reserved: atom()}
  def new(id, reserved) do
    %ReleaseRequest{id: id, reserved: reserved}
  end
end

defmodule Caravan.ReserveRequest do
  alias __MODULE__

  defstruct(task: nil)

  @spec new(atom()) :: %ReserveRequest{task: atom()}
  def new(task) do
    %ReserveRequest{task: task}
  end
end

defmodule Caravan.ReserveResponse do
  alias __MODULE__

  defstruct(error: nil)

  @spec new(atom() | nil) :: %ReserveResponse{error: atom() | nil}
  def new(error) do
    %ReserveResponse{error: error}
  end
end
