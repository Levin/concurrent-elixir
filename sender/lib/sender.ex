defmodule Sender do
  
  def send_mail("müllmail.bin" = _email), do: :error

  def send_mail(email) do
    Process.sleep(3000)
    IO.puts("Email, to #{email} sent")
    {:ok, "email_sent"}
  end
  

  def notify_all(emails) do
    Sender.EmailTaskSupervisor
    |> Task.Supervisor.async_stream_nolink(emails, &send_mail/1)
    |> Enum.to_list()
  end

  def terminate(reason, _state) do
    IO.puts("Terminate with reason #{reason}")
  end
end
