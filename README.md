# Messenger

Messenger is a simple spike application for exploring OTP's `GenServer` system. It is a very simple peer-to-peer messenging system. It knowingly handles none of the issues that arise from peers dropping out or other propogation issues.

Here's how to use it:

Node 1: `$ iex --name friend1@127.0.0.1 -S mix`

```elixir
Messenger.Server.set_nickname("friend1")
# wait for other node(s) to be setup
Messenger.Server.connect(:"friend2@127.0.0.1")
Messenger.Server.message("friend2", "Hello, there!")
```

Node 2: `$ iex --name friend2@127.0.0.1 -S mix`

```elixir
Messenger.Server.set_nickname("friend2")
# connect from other nodes
Messenger.Server.message("friend1", "This is a test message")
```
