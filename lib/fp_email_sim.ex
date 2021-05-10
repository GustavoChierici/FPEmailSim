defmodule FpEmailSim do
  use GenServer

  def start do
    GenServer.start_link(__MODULE__, %{users: []}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_users, _from, state) do
    {:reply, state[:users], state}
  end

  def handle_cast({:new_user, pid}, state) do
    {:noreply, %{state | users: state[:users] ++ [pid]}}
  end

  def create_user do
    {:ok, u_pid} = User.start_link()
    User.set_pid(u_pid)
    {:ok, c_pid} = Inbox.Common.create_common(u_pid)
    {:ok, p_pid} = Inbox.Principal.create_principal(u_pid)
    {:ok, s_pid} = Inbox.Spam.create_spam(u_pid)
    User.set_inbox(u_pid, c_pid, p_pid, s_pid)
    GenServer.cast(__MODULE__, {:new_user, u_pid})
    u_pid
  end
end
