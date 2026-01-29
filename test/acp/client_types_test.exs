defmodule ACP.ClientTypesTest do
  use ExUnit.Case, async: true

  test "SessionNotification to_json/from_json with agent_message_chunk" do
    chunk = ACP.ContentChunk.new({:text, %ACP.TextContent{text: "Hello"}})
    update = {:agent_message_chunk, chunk}
    notif = ACP.SessionNotification.new("s1", update)
    json = ACP.SessionNotification.to_json(notif)
    assert json["sessionId"] == "s1"
    assert json["update"]["sessionUpdate"] == "agent_message_chunk"
    {:ok, decoded} = ACP.SessionNotification.from_json(json)
    assert decoded.session_id == "s1"
    assert {:agent_message_chunk, _} = decoded.update
  end

  test "SessionUpdate plan" do
    plan = ACP.Plan.new([ACP.PlanEntry.new("Do thing", :high, :pending)])
    update = {:plan, plan}
    json = ACP.SessionUpdate.to_json(update)
    assert json["sessionUpdate"] == "plan"
    assert length(json["entries"]) == 1
  end

  test "SessionUpdate current_mode_update" do
    cmu = ACP.CurrentModeUpdate.new("architect")
    json = ACP.SessionUpdate.to_json({:current_mode_update, cmu})
    assert json["sessionUpdate"] == "current_mode_update"
    assert json["currentModeId"] == "architect"
  end

  test "PermissionOption to_json/from_json" do
    opt = ACP.PermissionOption.new("allow-once", "Allow Once", :allow_once)
    json = ACP.PermissionOption.to_json(opt)
    assert json["optionId"] == "allow-once"
    assert json["kind"] == "allow_once"
    {:ok, decoded} = ACP.PermissionOption.from_json(json)
    assert decoded.kind == :allow_once
  end

  test "RequestPermissionOutcome cancelled" do
    json = ACP.RequestPermissionOutcome.to_json(:cancelled)
    assert json == %{"outcome" => "cancelled"}
    assert :cancelled = ACP.RequestPermissionOutcome.from_json(json)
  end

  test "RequestPermissionOutcome selected" do
    outcome = {:selected, ACP.SelectedPermissionOutcome.new("opt-1")}
    json = ACP.RequestPermissionOutcome.to_json(outcome)
    assert json["outcome"] == "selected"
    assert json["optionId"] == "opt-1"
    decoded = ACP.RequestPermissionOutcome.from_json(json)
    assert {:selected, s} = decoded
    assert s.option_id == "opt-1"
  end

  test "WriteTextFileRequest to_json/from_json" do
    req = ACP.WriteTextFileRequest.new("s1", "/tmp/test.txt", "hello world")
    json = ACP.WriteTextFileRequest.to_json(req)
    assert json["path"] == "/tmp/test.txt"
    assert json["content"] == "hello world"
    {:ok, decoded} = ACP.WriteTextFileRequest.from_json(json)
    assert decoded.content == "hello world"
  end

  test "ReadTextFileRequest with line/limit" do
    req = %ACP.ReadTextFileRequest{session_id: "s1", path: "/test", line: 10, limit: 50}
    json = ACP.ReadTextFileRequest.to_json(req)
    assert json["line"] == 10
    assert json["limit"] == 50
  end

  test "CreateTerminalRequest to_json/from_json" do
    req = ACP.CreateTerminalRequest.new("s1", "echo")
    json = ACP.CreateTerminalRequest.to_json(req)
    assert json["command"] == "echo"
    {:ok, decoded} = ACP.CreateTerminalRequest.from_json(json)
    assert decoded.command == "echo"
  end

  test "TerminalExitStatus to_json/from_json" do
    status = ACP.TerminalExitStatus.new(0)
    json = ACP.TerminalExitStatus.to_json(status)
    assert json["exitCode"] == 0
    {:ok, decoded} = ACP.TerminalExitStatus.from_json(json)
    assert decoded.exit_code == 0
  end

  test "ClientCapabilities defaults" do
    caps = ACP.ClientCapabilities.new()
    assert caps.terminal == false
    assert caps.file_system == nil
  end

  test "FileSystemCapability to_json/from_json" do
    fs = %ACP.FileSystemCapability{write_text_file: true, read_text_file: true}
    json = ACP.FileSystemCapability.to_json(fs)
    assert json["writeTextFile"] == true
    {:ok, decoded} = ACP.FileSystemCapability.from_json(json)
    assert decoded.write_text_file == true
  end

  test "AvailableCommand to_json/from_json" do
    cmd = ACP.AvailableCommand.new("commit", "Commit changes")
    json = ACP.AvailableCommand.to_json(cmd)
    assert json["name"] == "commit"
    {:ok, decoded} = ACP.AvailableCommand.from_json(json)
    assert decoded.description == "Commit changes"
  end
end
