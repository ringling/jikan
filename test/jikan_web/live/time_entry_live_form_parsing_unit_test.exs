defmodule JikanWeb.TimeEntryLive.FormParsingUnitTest do
  use ExUnit.Case, async: true

  alias Jikan.Timezone

  # Test the timezone conversion logic directly
  describe "Time format parsing and timezone conversion" do
    test "Time.from_iso8601 handles HH:MM:SS format" do
      assert {:ok, ~T[14:30:45]} = Time.from_iso8601("14:30:45")
    end

    test "Time.from_iso8601 handles HH:MM format with :00 appended" do
      assert {:ok, ~T[14:30:00]} = Time.from_iso8601("14:30:00")
    end

    test "Time.from_iso8601 fails on HH:MM format without seconds" do
      assert {:error, :invalid_format} = Time.from_iso8601("14:30")
    end

    test "Time.from_iso8601 fails on invalid format HH:MM:SS:00" do
      assert {:error, :invalid_format} = Time.from_iso8601("14:30:45:00")
    end

    test "timezone conversion works correctly for CET winter time" do
      date = ~D[2026-03-13]  # Winter date (CET = UTC+1)
      local_time = ~T[07:14:18]  # CET time
      
      utc_time = Timezone.time_to_utc(local_time, date)
      
      # 07:14:18 CET should become 06:14:18 UTC
      assert utc_time == ~T[06:14:18]
    end

    test "timezone conversion works correctly for CEST summer time" do
      date = ~D[2026-07-15]  # Summer date (CEST = UTC+2)  
      local_time = ~T[09:30:45]  # CEST time
      
      utc_time = Timezone.time_to_utc(local_time, date)
      
      # 09:30:45 CEST should become 07:30:45 UTC
      assert utc_time == ~T[07:30:45]
    end

    test "timezone conversion handles midnight edge case" do
      date = ~D[2026-03-13]  # Winter date (CET = UTC+1)
      local_time = ~T[00:30:15]  # Just after midnight CET
      
      utc_time = Timezone.time_to_utc(local_time, date)
      
      # 00:30:15 CET should become 23:30:15 UTC (previous day)
      assert utc_time == ~T[23:30:15]
    end

    test "robust time parsing logic simulation" do
      # Simulate the logic in maybe_convert_time_to_utc/3
      
      test_cases = [
        # Format: {input_string, expected_parse_result}
        {"14:30:45", {:ok, ~T[14:30:45]}},  # HH:MM:SS format
        {"14:30", {:ok, ~T[14:30:00]}},     # HH:MM format (with :00 added)
        {"00:00:00", {:ok, ~T[00:00:00]}},  # Midnight with seconds
        {"23:59", {:ok, ~T[23:59:00]}},     # Just before midnight  
        {"invalid", {:error, :invalid_time}} # Invalid format
      ]

      for {input, expected} <- test_cases do
        # This simulates our robust parsing logic
        actual = 
          cond do
            # Try parsing as-is first (handles HH:MM:SS format)
            match?({:ok, _}, Time.from_iso8601(input)) ->
              Time.from_iso8601(input)
            
            # Try adding :00 for HH:MM format  
            match?({:ok, _}, Time.from_iso8601(input <> ":00")) ->
              Time.from_iso8601(input <> ":00")
            
            # Fallback: return error
            true ->
              {:error, :invalid_time}
          end
        
        assert actual == expected, "Failed for input: #{input}"
      end
    end

    test "complete timezone conversion workflow simulation" do
      # Simulate converting "07:14:18" CET to UTC for winter date
      time_string = "07:14:18"
      date = ~D[2026-03-13]
      
      # Parse time (should work with our robust logic)
      {:ok, local_time} = 
        cond do
          match?({:ok, _}, Time.from_iso8601(time_string)) ->
            Time.from_iso8601(time_string)
          match?({:ok, _}, Time.from_iso8601(time_string <> ":00")) ->
            Time.from_iso8601(time_string <> ":00")
          true ->
            {:error, :invalid_time}
        end
      
      # Convert to UTC
      utc_time = Timezone.time_to_utc(local_time, date)
      utc_string = Time.to_string(utc_time)
      
      # Verify result
      assert local_time == ~T[07:14:18]  # Parsed correctly
      assert utc_time == ~T[06:14:18]    # Converted correctly (CET - 1 hour)
      assert utc_string == "06:14:18"    # Formatted correctly for storage
    end
  end
end