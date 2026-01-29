defmodule ACP.ProtocolVersionTest do
  use ExUnit.Case, async: true

  test "v0 is 0" do
    assert ACP.ProtocolVersion.v0() == 0
  end

  test "v1 is 1" do
    assert ACP.ProtocolVersion.v1() == 1
  end

  test "latest is v1" do
    assert ACP.ProtocolVersion.latest() == ACP.ProtocolVersion.v1()
  end

  test "from_json integer passes through" do
    assert ACP.ProtocolVersion.from_json(1) == {:ok, 1}
    assert ACP.ProtocolVersion.from_json(0) == {:ok, 0}
  end

  test "from_json string becomes v0" do
    assert ACP.ProtocolVersion.from_json("anything") == {:ok, 0}
  end

  test "from_json invalid" do
    assert ACP.ProtocolVersion.from_json(-1) == {:error, :invalid_protocol_version}
  end
end
