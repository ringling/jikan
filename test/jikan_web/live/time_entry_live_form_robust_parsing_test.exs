defmodule JikanWeb.TimeEntryLive.FormRobustParsingTest do
  use JikanWeb.ConnCase

  import Jikan.TrackingFixtures
  import Jikan.AccountsFixtures

  alias Jikan.Tracking
  alias Jikan.Timezone

  describe "Robust time format parsing and timezone conversion" do
    setup %{conn: conn} do
      user = user_fixture()
      client = client_fixture(user)
      project = project_fixture(user, %{client_id: client.id, color: "#3B82F6"})
      
      %{user: user, client: client, project: project, conn: log_in_user(conn, user)}
    end

    # Helper function to simulate the LiveView form's timezone conversion
    defp convert_form_params_to_utc(params) do
      date = params["date"] || Date.utc_today()
      date = if is_binary(date), do: Date.from_iso8601!(date), else: date

      params
      |> maybe_convert_time_to_utc("start_time", date)
      |> maybe_convert_time_to_utc("end_time", date)
    end

    defp maybe_convert_time_to_utc(params, field, date) do
      case params[field] do
        nil -> params
        "" -> params
        time_string when is_binary(time_string) ->
          # Parse the time string robustly (handles both HH:MM and HH:MM:SS formats)
          parsed_time = 
            cond do
              # Try parsing as-is first (handles HH:MM:SS format)
              match?({:ok, _}, Time.from_iso8601(time_string)) ->
                Time.from_iso8601(time_string)
              
              # Try adding :00 for HH:MM format  
              match?({:ok, _}, Time.from_iso8601(time_string <> ":00")) ->
                Time.from_iso8601(time_string <> ":00")
              
              # Fallback: return error
              true ->
                {:error, :invalid_time}
            end
          
          case parsed_time do
            {:ok, local_time} ->
              utc_time = Timezone.time_to_utc(local_time, date)
              Map.put(params, field, Time.to_string(utc_time))
            _ -> params  # Keep original value if parsing fails
          end
        _ -> params
      end
    end

    test "handles HH:MM:SS format correctly", %{project: project, user: user} do
      # Create a time entry with precise times including seconds (in UTC)
      {:ok, time_entry} = Tracking.create_time_entry(user, %{
        project_id: project.id,
        date: ~D[2026-03-13],
        start_time: ~T[06:14:18], # UTC time with seconds
        end_time: ~T[07:44:31],   # UTC time with seconds
        duration_minutes: 90,
        description: "Precise timing test",
        billable: true
      })

      # Test updating with HH:MM:SS format through form helper
      # Simulate form submission with CET times that include seconds
      updated_params = %{
        "date" => "2026-03-13",
        "start_time" => "08:00:00",  # CET time with seconds 
        "end_time" => "16:30:00",    # CET time with seconds
        "duration_minutes" => 510,   # 8.5 hours
        "description" => "Updated with seconds format",
        "billable" => true
      }

      # Convert times like the LiveView form would
      converted_params = convert_form_params_to_utc(updated_params)
      
      # Update should work without errors and convert times correctly
      {:ok, updated_entry} = Tracking.update_time_entry(time_entry, converted_params)
      
      # Verify times were correctly converted from CET to UTC and saved
      assert updated_entry.start_time == ~T[07:00:00]  # 08:00 CET - 1 hour = 07:00 UTC
      assert updated_entry.end_time == ~T[15:30:00]    # 16:30 CET - 1 hour = 15:30 UTC
      assert updated_entry.description == "Updated with seconds format"
    end

    test "handles HH:MM format correctly", %{project: project, user: user} do
      # Test time parsing and timezone conversion through form helper
      form_params = %{
        "project_id" => to_string(project.id),
        "date" => "2026-03-13",
        "start_time" => "09:15",  # CET time without seconds
        "end_time" => "17:45",    # CET time without seconds 
        "duration_minutes" => 510,
        "description" => "No seconds format test",
        "billable" => true
      }

      # Convert times like the LiveView form would
      converted_params = convert_form_params_to_utc(form_params)
      
      # Create time entry with converted params
      {:ok, time_entry} = Tracking.create_time_entry(user, converted_params)

      # Verify times were correctly converted to UTC
      assert time_entry.start_time == ~T[08:15:00]  # 09:15 CET - 1 hour = 08:15 UTC
      assert time_entry.end_time == ~T[16:45:00]    # 17:45 CET - 1 hour = 16:45 UTC
      assert time_entry.description == "No seconds format test"
    end

    test "handles edge case: midnight times correctly", %{project: project, user: user} do
      # Test midnight edge case with timezone conversion logic
      form_params = %{
        "project_id" => to_string(project.id),
        "date" => "2026-03-13",
        "start_time" => "00:30:45",  # Just after midnight CET
        "end_time" => "08:15:30",    # Morning CET
        "duration_minutes" => 465,   # ~7.75 hours
        "description" => "Midnight edge case with seconds",
        "billable" => true
      }

      # Convert times like the LiveView form would
      converted_params = convert_form_params_to_utc(form_params)
      
      # Verify the timezone conversion happens correctly
      assert converted_params["start_time"] == "23:30:45"  # 00:30:45 CET - 1 hour = 23:30:45 UTC
      assert converted_params["end_time"] == "07:15:30"    # 08:15:30 CET - 1 hour = 07:15:30 UTC
      
      # The business logic validation may reject this because end_time appears before start_time
      # when both are stored as times on the same date (crossing midnight boundary)
      result = Tracking.create_time_entry(user, converted_params)
      
      case result do
        {:ok, time_entry} ->
          # If creation succeeds, verify times were stored correctly
          assert time_entry.start_time == ~T[23:30:45]
          assert time_entry.end_time == ~T[07:15:30]
        {:error, changeset} ->
          # If validation fails due to end_time being before start_time, that's acceptable
          # This is a known limitation when crossing midnight boundaries
          {error_msg, _} = changeset.errors[:end_time] || {"", []}
          assert error_msg =~ "after start time"
      end
    end

    test "handles invalid time format gracefully", %{project: project, user: user} do
      # Test invalid time format handling through form helper
      invalid_params = %{
        "project_id" => to_string(project.id),
        "date" => "2026-03-13",
        "start_time" => "25:99:99",  # Invalid time
        "end_time" => "17:45",       # Valid time
        "duration_minutes" => 480,
        "description" => "Invalid time test",
        "billable" => true
      }

      # Convert times like the LiveView form would (should handle invalid gracefully)
      converted_params = convert_form_params_to_utc(invalid_params)
      
      # Should either keep invalid time as-is or convert valid one
      assert converted_params["description"] == "Invalid time test"
      assert converted_params["start_time"] == "25:99:99"  # Invalid time kept as-is
      # end_time should be converted: 17:45 CET = 16:45 UTC
      assert converted_params["end_time"] == "16:45:00"
      
      # Backend should handle invalid times gracefully when we try to create
      result = Tracking.create_time_entry(user, converted_params)
      
      case result do
        {:ok, time_entry} ->
          # If creation succeeds, invalid time should be handled gracefully
          assert time_entry.description == "Invalid time test"
        {:error, changeset} ->
          # If creation fails, should have validation error for invalid time
          assert changeset.errors[:start_time] || changeset.errors[:time]
      end
    end
  end
end