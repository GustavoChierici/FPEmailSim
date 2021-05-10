defmodule Inbox.Principal do
  use Inbox, minimum_to_notify: 1, inbox_type: :principal

  def create_principal(user) do
    start_link(user, __MODULE__)
  end
end
