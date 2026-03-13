defmodule Jikan.TimezoneTest do
  use ExUnit.Case, async: true
  alias Jikan.Timezone

  describe "get_timezone/0" do
    test "returns configured timezone" do
      assert Timezone.get_timezone() == "Europe/Berlin"
    end
  end

  describe "to_local/1" do
    test "converts UTC DateTime to local timezone" do
      {:ok, utc_dt} = DateTime.new(~D[2026-03-13], ~T[12:00:00], "Etc/UTC")
      local_dt = Timezone.to_local(utc_dt)
      
      assert local_dt.time_zone == "Europe/Berlin"
      # In March, Berlin is UTC+1 (CET)
      assert local_dt.hour == 13
      assert local_dt.minute == 0
      assert local_dt.second == 0
    end

    test "handles summer time correctly" do
      # Test with a summer date (CEST = UTC+2)
      {:ok, summer_utc} = DateTime.new(~D[2026-07-15], ~T[14:00:00], "Etc/UTC")
      summer_local = Timezone.to_local(summer_utc)
      
      assert summer_local.time_zone == "Europe/Berlin"
      # In July, Berlin is UTC+2 (CEST)
      assert summer_local.hour == 16
    end

    test "handles winter time correctly" do
      # Test with a winter date (CET = UTC+1)
      {:ok, winter_utc} = DateTime.new(~D[2026-01-15], ~T[14:00:00], "Etc/UTC")
      winter_local = Timezone.to_local(winter_utc)
      
      assert winter_local.time_zone == "Europe/Berlin"
      # In January, Berlin is UTC+1 (CET)
      assert winter_local.hour == 15
    end
  end

  describe "to_utc/1" do
    test "converts local DateTime to UTC" do
      {:ok, local_dt} = DateTime.new(~D[2026-03-13], ~T[13:00:00], "Europe/Berlin")
      utc_dt = Timezone.to_utc(local_dt)
      
      assert utc_dt.time_zone == "Etc/UTC"
      # 13:00 CET = 12:00 UTC
      assert utc_dt.hour == 12
      assert utc_dt.minute == 0
      assert utc_dt.second == 0
    end
  end

  describe "time_to_local/2" do
    test "converts UTC Time to local DateTime for today" do
      utc_time = ~T[10:30:45]
      date = ~D[2026-03-13]
      
      local_dt = Timezone.time_to_local(utc_time, date)
      
      assert local_dt.time_zone == "Europe/Berlin"
      # 10:30 UTC = 11:30 CET
      assert local_dt.hour == 11
      assert local_dt.minute == 30
      assert local_dt.second == 45
    end

    test "uses current date when date not provided" do
      utc_time = ~T[15:00:00]
      local_dt = Timezone.time_to_local(utc_time)
      
      assert local_dt.time_zone == "Europe/Berlin"
      # Should be 1 hour ahead in winter, 2 hours in summer
      assert local_dt.hour in [16, 17]
    end
  end

  describe "time_to_utc/2" do
    test "converts local Time to UTC" do
      local_time = ~T[14:30:00]
      date = ~D[2026-03-13]
      
      utc_time = Timezone.time_to_utc(local_time, date)
      
      # 14:30 CET = 13:30 UTC
      assert utc_time.hour == 13
      assert utc_time.minute == 30
      assert utc_time.second == 0
    end

    test "handles midnight edge case" do
      local_time = ~T[00:30:00]
      date = ~D[2026-03-13]
      
      utc_time = Timezone.time_to_utc(local_time, date)
      
      # 00:30 CET = 23:30 UTC (previous day)
      assert utc_time.hour == 23
      assert utc_time.minute == 30
    end
  end

  describe "local_today/0" do
    test "returns current date in local timezone" do
      local_date = Timezone.local_today()
      
      # Should be a Date struct
      assert %Date{} = local_date
      
      # Compare with UTC date - might be different near midnight
      utc_today = Date.utc_today()
      date_diff = Date.diff(local_date, utc_today)
      
      # Should be same day or at most 1 day different
      assert date_diff in [-1, 0, 1]
    end
  end

  describe "local_now/0" do
    test "returns current time in local timezone" do
      local_time = Timezone.local_now()
      
      # Should be a Time struct
      assert %Time{} = local_time
      
      # Should have valid hour, minute, second
      assert local_time.hour in 0..23
      assert local_time.minute in 0..59
      assert local_time.second in 0..59
    end
  end

  describe "format_local/2" do
    test "formats DateTime in local timezone with default format" do
      {:ok, utc_dt} = DateTime.new(~D[2026-03-13], ~T[12:30:45], "Etc/UTC")
      
      formatted = Timezone.format_local(utc_dt)
      
      # Default format: "%Y-%m-%d %H:%M:%S"
      # 12:30:45 UTC = 13:30:45 CET
      assert formatted == "2026-03-13 13:30:45"
    end

    test "formats DateTime with custom format" do
      {:ok, utc_dt} = DateTime.new(~D[2026-03-13], ~T[12:30:45], "Etc/UTC")
      
      formatted = Timezone.format_local(utc_dt, "%d.%m.%Y %H:%M")
      
      # 12:30 UTC = 13:30 CET
      assert formatted == "13.03.2026 13:30"
    end

    test "includes timezone abbreviation when requested" do
      {:ok, utc_dt} = DateTime.new(~D[2026-03-13], ~T[12:30:45], "Etc/UTC")
      
      formatted = Timezone.format_local(utc_dt, "%H:%M %Z")
      
      # Should show CET or CEST depending on date
      assert formatted =~ ~r/13:30 CE[S]?T/
    end
  end

  describe "in_dst?/0" do
    test "detects daylight saving time status" do
      is_dst = Timezone.in_dst?()
      
      # Should return a boolean
      assert is_boolean(is_dst)
      
      # In March (CET), should be false
      # In July (CEST), should be true
      # This test just ensures the function works without error
    end
  end

  describe "edge cases" do
    test "handles invalid timezone gracefully" do
      # Temporarily change timezone to invalid value
      original_tz = Application.get_env(:jikan, :timezone)
      Application.put_env(:jikan, :timezone, "Invalid/Timezone")
      
      # Should fall back gracefully
      {:ok, utc_dt} = DateTime.new(~D[2026-03-13], ~T[12:00:00], "Etc/UTC")
      local_dt = Timezone.to_local(utc_dt)
      
      # Should return original datetime when conversion fails
      assert local_dt == utc_dt
      
      # Restore original timezone
      Application.put_env(:jikan, :timezone, original_tz)
    end

    test "handles DST transition dates" do
      # Spring forward: Last Sunday of March 2026 at 02:00 CET -> 03:00 CEST
      # March 29, 2026 is the last Sunday of March
      # At 01:00 UTC on March 29, 2026, Berlin time transitions from 02:00 CET to 03:00 CEST
      {:ok, before_dst} = DateTime.new(~D[2026-03-29], ~T[00:00:00], "Etc/UTC")
      before_local = Timezone.to_local(before_dst)
      
      # 00:00 UTC = 01:00 CET (before transition)
      assert before_local.hour == 1
      assert before_local.zone_abbr == "CET"
      
      # After DST transition
      {:ok, after_dst} = DateTime.new(~D[2026-03-29], ~T[01:30:00], "Etc/UTC")
      after_local = Timezone.to_local(after_dst)
      
      # 01:30 UTC = 03:30 CEST (after transition at 01:00 UTC)
      assert after_local.hour == 3
      assert after_local.zone_abbr == "CEST"
    end
  end
end