defmodule Jikan.Timezone do
  @moduledoc """
  Utilities for handling timezone conversions in the application.
  """

  @doc """
  Get the configured timezone for the application.
  """
  def get_timezone do
    Application.get_env(:jikan, :timezone, "Europe/Berlin")
  end

  @doc """
  Convert a UTC DateTime to the local timezone.
  """
  def to_local(%DateTime{} = datetime) do
    case DateTime.shift_zone(datetime, get_timezone()) do
      {:ok, local_dt} -> local_dt
      {:error, _} -> datetime
    end
  end

  @doc """
  Convert a local DateTime to UTC.
  """
  def to_utc(%DateTime{} = datetime) do
    case DateTime.shift_zone(datetime, "Etc/UTC") do
      {:ok, utc_dt} -> utc_dt
      {:error, _} -> datetime
    end
  end

  @doc """
  Convert a UTC Time to local time for today.
  Returns a DateTime in the local timezone.
  """
  def time_to_local(%Time{} = time, date \\ Date.utc_today()) do
    {:ok, datetime} = DateTime.new(date, time, "Etc/UTC")
    to_local(datetime)
  end

  @doc """
  Convert a local Time to UTC for today.
  Returns a Time in UTC.
  """
  def time_to_utc(%Time{} = time, date \\ Date.utc_today()) do
    {:ok, naive_dt} = NaiveDateTime.new(date, time)
    
    case DateTime.from_naive(naive_dt, get_timezone()) do
      {:ok, local_dt} ->
        utc_dt = to_utc(local_dt)
        DateTime.to_time(utc_dt)
        
      {:error, _} ->
        time
    end
  end

  @doc """
  Get the current date in the local timezone.
  """
  def local_today do
    DateTime.now!(get_timezone())
    |> DateTime.to_date()
  end

  @doc """
  Get the current time in the local timezone.
  """
  def local_now do
    DateTime.now!(get_timezone())
    |> DateTime.to_time()
  end

  @doc """
  Format a DateTime in the local timezone with a specific format.
  """
  def format_local(%DateTime{} = datetime, format \\ "%Y-%m-%d %H:%M:%S") do
    datetime
    |> to_local()
    |> Calendar.strftime(format)
  end

  @doc """
  Check if we're currently in daylight saving time.
  """
  def in_dst? do
    tz = get_timezone()
    
    case DateTime.now(tz) do
      {:ok, dt} ->
        # Check if the timezone abbreviation contains 'DST' or similar
        # or if the std_offset is greater than 0
        dt.std_offset > 0
        
      {:error, _} ->
        false
    end
  end
end