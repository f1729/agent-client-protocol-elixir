defmodule ACP.UnstableTest do
  use ExUnit.Case, async: true

  # --- MaybeUndefined ---

  describe "MaybeUndefined" do
    test "is_undefined/is_null/is_value" do
      assert ACP.MaybeUndefined.is_undefined(:undefined)
      refute ACP.MaybeUndefined.is_undefined(nil)
      refute ACP.MaybeUndefined.is_undefined({:value, 42})

      refute ACP.MaybeUndefined.is_null(:undefined)
      assert ACP.MaybeUndefined.is_null(nil)
      refute ACP.MaybeUndefined.is_null({:value, 42})

      refute ACP.MaybeUndefined.is_value(:undefined)
      refute ACP.MaybeUndefined.is_value(nil)
      assert ACP.MaybeUndefined.is_value({:value, 42})
    end

    test "value/1" do
      assert ACP.MaybeUndefined.value({:value, 42}) == 42
      assert ACP.MaybeUndefined.value(:undefined) == nil
      assert ACP.MaybeUndefined.value(nil) == nil
    end

    test "map_value/2" do
      assert ACP.MaybeUndefined.map_value({:value, 5}, &(&1 * 2)) == {:value, 10}
      assert ACP.MaybeUndefined.map_value(:undefined, &(&1 * 2)) == :undefined
      assert ACP.MaybeUndefined.map_value(nil, &(&1 * 2)) == nil
    end

    test "update_to/2" do
      assert ACP.MaybeUndefined.update_to({:value, 10}, 5) == 10
      assert ACP.MaybeUndefined.update_to(nil, 5) == nil
      assert ACP.MaybeUndefined.update_to(:undefined, 5) == 5
    end

    test "to_json/from_json round trip" do
      assert ACP.MaybeUndefined.to_json(:undefined) == {:skip}
      assert ACP.MaybeUndefined.to_json(nil) == nil
      assert ACP.MaybeUndefined.to_json({:value, "hello"}) == "hello"

      assert ACP.MaybeUndefined.from_json(:missing) == :undefined
      assert ACP.MaybeUndefined.from_json(nil) == nil
      assert ACP.MaybeUndefined.from_json("hello") == {:value, "hello"}
    end
  end

  # --- SessionModelState ---

  describe "SessionModelState" do
    test "round trip serialization" do
      model =
        ACP.SessionModelState.new("opus-4", [
          ACP.ModelInfo.new("opus-4", "Claude Opus 4"),
          %ACP.ModelInfo{model_id: "sonnet-4", name: "Claude Sonnet 4", description: "Fast model"}
        ])

      json = ACP.SessionModelState.to_json(model)
      assert json["currentModelId"] == "opus-4"
      assert length(json["availableModels"]) == 2
      assert hd(json["availableModels"])["modelId"] == "opus-4"

      {:ok, decoded} = ACP.SessionModelState.from_json(json)
      assert decoded.current_model_id == "opus-4"
      assert length(decoded.available_models) == 2
      assert Enum.at(decoded.available_models, 1).description == "Fast model"
    end
  end

  describe "ModelInfo" do
    test "serialization with optional description" do
      info = ACP.ModelInfo.new("test-model", "Test Model")
      json = ACP.ModelInfo.to_json(info)
      assert json == %{"modelId" => "test-model", "name" => "Test Model"}

      info_with_desc = %{info | description: "A test model"}
      json2 = ACP.ModelInfo.to_json(info_with_desc)
      assert json2["description"] == "A test model"
    end
  end

  describe "SetSessionModelRequest" do
    test "round trip" do
      req = ACP.SetSessionModelRequest.new("sess-1", "opus-4")
      json = ACP.SetSessionModelRequest.to_json(req)
      assert json == %{"sessionId" => "sess-1", "modelId" => "opus-4"}

      {:ok, decoded} = ACP.SetSessionModelRequest.from_json(json)
      assert decoded.session_id == "sess-1"
      assert decoded.model_id == "opus-4"
    end
  end

  describe "SetSessionModelResponse" do
    test "empty response" do
      resp = ACP.SetSessionModelResponse.new()
      json = ACP.SetSessionModelResponse.to_json(resp)
      assert json == %{}

      {:ok, decoded} = ACP.SetSessionModelResponse.from_json(json)
      assert decoded.meta == nil
    end
  end

  # --- Session Config Option Types ---

  describe "SessionConfigOption" do
    test "select option round trip" do
      opt =
        ACP.SessionConfigOption.select(
          "model-selector",
          "Model",
          "opus-4",
          {:ungrouped,
           [
             ACP.SessionConfigSelectOption.new("opus-4", "Claude Opus 4"),
             ACP.SessionConfigSelectOption.new("sonnet-4", "Claude Sonnet 4")
           ]}
        )

      json = ACP.SessionConfigOption.to_json(opt)
      assert json["id"] == "model-selector"
      assert json["name"] == "Model"
      assert json["type"] == "select"
      assert json["currentValue"] == "opus-4"
      assert length(json["options"]) == 2

      {:ok, decoded} = ACP.SessionConfigOption.from_json(json)
      assert decoded.id == "model-selector"
      assert {:select, select} = decoded.kind
      assert select.current_value == "opus-4"
      assert length(elem(select.options, 1)) == 2
    end

    test "select with grouped options" do
      opt =
        ACP.SessionConfigOption.select(
          "model-selector",
          "Model",
          "opus-4",
          {:grouped,
           [
             ACP.SessionConfigSelectGroup.new("premium", "Premium Models", [
               ACP.SessionConfigSelectOption.new("opus-4", "Claude Opus 4")
             ]),
             ACP.SessionConfigSelectGroup.new("standard", "Standard Models", [
               ACP.SessionConfigSelectOption.new("sonnet-4", "Claude Sonnet 4")
             ])
           ]}
        )

      json = ACP.SessionConfigOption.to_json(opt)
      assert length(json["options"]) == 2
      assert hd(json["options"])["group"] == "premium"

      {:ok, decoded} = ACP.SessionConfigOption.from_json(json)
      {:select, select} = decoded.kind
      {:grouped, groups} = select.options
      assert length(groups) == 2
      assert hd(groups).group == "premium"
    end

    test "with category" do
      opt = %{
        ACP.SessionConfigOption.select("m", "M", "v1", {:ungrouped, []})
        | category: :model
      }

      json = ACP.SessionConfigOption.to_json(opt)
      assert json["category"] == "model"

      {:ok, decoded} = ACP.SessionConfigOption.from_json(json)
      assert decoded.category == :model
    end
  end

  describe "SessionConfigOptionCategory" do
    test "all variants" do
      assert ACP.SessionConfigOptionCategory.to_json(:mode) == "mode"
      assert ACP.SessionConfigOptionCategory.to_json(:model) == "model"
      assert ACP.SessionConfigOptionCategory.to_json(:thought_level) == "thought_level"
      assert ACP.SessionConfigOptionCategory.to_json(:other) == "other"

      assert ACP.SessionConfigOptionCategory.from_json("mode") == :mode
      assert ACP.SessionConfigOptionCategory.from_json("model") == :model
      assert ACP.SessionConfigOptionCategory.from_json("thought_level") == :thought_level
      assert ACP.SessionConfigOptionCategory.from_json("unknown") == :other
    end
  end

  describe "SetSessionConfigOptionRequest" do
    test "round trip" do
      req = ACP.SetSessionConfigOptionRequest.new("sess-1", "model-selector", "opus-4")
      json = ACP.SetSessionConfigOptionRequest.to_json(req)

      assert json == %{
               "sessionId" => "sess-1",
               "configId" => "model-selector",
               "value" => "opus-4"
             }

      {:ok, decoded} = ACP.SetSessionConfigOptionRequest.from_json(json)
      assert decoded.config_id == "model-selector"
      assert decoded.value == "opus-4"
    end
  end

  describe "SetSessionConfigOptionResponse" do
    test "round trip" do
      resp =
        ACP.SetSessionConfigOptionResponse.new([
          ACP.SessionConfigOption.select("m", "Model", "v1", {:ungrouped, []})
        ])

      json = ACP.SetSessionConfigOptionResponse.to_json(resp)
      assert length(json["configOptions"]) == 1

      {:ok, decoded} = ACP.SetSessionConfigOptionResponse.from_json(json)
      assert length(decoded.config_options) == 1
    end
  end

  # --- Fork Session ---

  describe "ForkSessionRequest" do
    test "round trip" do
      req = ACP.ForkSessionRequest.new("sess-1", "/home/user")
      json = ACP.ForkSessionRequest.to_json(req)
      assert json == %{"sessionId" => "sess-1", "cwd" => "/home/user"}

      {:ok, decoded} = ACP.ForkSessionRequest.from_json(json)
      assert decoded.session_id == "sess-1"
      assert decoded.cwd == "/home/user"
      assert decoded.mcp_servers == []
    end
  end

  describe "ForkSessionResponse" do
    test "minimal round trip" do
      resp = ACP.ForkSessionResponse.new("new-sess")
      json = ACP.ForkSessionResponse.to_json(resp)
      assert json == %{"sessionId" => "new-sess"}

      {:ok, decoded} = ACP.ForkSessionResponse.from_json(json)
      assert decoded.session_id == "new-sess"
      assert decoded.modes == nil
      assert decoded.models == nil
      assert decoded.config_options == nil
    end

    test "with models and config_options" do
      resp = %ACP.ForkSessionResponse{
        session_id: "new-sess",
        models: ACP.SessionModelState.new("opus", [ACP.ModelInfo.new("opus", "Opus")])
      }

      json = ACP.ForkSessionResponse.to_json(resp)
      assert json["models"]["currentModelId"] == "opus"

      {:ok, decoded} = ACP.ForkSessionResponse.from_json(json)
      assert decoded.models.current_model_id == "opus"
    end
  end

  # --- Resume Session ---

  describe "ResumeSessionRequest" do
    test "round trip" do
      req = ACP.ResumeSessionRequest.new("sess-1", "/home/user")
      json = ACP.ResumeSessionRequest.to_json(req)
      assert json == %{"sessionId" => "sess-1", "cwd" => "/home/user"}

      {:ok, decoded} = ACP.ResumeSessionRequest.from_json(json)
      assert decoded.session_id == "sess-1"
    end
  end

  describe "ResumeSessionResponse" do
    test "empty round trip" do
      resp = ACP.ResumeSessionResponse.new()
      json = ACP.ResumeSessionResponse.to_json(resp)
      assert json == %{}

      {:ok, decoded} = ACP.ResumeSessionResponse.from_json(json)
      assert decoded.modes == nil
    end
  end

  # --- List Sessions ---

  describe "ListSessionsRequest" do
    test "empty round trip" do
      req = ACP.ListSessionsRequest.new()
      json = ACP.ListSessionsRequest.to_json(req)
      assert json == %{}

      {:ok, decoded} = ACP.ListSessionsRequest.from_json(json)
      assert decoded.cwd == nil
      assert decoded.cursor == nil
    end

    test "with cwd and cursor" do
      req = %ACP.ListSessionsRequest{cwd: "/home", cursor: "abc123"}
      json = ACP.ListSessionsRequest.to_json(req)
      assert json == %{"cwd" => "/home", "cursor" => "abc123"}
    end
  end

  describe "ListSessionsResponse" do
    test "round trip" do
      resp =
        ACP.ListSessionsResponse.new([
          ACP.SessionInfo.new("sess-1", "/home"),
          %ACP.SessionInfo{
            session_id: "sess-2",
            cwd: "/tmp",
            title: "My Session",
            updated_at: "2025-01-01T00:00:00Z"
          }
        ])

      json = ACP.ListSessionsResponse.to_json(resp)
      assert length(json["sessions"]) == 2
      assert Enum.at(json["sessions"], 1)["title"] == "My Session"

      {:ok, decoded} = ACP.ListSessionsResponse.from_json(json)
      assert length(decoded.sessions) == 2
      assert Enum.at(decoded.sessions, 1).title == "My Session"
    end

    test "with next_cursor" do
      resp = %{ACP.ListSessionsResponse.new([]) | next_cursor: "page2"}
      json = ACP.ListSessionsResponse.to_json(resp)
      assert json["nextCursor"] == "page2"
    end
  end

  # --- Session Capabilities (Unstable) ---

  describe "SessionCapabilities with unstable fields" do
    test "with list/fork/resume capabilities" do
      caps = %ACP.SessionCapabilities{
        modes: true,
        list: ACP.SessionListCapabilities.new(),
        fork: ACP.SessionForkCapabilities.new(),
        resume: ACP.SessionResumeCapabilities.new()
      }

      json = ACP.SessionCapabilities.to_json(caps)
      assert json["modes"] == true
      assert json["list"] == %{}
      assert json["fork"] == %{}
      assert json["resume"] == %{}

      {:ok, decoded} = ACP.SessionCapabilities.from_json(json)
      assert decoded.modes == true
      assert decoded.list != nil
      assert decoded.fork != nil
      assert decoded.resume != nil
    end
  end

  # --- ConfigOptionUpdate ---

  describe "ConfigOptionUpdate" do
    test "round trip" do
      update =
        ACP.ConfigOptionUpdate.new([
          ACP.SessionConfigOption.select("m", "Model", "v1", {:ungrouped, []})
        ])

      json = ACP.ConfigOptionUpdate.to_json(update)
      assert length(json["configOptions"]) == 1

      {:ok, decoded} = ACP.ConfigOptionUpdate.from_json(json)
      assert length(decoded.config_options) == 1
    end
  end

  # --- SessionInfoUpdate ---

  describe "SessionInfoUpdate" do
    test "empty (all undefined)" do
      update = ACP.SessionInfoUpdate.new()
      json = ACP.SessionInfoUpdate.to_json(update)
      assert json == %{}
    end

    test "with title set to value" do
      update = %ACP.SessionInfoUpdate{title: {:value, "My Session"}}
      json = ACP.SessionInfoUpdate.to_json(update)
      assert json == %{"title" => "My Session"}
    end

    test "with title set to null (clear)" do
      update = %ACP.SessionInfoUpdate{title: nil}
      json = ACP.SessionInfoUpdate.to_json(update)
      assert json == %{"title" => nil}
    end

    test "round trip with values" do
      update = %ACP.SessionInfoUpdate{
        title: {:value, "Test"},
        updated_at: {:value, "2025-01-01T00:00:00Z"}
      }

      json = ACP.SessionInfoUpdate.to_json(update)
      assert json["title"] == "Test"
      assert json["updatedAt"] == "2025-01-01T00:00:00Z"

      {:ok, decoded} = ACP.SessionInfoUpdate.from_json(json)
      assert decoded.title == {:value, "Test"}
      assert decoded.updated_at == {:value, "2025-01-01T00:00:00Z"}
    end

    test "round trip with null values" do
      json = %{"title" => nil, "updatedAt" => nil}
      {:ok, decoded} = ACP.SessionInfoUpdate.from_json(json)
      assert decoded.title == nil
      assert decoded.updated_at == nil
    end

    test "round trip with missing fields" do
      {:ok, decoded} = ACP.SessionInfoUpdate.from_json(%{})
      assert decoded.title == :undefined
      assert decoded.updated_at == :undefined
    end
  end

  # --- SessionUpdate with new variants ---

  describe "SessionUpdate unstable variants" do
    test "config_option_update round trip" do
      update =
        {:config_option_update,
         ACP.ConfigOptionUpdate.new([
           ACP.SessionConfigOption.select("m", "Model", "v1", {:ungrouped, []})
         ])}

      json = ACP.SessionUpdate.to_json(update)
      assert json["sessionUpdate"] == "config_option_update"
      assert length(json["configOptions"]) == 1

      decoded = ACP.SessionUpdate.from_json(json)
      assert {:config_option_update, cou} = decoded
      assert length(cou.config_options) == 1
    end

    test "session_info_update round trip" do
      update = {:session_info_update, %ACP.SessionInfoUpdate{title: {:value, "Updated"}}}

      json = ACP.SessionUpdate.to_json(update)
      assert json["sessionUpdate"] == "session_info_update"
      assert json["title"] == "Updated"

      decoded = ACP.SessionUpdate.from_json(json)
      assert {:session_info_update, siu} = decoded
      assert siu.title == {:value, "Updated"}
    end
  end

  # --- Side decoder for unstable methods ---

  describe "AgentSide unstable decode_request" do
    test "session/list" do
      {:ok, {:list_sessions, req}} =
        ACP.AgentSide.decode_request("session/list", %{})

      assert %ACP.ListSessionsRequest{} = req
    end

    test "session/fork" do
      {:ok, {:fork_session, req}} =
        ACP.AgentSide.decode_request("session/fork", %{"sessionId" => "s1", "cwd" => "/tmp"})

      assert req.session_id == "s1"
    end

    test "session/resume" do
      {:ok, {:resume_session, req}} =
        ACP.AgentSide.decode_request("session/resume", %{"sessionId" => "s1", "cwd" => "/tmp"})

      assert req.session_id == "s1"
    end

    test "session/set_config_option" do
      {:ok, {:set_session_config_option, req}} =
        ACP.AgentSide.decode_request("session/set_config_option", %{
          "sessionId" => "s1",
          "configId" => "model",
          "value" => "opus"
        })

      assert req.config_id == "model"
    end

    test "session/set_model" do
      {:ok, {:set_session_model, req}} =
        ACP.AgentSide.decode_request("session/set_model", %{
          "sessionId" => "s1",
          "modelId" => "opus-4"
        })

      assert req.model_id == "opus-4"
    end
  end

  # --- Method Names ---

  describe "MethodNames unstable" do
    test "unstable method names" do
      assert ACP.MethodNames.session_fork() == "session/fork"
      assert ACP.MethodNames.session_resume() == "session/resume"
      assert ACP.MethodNames.session_list() == "session/list"
      assert ACP.MethodNames.session_set_config_option() == "session/set_config_option"
      assert ACP.MethodNames.session_set_model() == "session/set_model"
    end

    test "agent_methods includes unstable" do
      methods = ACP.MethodNames.agent_methods()
      assert "session/fork" in methods
      assert "session/resume" in methods
      assert "session/list" in methods
      assert "session/set_config_option" in methods
      assert "session/set_model" in methods
    end
  end

  # --- Dispatch Enums ---

  describe "ClientRequest unstable variants" do
    test "method names" do
      assert ACP.ClientRequest.method({:list_sessions, nil}) == "session/list"
      assert ACP.ClientRequest.method({:fork_session, nil}) == "session/fork"
      assert ACP.ClientRequest.method({:resume_session, nil}) == "session/resume"

      assert ACP.ClientRequest.method({:set_session_config_option, nil}) ==
               "session/set_config_option"

      assert ACP.ClientRequest.method({:set_session_model, nil}) == "session/set_model"
    end
  end

  # --- NewSessionResponse / LoadSessionResponse with unstable fields ---

  describe "NewSessionResponse with unstable fields" do
    test "with models" do
      resp = %ACP.NewSessionResponse{
        session_id: "s1",
        models: ACP.SessionModelState.new("opus", [ACP.ModelInfo.new("opus", "Opus")])
      }

      json = ACP.NewSessionResponse.to_json(resp)
      assert json["models"]["currentModelId"] == "opus"

      {:ok, decoded} = ACP.NewSessionResponse.from_json(json)
      assert decoded.models.current_model_id == "opus"
    end

    test "with config_options" do
      resp = %ACP.NewSessionResponse{
        session_id: "s1",
        config_options: [ACP.SessionConfigOption.select("m", "M", "v", {:ungrouped, []})]
      }

      json = ACP.NewSessionResponse.to_json(resp)
      assert length(json["configOptions"]) == 1

      {:ok, decoded} = ACP.NewSessionResponse.from_json(json)
      assert length(decoded.config_options) == 1
    end
  end

  describe "LoadSessionResponse with unstable fields" do
    test "with models and config_options" do
      resp = %ACP.LoadSessionResponse{
        models: ACP.SessionModelState.new("opus", [ACP.ModelInfo.new("opus", "Opus")]),
        config_options: [ACP.SessionConfigOption.select("m", "M", "v", {:ungrouped, []})]
      }

      json = ACP.LoadSessionResponse.to_json(resp)
      assert json["models"]["currentModelId"] == "opus"
      assert length(json["configOptions"]) == 1

      {:ok, decoded} = ACP.LoadSessionResponse.from_json(json)
      assert decoded.models.current_model_id == "opus"
      assert length(decoded.config_options) == 1
    end
  end
end
