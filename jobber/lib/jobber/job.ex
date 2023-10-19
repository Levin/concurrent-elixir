defmodule Jobber.Job do
  use GenServer
  require Logger

  defstruct [:work, :id, :max_retries, retries: 0, status: "new"] 
  


  def init(args) do
  
    work = Keyword.fetch!(args, :work)
    id = Keyword.get(args, :id, random_job_id())
    max_retries = Keyword.get(args, :max_retries, 3)

    state = %Jobber.Job{id: id, work: work, max_retries: max_retries}
    {:ok, state, {:continue, :run}}


  end

  def handle_continue(:run, state) do

    new_state = state.work.() |> handle_job_result(state)

    if new_state.status == "errored" do
      Process.send_after(self(), :retry, 5000)
      {:noreply, new_state}
    else 
      Logger.debug("Job exiting #{state.id}")
      {:stop, :normal, new_state}
    end
  end

  def handle_info(:retry, state) do
    {:noreply, state, {:continue, :run}}
  end

  defp random_job_id(), do: :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)

  defp handle_job_result({:ok, _data}, state) do
    Logger.debug("[#{__MODULE__}]'s Job went fine !")
    %Jobber.Job{state | status: "done"}
  end


  defp handle_job_result(:error, %{status: "new"}, state) do
    Logger.debug("[#{__MODULE__}]'s job went bad, try again")
    %Jobber.Job{state | status: "errored"}
  end

  defp handle_job_result(:error, %{status: "errored"}, state) do
    Logger.warning("[#{__MODULE__}] is dead by now :(")
    new_state = %Jobber.Job{state | retries: state.retries + 1}
    cond do
      state.retries == state.max_retries -> %Jobber.Job{state | status: "failed"}
      true -> new_state
    end
  end

  


end
