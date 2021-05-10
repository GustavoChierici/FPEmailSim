defmodule Inbox.Spam do
  use Inbox, notify: false

  def create_spam(user) do
    start_link(user, __MODULE__)
  end


end
