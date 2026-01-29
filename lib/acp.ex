defmodule ACP do
  @moduledoc """
  Agent Client Protocol (ACP) for Elixir.

  A standardized protocol for communication between code editors (clients)
  and AI coding agents. This library provides the schema types, JSON-RPC
  primitives, behaviours, and connection management for building ACP-compliant
  clients and agents.

  ## Schema Types

  - `ACP.ProtocolVersion` - Protocol version negotiation
  - `ACP.Error` - JSON-RPC error codes and constructors
  - `ACP.ContentBlock` - Content blocks (text, image, audio, resource)
  - `ACP.Plan` / `ACP.PlanEntry` - Execution plans
  - `ACP.ToolCall` / `ACP.ToolCallUpdate` - Tool call tracking

  ## Agent Types

  - `ACP.InitializeRequest` / `ACP.InitializeResponse`
  - `ACP.AuthenticateRequest` / `ACP.AuthenticateResponse`
  - `ACP.NewSessionRequest` / `ACP.NewSessionResponse`
  - `ACP.LoadSessionRequest` / `ACP.LoadSessionResponse`
  - `ACP.SetSessionModeRequest` / `ACP.SetSessionModeResponse`
  - `ACP.PromptRequest` / `ACP.PromptResponse`
  - `ACP.CancelNotification`
  - `ACP.AgentCapabilities` / `ACP.SessionCapabilities`

  ## Client Types

  - `ACP.SessionNotification` / `ACP.SessionUpdate`
  - `ACP.RequestPermissionRequest` / `ACP.RequestPermissionResponse`
  - `ACP.WriteTextFileRequest` / `ACP.ReadTextFileRequest`
  - `ACP.CreateTerminalRequest` / `ACP.TerminalOutputRequest`
  - `ACP.ClientCapabilities`

  ## Behaviours

  - `ACP.Agent` - Agent behaviour (initialize, prompt, cancel, etc.)
  - `ACP.Client` - Client behaviour (request_permission, session_notification, etc.)

  ## Connections

  - `ACP.Connection` - Low-level JSON-RPC GenServer
  - `ACP.ClientSideConnection` - Client-side connection wrapper
  - `ACP.AgentSideConnection` - Agent-side connection wrapper

  ## RPC

  - `ACP.RPC.Request` / `ACP.RPC.Response` / `ACP.RPC.Notification`
  - `ACP.RPC.JsonRpcMessage` - JSON-RPC 2.0 message wrapper
  - `ACP.ClientSide` / `ACP.AgentSide` - Side implementations for message decoding

  ## Stream Broadcast

  - `ACP.StreamBroadcast` - PubSub for observing RPC message streams
  - `ACP.StreamMessage` - Stream message struct
  """

  @type session_id :: String.t()
end
