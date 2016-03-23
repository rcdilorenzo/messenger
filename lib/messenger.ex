defmodule Messenger do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Node.set_cookie(Node.self, :messenger2016)

    children = [
      worker(Messenger.Server, [])
    ]

    opts = [strategy: :one_for_one, name: Messenger.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
