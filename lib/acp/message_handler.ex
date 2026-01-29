defmodule ACP.MessageHandler do
  @moduledoc """
  Behaviour for handling incoming JSON-RPC requests and notifications.

  Implementations route decoded requests to the appropriate Agent or Client callbacks.
  """

  @doc "Handle an incoming request and return a response."
  @callback handle_request(request :: any()) :: {:ok, any()} | {:error, ACP.Error.t()}

  @doc "Handle an incoming notification."
  @callback handle_notification(notification :: any()) :: :ok | {:error, ACP.Error.t()}
end
