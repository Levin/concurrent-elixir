defmodule SendServer do
  require Logger
  use GenServer

  def init(args) do
    IO.puts("got #{inspect args}")
    max_retries = Keyword.get(args, :max_retries, 5)
    state = %{emails: [], max_retries: max_retries}
    Process.send_after(self(), :retry, 5000)
    {:ok, state}
  end


  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:send_mail, email}, state) do
    status = 
      case Sender.send_mail(email) do
        {:ok, "email_sent"} -> "sent"
        :error -> "failed"
      end

    emails = [%{email: email, status: status, retries: 0}] ++ state.emails

    Logger.debug("[#{__MODULE__}] emails now : #{inspect emails}")

    {:noreply, %{state | emails: emails}}
  end

  def handle_info(:retry, state) do
    {failed, done} =
      Enum.split_with(
        state.emails, 
        fn item -> 
          item.status == "failed" && item.retries < state.max_entries 
      end)
      
    retried = 
      Enum.map(
        failed, 
        fn item -> 
          IO.puts("Retrying email #{item.email} ...")

          new_status = 
            case Sender.send_mail(item.email)do
              {:ok, "email sent"} -> "sent"
              :error -> "failed"
            end
          %{email: item.email, status: new_status, retries: item.retries + 1}
      end)
    Process.send_after(self(), :retry, 4999)
    {:noreply, %{state | emails: retried ++ done}}
  end


end
