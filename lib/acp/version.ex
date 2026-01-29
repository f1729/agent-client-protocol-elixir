defmodule ACP.ProtocolVersion do
  @moduledoc "Protocol version identifier. Only bumped for breaking changes."

  @type t :: non_neg_integer()

  @v0 0
  @v1 1
  @latest @v1

  def v0, do: @v0
  def v1, do: @v1
  def latest, do: @latest

  @doc "Deserialize from JSON value. Integers pass through, strings become v0."
  def from_json(value) when is_integer(value) and value >= 0, do: {:ok, value}
  def from_json(value) when is_binary(value), do: {:ok, @v0}
  def from_json(_), do: {:error, :invalid_protocol_version}
end
