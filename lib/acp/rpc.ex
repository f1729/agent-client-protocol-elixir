defmodule ACP.RPC do
  @moduledoc "JSON-RPC 2.0 primitives for the Agent Client Protocol."
end

# RequestId - can be null, number, or string
defmodule ACP.RequestId do
  @moduledoc "JSON-RPC Request ID. Can be null, integer, or string."

  @type t :: nil | integer() | String.t()

  def to_json(nil), do: nil
  def to_json(id) when is_integer(id), do: id
  def to_json(id) when is_binary(id), do: id

  def from_json(nil), do: nil
  def from_json(id) when is_integer(id), do: id
  def from_json(id) when is_binary(id), do: id

  def display(nil), do: "null"
  def display(id) when is_integer(id), do: Integer.to_string(id)
  def display(id) when is_binary(id), do: id
end

# Request
defmodule ACP.RPC.Request do
  @moduledoc "JSON-RPC 2.0 Request object."

  @enforce_keys [:id, :method]
  defstruct [:id, :method, :params]

  @type t :: %__MODULE__{
          id: ACP.RequestId.t(),
          method: String.t(),
          params: any() | nil
        }

  def new(id, method, params \\ nil) do
    %__MODULE__{id: id, method: method, params: params}
  end

  def to_json(%__MODULE__{} = req) do
    map = %{"id" => ACP.RequestId.to_json(req.id), "method" => req.method}
    if req.params != nil, do: Map.put(map, "params", req.params), else: map
  end

  def from_json(%{"id" => id, "method" => method} = map) do
    {:ok,
     %__MODULE__{
       id: ACP.RequestId.from_json(id),
       method: method,
       params: Map.get(map, "params")
     }}
  end
end

defimpl Jason.Encoder, for: ACP.RPC.Request do
  def encode(val, opts), do: ACP.RPC.Request.to_json(val) |> Jason.Encoder.encode(opts)
end

# Response - either result or error
defmodule ACP.RPC.Response do
  @moduledoc "JSON-RPC 2.0 Response object. Either {:ok, result} or {:error, error}."

  @type t ::
          {:result, ACP.RequestId.t(), any()}
          | {:error, ACP.RequestId.t(), ACP.Error.t()}

  def new(id, {:ok, result}), do: {:result, id, result}
  def new(id, {:error, error}), do: {:error, id, error}
  def result(id, result), do: {:result, id, result}
  def error(id, error), do: {:error, id, error}

  def to_json({:result, id, result}) do
    %{"id" => ACP.RequestId.to_json(id), "result" => result}
  end

  def to_json({:error, id, error}) do
    %{"id" => ACP.RequestId.to_json(id), "error" => ACP.Error.to_json(error)}
  end

  def from_json(%{"id" => id, "result" => result}) do
    {:ok, {:result, ACP.RequestId.from_json(id), result}}
  end

  def from_json(%{"id" => id, "error" => error}) do
    {:ok, err} = ACP.Error.from_json(error)
    {:ok, {:error, ACP.RequestId.from_json(id), err}}
  end
end

# Notification
defmodule ACP.RPC.Notification do
  @moduledoc "JSON-RPC 2.0 Notification object (no id, no response expected)."

  @enforce_keys [:method]
  defstruct [:method, :params]

  @type t :: %__MODULE__{
          method: String.t(),
          params: any() | nil
        }

  def new(method, params \\ nil) do
    %__MODULE__{method: method, params: params}
  end

  def to_json(%__MODULE__{} = notif) do
    map = %{"method" => notif.method}
    if notif.params != nil, do: Map.put(map, "params", notif.params), else: map
  end

  def from_json(%{"method" => method} = map) do
    {:ok, %__MODULE__{method: method, params: Map.get(map, "params")}}
  end
end

defimpl Jason.Encoder, for: ACP.RPC.Notification do
  def encode(val, opts), do: ACP.RPC.Notification.to_json(val) |> Jason.Encoder.encode(opts)
end

# JsonRpcMessage - wraps any message with "jsonrpc": "2.0"
defmodule ACP.RPC.JsonRpcMessage do
  @moduledoc "Wraps a JSON-RPC message with the required `jsonrpc: \"2.0\"` field."

  @enforce_keys [:message]
  defstruct [:message]

  @type t :: %__MODULE__{message: map()}

  def wrap(message) do
    %__MODULE__{message: message}
  end

  def to_json(%__MODULE__{message: message}) when is_map(message) do
    Map.put(message, "jsonrpc", "2.0")
  end

  def to_json(%__MODULE__{message: {:result, _, _} = resp}) do
    ACP.RPC.Response.to_json(resp) |> Map.put("jsonrpc", "2.0")
  end

  def to_json(%__MODULE__{message: {:error, _, _} = resp}) do
    ACP.RPC.Response.to_json(resp) |> Map.put("jsonrpc", "2.0")
  end

  def to_json(%__MODULE__{message: %_{} = struct}) do
    case struct do
      %ACP.RPC.Request{} -> ACP.RPC.Request.to_json(struct) |> Map.put("jsonrpc", "2.0")
      %ACP.RPC.Notification{} -> ACP.RPC.Notification.to_json(struct) |> Map.put("jsonrpc", "2.0")
    end
  end

  @doc "Encode to JSON string (line-delimited)."
  def encode!(%__MODULE__{} = msg) do
    Jason.encode!(to_json(msg))
  end

  @doc "Decode from a JSON string. Returns the inner message (request, response, or notification)."
  def decode(json_string) when is_binary(json_string) do
    case Jason.decode(json_string) do
      {:ok, %{"jsonrpc" => "2.0"} = map} -> classify(map)
      {:ok, _} -> {:error, :invalid_jsonrpc_version}
      {:error, reason} -> {:error, {:json_parse_error, reason}}
    end
  end

  defp classify(map) do
    cond do
      # Response (has id + result or error, no method)
      Map.has_key?(map, "id") and (Map.has_key?(map, "result") or Map.has_key?(map, "error")) and
          not Map.has_key?(map, "method") ->
        ACP.RPC.Response.from_json(map)

      # Request (has id + method)
      Map.has_key?(map, "id") and Map.has_key?(map, "method") ->
        ACP.RPC.Request.from_json(map)

      # Notification (has method, no id)
      Map.has_key?(map, "method") and not Map.has_key?(map, "id") ->
        ACP.RPC.Notification.from_json(map)

      true ->
        {:error, :unrecognized_message}
    end
  end
end

defimpl Jason.Encoder, for: ACP.RPC.JsonRpcMessage do
  def encode(val, opts), do: ACP.RPC.JsonRpcMessage.to_json(val) |> Jason.Encoder.encode(opts)
end
