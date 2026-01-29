defmodule ACP.MaybeUndefined do
  @moduledoc """
  A three-state value type: `:undefined`, `nil` (null), or `{:value, term}`.

  Similar to `Option<T>`, but distinguishes between a missing field (undefined)
  and an explicitly null field. This is important for partial update semantics
  where omitting a field means "don't change" and setting it to null means "clear".

  ## JSON Serialization

  - `:undefined` → field is omitted from JSON output
  - `nil` → `null`
  - `{:value, x}` → the JSON encoding of `x`

  ## Examples

      iex> ACP.MaybeUndefined.is_undefined(:undefined)
      true

      iex> ACP.MaybeUndefined.is_undefined(nil)
      false

      iex> ACP.MaybeUndefined.is_undefined({:value, "hello"})
      false
  """

  @type t(value) :: :undefined | nil | {:value, value}

  @doc "Returns true if the value is undefined."
  def is_undefined(:undefined), do: true
  def is_undefined(_), do: false

  @doc "Returns true if the value is null."
  def is_null(nil), do: true
  def is_null(_), do: false

  @doc "Returns true if the value contains a value."
  def is_value({:value, _}), do: true
  def is_value(_), do: false

  @doc "Returns the inner value, or nil if undefined or null."
  def value({:value, v}), do: v
  def value(_), do: nil

  @doc "Converts to `Option<Option<T>>` equivalent: nil | {:some, nil} | {:some, value}."
  def as_opt_ref(:undefined), do: nil
  def as_opt_ref(nil), do: {:some, nil}
  def as_opt_ref({:value, v}), do: {:some, v}

  @doc "Converts from a nested option back to MaybeUndefined."
  def from_opt(nil), do: :undefined
  def from_opt({:some, nil}), do: nil
  def from_opt({:some, v}), do: {:value, v}

  @doc "Maps a function over the value, preserving undefined/null."
  def map_value(:undefined, _fun), do: :undefined
  def map_value(nil, _fun), do: nil
  def map_value({:value, v}, fun), do: {:value, fun.(v)}

  @doc """
  Updates a target value if the MaybeUndefined is not undefined.

  - `:undefined` → returns the current value unchanged
  - `nil` → returns nil (clear)
  - `{:value, v}` → returns v (set)
  """
  def update_to(:undefined, current), do: current
  def update_to(nil, _current), do: nil
  def update_to({:value, v}, _current), do: v

  @doc """
  Encodes a MaybeUndefined value for JSON serialization.
  Returns `{:skip}` for undefined (caller should omit the field),
  `nil` for null, or the value itself.
  """
  def to_json(:undefined), do: {:skip}
  def to_json(nil), do: nil
  def to_json({:value, v}), do: v

  @doc """
  Decodes a MaybeUndefined value from JSON deserialization.
  Call with `:missing` if the key was not present, or the value if it was.
  """
  def from_json(:missing), do: :undefined
  def from_json(nil), do: nil
  def from_json(v), do: {:value, v}
end
