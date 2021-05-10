defmodule User do
  use GenServer

  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state), do: {:ok, state}

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_pid, _from, state) do
    {:reply, state[:pid], state}
  end

  def handle_call({:get_inbox, inbox_type}, _from, state) do
    {:reply, state[inbox_type], state}
  end

  def handle_cast({:read_from_notify, inbox_type}, state) do
    read(state[:pid], state[inbox_type], :rand.uniform(5))
    {:noreply, state}
  end

  def handle_cast({:set_pid, pid}, state) do
    {:noreply, Map.put_new(state, :pid, pid)}
  end

  def handle_cast({:set_inbox, common_pid, principal_pid, spam_pid}, state) do
    new_state = Map.put_new(state, :common, common_pid) |> Map.put_new(:principal, principal_pid) |> Map.put_new(:spam, spam_pid)
    {:noreply, new_state}
  end

  # def handle_cast({:receive_email, email}, state) do
  #   GenServer.cast(state[:common], {:new_email, email})
  #   {:noreply, state}
  # end

  def set_pid(pid), do: GenServer.cast(pid, {:set_pid, pid})
  def set_inbox(pid, common, principal, spam), do: GenServer.cast(pid, {:set_inbox, common, principal, spam})
  def get_state(pid), do: GenServer.call(pid, :get_state)
  def get_pid(pid), do: GenServer.call(pid, :get_pid)
  def get_common_inbox(pid), do: GenServer.call(pid, {:get_inbox, :common})
  def get_principal_inbox(pid), do: GenServer.call(pid, {:get_inbox, :principal})
  def get_spam_inbox(pid), do: GenServer.call(pid, {:get_inbox, :spam})

  def send(pid1, pid2, msg) do
    email = %{from: pid1, to: pid2, message: msg, timestamp: :os.system_time(:millisecond)}
    # Logger.debug(inspect(pid1) <> " to " <> inspect(pid2) <> ": " <> msg)

    cond do
      msg =~ ~r(^[^a-z]*$) -> GenServer.cast(get_spam_inbox(pid2), {:new_email, email})
      String.length(msg) < 50 and msg != "reply" -> GenServer.cast(get_principal_inbox(pid2), {:new_email, email})
      true -> GenServer.cast(get_common_inbox(pid2), {:new_email, email})
    end
  end

  def read(pid) do
    common_email_count = GenServer.call(User.get_common_inbox(pid), :get_unread_email_count)
    principal_email_count = GenServer.call(User.get_principal_inbox(pid), :get_unread_email_count)
    case {common_email_count, principal_email_count} do
      {0, 0} -> "No email to read"
      {0, _} -> read(pid, User.get_principal_inbox(pid), :rand.uniform(principal_email_count))
      {_, 0} -> read(pid, User.get_common_inbox(pid), :rand.uniform(common_email_count))
      {_, _} -> read(pid, User.get_principal_inbox(pid), :rand.uniform(principal_email_count))
    end
  end

  defp read(_pid, _inbox, 0) do
    :ok
  end

  defp read(pid, inbox, count) do
    email = GenServer.call(inbox, :read_email)
    if email != [] do
      if :rand.uniform(100) > 90 and email[:from] != email[:to] do
        reply_email(pid, email[:from], email, "reply")
      end
      read(pid, inbox, count - 1)
    end
  end

  def reply_email(pid1, pid2, original_email, msg) do
    email = %{from: pid1, to: pid2, message: msg, timestamp: :os.system_time(:millisecond), replying: original_email}
    # Logger.debug(inspect(pid1) <> " reply " <> inspect(pid2) <> ": " <> msg)
    cond do
      msg =~ ~r(^[^a-z]*$) -> GenServer.cast(get_spam_inbox(pid2), {:new_email, email})
      String.length(msg) < 50 and msg != "reply" -> GenServer.cast(get_principal_inbox(pid2), {:new_email, email})
      true -> GenServer.cast(get_common_inbox(pid2), {:new_email, email})
    end
  end
end
