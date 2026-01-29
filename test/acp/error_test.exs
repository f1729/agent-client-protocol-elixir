defmodule ACP.ErrorTest do
  use ExUnit.Case, async: true

  test "error codes" do
    assert ACP.Error.parse_error_code() == -32700
    assert ACP.Error.invalid_request_code() == -32600
    assert ACP.Error.method_not_found_code() == -32601
    assert ACP.Error.invalid_params_code() == -32602
    assert ACP.Error.internal_error_code() == -32603
    assert ACP.Error.auth_required_code() == -32000
    assert ACP.Error.resource_not_found_code() == -32002
  end

  test "convenience constructors" do
    err = ACP.Error.parse_error()
    assert err.code == -32700
    assert err.message == "Parse error"
  end

  test "to_json/from_json round-trip" do
    err = ACP.Error.new(-32600, "Invalid request")
    json = ACP.Error.to_json(err)
    assert json == %{"code" => -32600, "message" => "Invalid request"}
    assert {:ok, decoded} = ACP.Error.from_json(json)
    assert decoded.code == err.code
    assert decoded.message == err.message
  end

  test "with data" do
    err = ACP.Error.resource_not_found("file:///test")
    assert err.data == %{"uri" => "file:///test"}
    json = ACP.Error.to_json(err)
    assert json["data"] == %{"uri" => "file:///test"}
  end

  test "code_name" do
    assert ACP.Error.code_name(-32700) == :parse_error
    assert ACP.Error.code_name(-32601) == :method_not_found
    assert ACP.Error.code_name(42) == {:other, 42}
  end

  test "Jason.Encoder" do
    err = ACP.Error.internal_error()
    encoded = Jason.encode!(err)
    decoded = Jason.decode!(encoded)
    assert decoded["code"] == -32603
    assert decoded["message"] == "Internal error"
  end
end
