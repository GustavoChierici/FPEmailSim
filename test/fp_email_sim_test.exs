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
    assert user == GenServer.call(user_state[:inbox], :get_user)
  end

  test "User can send an email" do
    FpEmailSim.start()
    user1 = FpEmailSim.create_user()
    user2 = FpEmailSim.create_user()
    User.send(user1, user2, "Olá, tudo bem?")
    email = User.get_inbox(user2) |> GenServer.call(:pop_email)
    assert email[:message] == "Olá, tudo bem?" and email[:from] == user1 and email[:to] == user2
  end

  test "User can read emails" do
    FpEmailSim.start()
    user1 = FpEmailSim.create_user()
    user2 = FpEmailSim.create_user()
    user3 = FpEmailSim.create_user()
    User.send(user1, user2, "Olá, tudo bem?")
    User.send(user3, user2, "Olá, tudo bem?")
    User.send(user1, user2, "Respondeeeeee")
    User.send(user3, user2, "Recebeu meu último email?")
    email_count = GenServer.call(User.get_inbox(user2), :get_email_count)
    User.read(user2)
    assert GenServer.call(User.get_inbox(user2), :get_email_count) < email_count
  end

  test "User read nothing if there is no email to read" do
    FpEmailSim.start()
    user1 = FpEmailSim.create_user()
    assert User.read(user1) == "No email to read"
  end

  test "Inbox notifies user when it has 10 emails or more" do
    FpEmailSim.start()
    user1 = FpEmailSim.create_user()
    user2 = FpEmailSim.create_user()
    User.send(user1, user2, "1")
    User.send(user1, user2, "2")
    User.send(user1, user2, "3")
    User.send(user1, user2, "4")
    User.send(user1, user2, "5")
    User.send(user1, user2, "6")
    User.send(user1, user2, "7")
    User.send(user1, user2, "8")
    User.send(user1, user2, "9")
    User.send(user1, user2, "10")
    :timer.sleep(100)
    assert GenServer.call(User.get_inbox(user2), :get_email_count) < 10
  end

  test "Multiples sends" do
    FpEmailSim.start()
    users = for _ <- 0..100, do: FpEmailSim.create_user()

    Enum.each(users, fn u -> :random.seed(:erlang.now); User.send(u, Enum.at(users, 54), "email"); :timer.sleep(50) end)
    IO.puts("end sync")
    :timer.sleep(5000)

    t = Task.async_stream(users, fn u -> :random.seed(:erlang.now); User.send(u, Enum.at(users, 54), "email"); :timer.sleep(50) end)
    Enum.to_list(t)
    assert :true
  end
end
