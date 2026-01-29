defmodule ACP.StreamMessage do
  @moduledoc """
  A message that flows through the RPC stream.

  Used for observing and debugging protocol communication.
  """

  @type direction :: :incoming | :outgoing

  @type content ::
          {:request, id :: any(), method :: String.t(), params :: any()}
          | {:response, id :: any(), result :: {:ok, any()} | {:error, ACP.Error.t()}}
          | {:notification, method :: String.t(), params :: any()}

  @type t :: %__MODULE__{
          direction: direction(),
          message: content()
        }

  @enforce_keys [:direction, :message]
  defstruct [:direction, :message]
end

defmodule ACP.StreamBroadcast do
  @moduledoc """
  A broadcast mechanism for observing RPC message streams.

  Uses a simple GenServer with subscriber tracking. Subscribers receive
  `{:acp_stream, %ACP.StreamMessage{}}` messages.
  """

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc "Subscribe the calling process to stream messages."
  def subscribe(broadcast) do
    GenServer.call(broadcast, {:subscribe, self()})
  end

  @doc "Broadcast a stream message to all subscribers."
  def broadcast(broadcast, %ACP.StreamMessage{} = message) do
    GenServer.cast(broadcast, {:broadcast, message})
  end

  @doc "Broadcast an outgoing message."
  def outgoing(broadcast, content) do
    broadcast(broadcast, %ACP.StreamMessage{direction: :outgoing, message: content})
  end

  @doc "Broadcast an incoming message."
  def incoming(broadcast, content) do
    broadcast(broadcast, %ACP.StreamMessage{direction: :incoming, message: content})
  end

  # GenServer callbacks

  @impl true
  def init(:ok) do
    {:ok, %{subscribers: []}}
  end

  @impl true
  def handle_call({:subscribe, pid}, _from, state) do
    ref = Process.monitor(pid)
    {:reply, ref, %{state | subscribers: [{pid, ref} | state.subscribers]}}
  end

  @impl true
  def handle_cast({:broadcast, message}, state) do
    for {pid, _ref} <- state.subscribers do
      send(pid, {:acp_stream, message})
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    subscribers = Enum.reject(state.subscribers, fn {_p, r} -> r == ref end)
    {:noreply, %{state | subscribers: subscribers}}
  end
end
