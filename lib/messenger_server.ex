defmodule Messenger.Server do
  use GenServer

  @name __MODULE__

  defstruct name: nil, nickname: nil, peers: %{}

  def start_link(name \\ @name) do
    GenServer.start_link(__MODULE__, %Messenger.Server{name: name}, [name: name])
  end

  def init(state) do
    {:ok, state}
  end

  def connect(pid_or_node), do: connect(@name, pid_or_node)

  def connect(server, pid) when is_pid(pid) do
    join_servers(server, [pid])
  end

  def connect(server, node) do
    IO.puts "Connecting to #{node} from #{Node.self}"
    case Node.connect(node) do
      true ->
        pid = Process.whereis(server)
        Node.spawn(node, __MODULE__, :connect, [pid])
      reason ->
        IO.puts "Could not connect to server: #{reason}"
        :error
    end
  end

  # Niceties

  def join_servers(server \\ @name, other_servers) do
    GenServer.call(server, {:join_servers, other_servers})
  end

  def set_nickname(server \\ @name, nickname) do
    GenServer.call(server, {:set_nickname, nickname})
  end

  def nickname(server \\ @name) do
    GenServer.call(server, :nickname)
  end

  def nicknames(server \\ @name) do
    GenServer.call(server, :nicknames)
  end

  def message(server \\ @name, nickname, message) do
    GenServer.cast(server, {:send, nickname, message})
  end

  # Callbacks

  def handle_call({:join_servers, _servers}, _from, state = %{nickname: nil}) do
    {:reply, {:error, :nonickname}, state}
  end

  def handle_call({:join_servers, servers}, _from, state = %{nickname: nickname}) do
    peers = Enum.reduce(servers, %{}, fn (server, acc) ->
      case GenServer.call(server, {:join_from, self(), nickname}) do
        {:error, :nonickname} -> acc
        {:nickname, nickname, server} -> Map.put(acc, nickname, server)
      end
    end)
    {:reply, {:ok, "#{Enum.count(peers)} connected"}, %{state | peers: peers}}
  end

  def handle_call({:set_nickname, nickname}, _from, state) do
    {:reply, {:ok, nickname}, %{state | nickname: nickname}}
  end

  def handle_call({:join_from, server, nickname}, _from, state = %{nickname: nil}) do
    {:reply, {:error, :nonickname}, state}
  end

  def handle_call({:join_from, server, from_nickname}, _from, state = %{nickname: nickname}) do
    new_state = put_in(state.peers[from_nickname], server)
    {:reply, {:nickname, nickname, self()}, new_state}
  end

  def handle_call(:nicknames, _from, state = %{peers: peers}) do
    {:reply, {:ok, Map.keys(peers)}, state}
  end

  def handle_call(:nickname, _from, state = %{nickname: nil}) do
    {:reply, {:error, :nonickname}, state}
  end

  def handle_call(:nickname, _from, state = %{nickname: nickname}) do
    {:reply, {:ok, nickname}, state}
  end

  def handle_cast({:send, to_nickname, message}, state = %{nickname: nickname, peers: peers}) do
    unless is_nil(peers[to_nickname]) do
      GenServer.cast(peers[to_nickname], {:receive, nickname, message})
    end
    {:noreply, state}
  end

  def handle_cast({:receive, from_nickname, message}, state) do
    IO.puts "[#{from_nickname}] #{message}"
    {:noreply, state}
  end
end
