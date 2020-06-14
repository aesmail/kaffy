defmodule Kaffy.Tasks do
  def collect_tasks() do
    Kaffy.Utils.get_task_modules()
    |> Enum.map(fn m ->
      m.__info__(:functions)
      |> Enum.filter(fn {f, _} -> String.starts_with?(to_string(f), "task_") end)
      |> Enum.map(fn {f, _} -> apply(m, f, []) end)
    end)
    |> List.flatten()
  end

  def tasks_info() do
    children = DynamicSupervisor.which_children(KaffyTaskSupervisor)

    Enum.map(children, fn {_, p, _, _} ->
      GenServer.call(p, :info)
    end)
  end
end
