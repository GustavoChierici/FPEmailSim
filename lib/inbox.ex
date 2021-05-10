defmodule Inbox do
  defmacro __using__(opts) do
    minimum_to_notify = Keyword.get(opts, :minimum_to_notify, 10)
    notify = Keyword.get(opts, :notify, true)
    inbox_type = Keyword.get(opts, :inbox_type, :common)

    quote do
      use GenServer
      require Logger

      def start_link(user, mail_box_type_module) do
        GenServer.start_link(mail_box_type_module, %{user: user, emails: [], unread_emails: []})
      end

      def init(state) do
        {:ok, state}
      end

      def handle_cast({:new_email, email}, state) do
        GenServer.cast(self(), {:notify, unquote(notify)})
        {:noreply, %{state | emails: state[:emails] ++ [email], unread_emails: state[:unread_emails] ++ [email]}}
      end

      def handle_cast({:notify, true}, state) do
        if length(state[:unread_emails]) >= unquote(minimum_to_notify) do
          GenServer.cast(state[:user], {:read_from_notify, unquote(inbox_type)})
        end

        {:noreply, state}
      end

      def handle_cast({:notify, _}, state) do
        current_time = :os.system_time(:millisecond)
        :timer.sleep(5000)
        [_ | remaing_unread_emails] = state[:unread_emails] #Enum.filter(state[:unread_emails], fn email -> current_time <= 30000 + email[:timestamp] end)
        [_ | remaing_emails] = state[:emails] #Enum.filter(state[:emails], fn email -> current_time <= 30000 + email[:timestamp] end)
        new_state = %{state | emails: remaing_emails, unread_emails: remaing_unread_emails}
        {:noreply, new_state}
      end

      def handle_call(:pop_email, _from, state) do
        [email | tail] = state[:emails]
        new_state = %{state | emails: tail}
        {:reply, email, new_state}
      end

      def handle_call(:read_email, _from, state) do
        if state[:unread_emails] != [] do
          [email | tail] = state[:unread_emails]
          # Logger.debug(inspect(state[:user]) <> " read " <> email[:message])
          new_state = %{state | unread_emails: tail}
          {:reply, email, new_state}
        else
          {:reply, [], state}
        end
      end


      def handle_call(:get_user, _from, state) do
        {:reply, state[:user], state}
      end

      def handle_call(:get_email_count, _from, state) do
        {:reply, length(state[:emails]), state}
      end

      def handle_call(:get_unread_email_count, _from, state) do
        {:reply, length(state[:unread_emails]), state}
      end
    end
  end
end
