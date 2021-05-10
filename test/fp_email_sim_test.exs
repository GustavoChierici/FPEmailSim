defmodule FpEmailSimTest do
  use ExUnit.Case
  doctest FpEmailSim

  test "User can be created" do
    FpEmailSim.start()
    user = FpEmailSim.create_user()
    users = GenServer.call(FpEmailSim, :get_users)
    assert Enum.find_value(users, fn x -> x == user end)
  end

  test "Multiple users can be created" do
    FpEmailSim.start()
    user1 = FpEmailSim.create_user()
    user2 = FpEmailSim.create_user()
    user3 = FpEmailSim.create_user()
    users = [user1, user2, user3]
    users_in_server = GenServer.call(FpEmailSim, :get_users)
    assert users == users_in_server
  end

  test "User has an inbox" do
    FpEmailSim.start()
    user = FpEmailSim.create_user()
    user_state = User.get_state(user)
    assert user == GenServer.call(user_state[:common], :get_user)
  end

  test "User can send an email" do
    FpEmailSim.start()
    user1 = FpEmailSim.create_user()
    user2 = FpEmailSim.create_user()
    User.send(user1, user2, "Olá, tudo bem?")
    email = User.get_principal_inbox(user2) |> GenServer.call(:pop_email)
    assert email[:message] == "Olá, tudo bem?" and email[:from] == user1 and email[:to] == user2
  end

  test "User can read emails" do
    FpEmailSim.start()
    user1 = FpEmailSim.create_user()
    user2 = FpEmailSim.create_user()
    user3 = FpEmailSim.create_user()
    User.send(user1, user2, "Olá, tudo bem?aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    User.send(user3, user2, "Olá, tudo bem?bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    User.send(user1, user2, "Respondeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
    User.send(user3, user2, "Recebeu meu último email?aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    email_count = GenServer.call(User.get_common_inbox(user2), :get_unread_email_count)
    User.read(user2)
    assert GenServer.call(User.get_common_inbox(user2), :get_unread_email_count) < email_count
  end

  test "User read nothing if there is no email to read" do
    FpEmailSim.start()
    user1 = FpEmailSim.create_user()
    assert User.read(user1) == "No email to read"
  end

  test "Common inbox notifies user when it has 10 emails or more" do
    FpEmailSim.start()
    user1 = FpEmailSim.create_user()
    user2 = FpEmailSim.create_user()
    User.send(user1, user2, "ummmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm")
    User.send(user1, user2, "doiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiissssssssssssssssssssssss")
    User.send(user1, user2, "tressssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss")
    User.send(user1, user2, "quatroooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo")
    User.send(user1, user2, "cincooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo")
    User.send(user1, user2, "seissssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss")
    User.send(user1, user2, "seteeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
    User.send(user1, user2, "oitooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo")
    User.send(user1, user2, "noveeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
    User.send(user1, user2, "deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeezzzzzzzzzzzz")
    :timer.sleep(100)
    assert GenServer.call(User.get_common_inbox(user2), :get_unread_email_count) < 10
  end

  test "Multiples sends" do
    FpEmailSim.start()
    users = for _ <- 0..1000, do: FpEmailSim.create_user()

    IO.puts("start sync")
    Enum.each(users, fn u ->
      :random.seed(:erlang.now())
      User.send(u, Enum.random(users), "email")
      :timer.sleep(10)
    end)

    IO.puts("end sync")
    :timer.sleep(500)
    IO.puts("start async")

    t =
      Task.async_stream(users, fn u ->
        :random.seed(:erlang.now())
        User.send(u, Enum.random(users), "email")
        :timer.sleep(10)
      end)

    Enum.to_list(t)

    IO.puts("end async")
    assert true
  end

  test "Spam autodelete after 5 seconds" do
    FpEmailSim.start()
    user1 = FpEmailSim.create_user()
    user2 = FpEmailSim.create_user()
    User.send(user1, user2, "SPAM")
    :timer.sleep(5005)
    spam = User.get_spam_inbox(user2)
    assert GenServer.call(spam, :get_email_count) == 0
  end
end
