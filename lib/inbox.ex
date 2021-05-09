defmodule Inbox do
  use GenServer

  require Logger

  def start_link(user) do
    GenServer.start_link(__MODULE__, %{user: user, emails: []})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:new_email, email}, state) do
    GenServer.cast(self(), :notify)
    {:noreply, %{state | emails: state[:emails] ++ [email]}}
  end

  def handle_call(:pop_email, _from, state) do
    [email | tail] = state[:emails]
    Logger.debug(inspect(state[:user]) <> " read " <> email[:message])
    new_state = %{state | emails: tail}
    {:reply, email, new_state}
  end

  def handle_call(:get_user, _from, state) do
    {:reply, state[:user], state}
  end

  def handle_call(:get_email_count, _from, state) do
    {:reply, length(state[:emails]), state}
  end

  def handle_cast(:notify, state) do
    if length(state[:emails]) >= 9 do
      GenServer.cast(state[:user], :read_from_notify)
    end
    {:noreply, state}
  end
end
