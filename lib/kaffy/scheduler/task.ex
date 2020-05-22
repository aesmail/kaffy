defmodule Kaffy.Scheduler.Task do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(task) do
    task =
      Map.merge(task, %{
        successful: 0,
        failure: 0,
        failure_value: nil,
        last_successful: nil,
        last_failure: nil,
        current_value: Map.get(task, :initial_value),
        started_at: DateTime.utc_now()
      })

    schedule_work(task)
    {:ok, task}
  end

  @impl true
  def handle_info(:perform_task, task) do
    task =
      case task.action.(task.current_value) do
        {:ok, value} ->
          task
          |> Map.put(:current_value, value)
          |> Map.put(:successful, task.successful + 1)
          |> Map.put(:last_successful, DateTime.utc_now())

        {:error, invalid_value} ->
          task
          |> Map.put(:failure, task.failure + 1)
          |> Map.put(:failure_value, invalid_value)
          |> Map.put(:last_failure, DateTime.utc_now())
      end

    # Reschedule once more
    schedule_work(task)
    {:noreply, task}
  end

  @impl true
  def handle_call(:info, _, task) do
    {:reply, task, task}
  end

  defp schedule_work(task) do
    # In seconds
    Process.send_after(self(), :perform_task, task.every * 1000)
  end
end
