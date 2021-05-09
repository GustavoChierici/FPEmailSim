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

  def handle_call(:get_inbox, _from, state) do
    {:reply, state[:inbox], state}
  end

  def handle_cast(:read_from_notify, state) do
    read(state[:pid], state[:inbox], :rand.uniform(5))
    {:noreply, state}
  end

  def handle_cast({:set_pid, pid}, state) do
    {:noreply, Map.put_new(state, :pid, pid)}
  end

  def handle_cast({:set_inbox, pid}, state) do
    {:noreply, Map.put_new(state, :inbox, pid)}
  end

  def handle_cast({:receive_email, email}, state) do
    GenServer.cast(state[:inbox], {:new_email, email})
    {:noreply, state}
  end

  def set_pid(pid), do: GenServer.cast(pid, {:set_pid, pid})
  def set_inbox(pid, inbox), do: GenServer.cast(pid, {:set_inbox, inbox})
  def get_state(pid), do: GenServer.call(pid, :get_state)
  def get_pid(pid), do: GenServer.call(pid, :get_pid)
  def get_inbox(pid), do: GenServer.call(pid, :get_inbox)

  def send(pid1, pid2, msg) do
    email = %{from: pid1, to: pid2, message: msg}
    # Logger.debug(inspect(pid1) <> " to " <> inspect(pid2) <> " " <> msg)
    GenServer.cast(get_inbox(pid2), {:new_email, email})
  end

  def read(pid) do
    email_count = GenServer.call(User.get_inbox(pid), :get_email_count)
    case email_count do
      0 -> "No email to read"
      _ -> read(pid, User.get_inbox(pid), :rand.uniform(email_count))
    end
  end

  defp read(_pid, _inbox, 0) do
    :ok
  end

  defp read(pid, inbox, count) do
    GenServer.call(inbox, :pop_email)
    read(pid, inbox, (count - 1))
  end
end
