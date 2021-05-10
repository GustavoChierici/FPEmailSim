defmodule Inbox.Common do
  use Inbox, minimum_to_notify: 10

  def create_common(user) do
    start_link(user, __MODULE__)
  end
end
