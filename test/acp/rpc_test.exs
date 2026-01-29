defmodule ACP.RPCTest do
  use ExUnit.Case, async: true

  test "RequestId display" do
    assert ACP.RequestId.display(nil) == "null"
    assert ACP.RequestId.display(1) == "1"
    assert ACP.RequestId.display(-1) == "-1"
    assert ACP.RequestId.display("abc") == "abc"
  end

  test "RequestId round-trip" do
    assert ACP.RequestId.from_json(nil) == nil
    assert ACP.RequestId.from_json(42) == 42
    assert ACP.RequestId.from_json("test") == "test"
  end

  test "Request to_json/from_json" do
    req = ACP.RPC.Request.new(1, "initialize", %{"protocolVersion" => 1})
    json = ACP.RPC.Request.to_json(req)
    assert json == %{"id" => 1, "method" => "initialize", "params" => %{"protocolVersion" => 1}}
    {:ok, decoded} = ACP.RPC.Request.from_json(json)
    assert decoded.id == 1
    assert decoded.method == "initialize"
  end

  test "Request without params" do
    req = ACP.RPC.Request.new(1, "test")
    json = ACP.RPC.Request.to_json(req)
    refute Map.has_key?(json, "params")
  end

  test "Response result" do
    resp = ACP.RPC.Response.result(1, %{"value" => true})
    json = ACP.RPC.Response.to_json(resp)
    assert json == %{"id" => 1, "result" => %{"value" => true}}
    {:ok, decoded} = ACP.RPC.Response.from_json(json)
    assert decoded == {:result, 1, %{"value" => true}}
  end

  test "Response error" do
    err = ACP.Error.method_not_found()
    resp = ACP.RPC.Response.error(1, err)
    json = ACP.RPC.Response.to_json(resp)
    assert json["id"] == 1
    assert json["error"]["code"] == -32601
    {:ok, decoded} = ACP.RPC.Response.from_json(json)
    assert {:error, 1, decoded_err} = decoded
    assert decoded_err.code == -32601
  end

  test "Notification to_json/from_json" do
    notif = ACP.RPC.Notification.new("session/update", %{"sessionId" => "abc"})
    json = ACP.RPC.Notification.to_json(notif)
    assert json == %{"method" => "session/update", "params" => %{"sessionId" => "abc"}}
    {:ok, decoded} = ACP.RPC.Notification.from_json(json)
    assert decoded.method == "session/update"
  end

  test "JsonRpcMessage wrap and encode" do
    req = ACP.RPC.Request.new(1, "initialize")
    msg = ACP.RPC.JsonRpcMessage.wrap(ACP.RPC.Request.to_json(req))
    json = ACP.RPC.JsonRpcMessage.to_json(msg)
    assert json["jsonrpc"] == "2.0"
    assert json["id"] == 1
    assert json["method"] == "initialize"
  end

  test "JsonRpcMessage decode request" do
    json_str = ~s({"jsonrpc":"2.0","id":1,"method":"test","params":{"key":"val"}})
    {:ok, decoded} = ACP.RPC.JsonRpcMessage.decode(json_str)
    assert %ACP.RPC.Request{id: 1, method: "test"} = decoded
  end

  test "JsonRpcMessage decode response" do
    json_str = ~s({"jsonrpc":"2.0","id":1,"result":{"ok":true}})
    {:ok, decoded} = ACP.RPC.JsonRpcMessage.decode(json_str)
    assert {:result, 1, %{"ok" => true}} = decoded
  end

  test "JsonRpcMessage decode notification" do
    json_str = ~s({"jsonrpc":"2.0","method":"cancel","params":{"sessionId":"s1"}})
    {:ok, decoded} = ACP.RPC.JsonRpcMessage.decode(json_str)
    assert %ACP.RPC.Notification{method: "cancel"} = decoded
  end

  test "JsonRpcMessage decode invalid version" do
    json_str = ~s({"jsonrpc":"1.0","method":"test"})
    assert {:error, :invalid_jsonrpc_version} = ACP.RPC.JsonRpcMessage.decode(json_str)
  end
end
