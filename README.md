# Agent Client Protocol (ACP) for Elixir

Elixir implementation of the [Agent Client Protocol](https://agentclientprotocol.com/) — a standardized protocol for communication between code editors (clients) and AI coding agents over JSON-RPC 2.0.

This library is a port of the Rust [`agent-client-protocol`](https://crates.io/crates/agent-client-protocol) and [`agent-client-protocol-schema`](https://crates.io/crates/agent-client-protocol-schema) crates.

## Installation

Add `agent_client_protocol` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:agent_client_protocol, "~> 0.1.0"}
  ]
end
```

## Overview

The library has two layers:

### Schema Types

All ACP message types with JSON serialization (`to_json/1` and `from_json/1`):

- **Content** — `ContentBlock`, `TextContent`, `ImageContent`, `AudioContent`, `ResourceLink`, `EmbeddedResource`
- **Tool Calls** — `ToolCall`, `ToolCallUpdate`, `ToolKind`, `ToolCallStatus`, `ToolCallContent`
- **Plans** — `Plan`, `PlanEntry`
- **Agent Types** — `InitializeRequest/Response`, `AuthenticateRequest/Response`, `NewSessionRequest/Response`, `LoadSessionRequest/Response`, `SetSessionModeRequest/Response`, `PromptRequest/Response`, `CancelNotification`
- **Client Types** — `SessionNotification`, `SessionUpdate`, `RequestPermissionRequest/Response`, `WriteTextFileRequest/Response`, `ReadTextFileRequest/Response`, terminal operations
- **Capabilities** — `AgentCapabilities`, `ClientCapabilities`, `SessionCapabilities`, `PromptCapabilities`, `McpCapabilities`
- **MCP Servers** — `McpServer` (tagged union: Stdio, Http, Sse)
- **Extensions** — `ExtRequest`, `ExtResponse`, `ExtNotification`
- **Unstable** — `SessionModelState`, `SessionConfigOption`, `ForkSessionRequest/Response`, `ResumeSessionRequest/Response`, `ListSessionsRequest/Response`, `ConfigOptionUpdate`, `SessionInfoUpdate`, `MaybeUndefined`

### SDK Layer

- **`ACP.Agent`** — Behaviour for implementing an ACP agent with callbacks for `initialize`, `authenticate`, `new_session`, `prompt`, `cancel`, etc.
- **`ACP.Client`** — Behaviour for implementing an ACP client with callbacks for `request_permission`, `session_notification`, file/terminal operations, etc.
- **`ACP.Connection`** — GenServer for bidirectional JSON-RPC 2.0 over IO streams with request/response correlation
- **`ACP.ClientSideConnection`** / **`ACP.AgentSideConnection`** — High-level connection wrappers
- **`ACP.Side`** — Behaviour with `ClientSide`/`AgentSide` implementations for message routing and decoding
- **`ACP.StreamBroadcast`** — PubSub GenServer for observing protocol messages

## Usage

### Implementing an Agent

```elixir
defmodule MyAgent do
  use ACP.Agent

  @impl true
  def initialize(request) do
    {:ok, ACP.InitializeResponse.new(ACP.ProtocolVersion.v1())}
  end

  @impl true
  def authenticate(_request) do
    {:ok, ACP.AuthenticateResponse.new()}
  end

  @impl true
  def new_session(request) do
    {:ok, ACP.NewSessionResponse.new("session-#{System.unique_integer()}")}
  end

  @impl true
  def prompt(request) do
    # Process the prompt and send session updates...
    {:ok, ACP.PromptResponse.new(:end_turn)}
  end

  @impl true
  def cancel(_notification), do: :ok
end
```

### Implementing a Client

```elixir
defmodule MyClient do
  use ACP.Client

  @impl true
  def request_permission(request) do
    # Present permission options to the user...
    option = hd(request.options)
    {:ok, ACP.RequestPermissionResponse.new({:selected, ACP.SelectedPermissionOutcome.new(option.option_id)})}
  end

  @impl true
  def session_notification(notification) do
    IO.inspect(notification.update, label: "Session update")
    :ok
  end
end
```

### Working with Types

```elixir
# Create and serialize a content block
text = ACP.TextContent.new("Hello, world!")
json = ACP.ContentBlock.to_json({:text, text})
# => %{"type" => "text", "text" => "Hello, world!"}

# Deserialize
{:ok, {:text, decoded}} = ACP.ContentBlock.from_json(json)

# Session updates
update = {:agent_message_chunk, ACP.ContentChunk.new({:text, ACP.TextContent.new("Hi")})}
json = ACP.SessionUpdate.to_json(update)

# JSON-RPC messages
request = %ACP.RPC.Request{id: 1, method: "initialize", params: %{"protocolVersion" => 1}}
encoded = ACP.RPC.JsonRpcMessage.encode!(request)
```

## Protocol Compatibility

This library targets ACP schema version 0.10.6. All stable types are fully implemented. Unstable features (session fork/resume/list, model selection, config options) are included but may change with future protocol versions.

## License

MIT
