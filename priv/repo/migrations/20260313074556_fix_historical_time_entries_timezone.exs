defmodule Jikan.Repo.Migrations.FixHistoricalTimeEntriesTimezone do
  use Ecto.Migration

  def up do
    # Fix historical time entries that were saved with wrong timezone
    # Users entered CET/CEST times, but system saved them as UTC
    # We need to subtract 1 hour for CET (winter) or 2 hours for CEST (summer)
    
    # PostgreSQL version - adjusts times based on date
    execute """
    UPDATE time_entries
    SET 
      start_time = CASE 
        -- For dates during CEST (last Sunday of March to last Sunday of October)
        -- We need to subtract 2 hours (times were saved 2 hours ahead)
        WHEN (
          (EXTRACT(MONTH FROM date) = 3 AND EXTRACT(DAY FROM date) >= 25 AND EXTRACT(DOW FROM date) = 0) OR
          (EXTRACT(MONTH FROM date) BETWEEN 4 AND 9) OR
          (EXTRACT(MONTH FROM date) = 10 AND EXTRACT(DAY FROM date) < 25)
        ) THEN 
          (start_time::time - INTERVAL '2 hours')::time
        -- For dates during CET (winter time)
        -- We need to subtract 1 hour (times were saved 1 hour ahead)
        ELSE 
          (start_time::time - INTERVAL '1 hour')::time
      END,
      end_time = CASE 
        WHEN end_time IS NOT NULL THEN
          CASE 
            -- CEST period (summer time)
            WHEN (
              (EXTRACT(MONTH FROM date) = 3 AND EXTRACT(DAY FROM date) >= 25 AND EXTRACT(DOW FROM date) = 0) OR
              (EXTRACT(MONTH FROM date) BETWEEN 4 AND 9) OR
              (EXTRACT(MONTH FROM date) = 10 AND EXTRACT(DAY FROM date) < 25)
            ) THEN 
              (end_time::time - INTERVAL '2 hours')::time
            -- CET period (winter time)
            ELSE 
              (end_time::time - INTERVAL '1 hour')::time
          END
        ELSE NULL
      END,
      paused_at = CASE 
        WHEN paused_at IS NOT NULL THEN
          CASE 
            -- CEST period (summer time)
            WHEN (
              (EXTRACT(MONTH FROM date) = 3 AND EXTRACT(DAY FROM date) >= 25 AND EXTRACT(DOW FROM date) = 0) OR
              (EXTRACT(MONTH FROM date) BETWEEN 4 AND 9) OR
              (EXTRACT(MONTH FROM date) = 10 AND EXTRACT(DAY FROM date) < 25)
            ) THEN 
              (paused_at::time - INTERVAL '2 hours')::time
            -- CET period (winter time)
            ELSE 
              (paused_at::time - INTERVAL '1 hour')::time
          END
        ELSE NULL
      END
    WHERE 
      -- Only fix entries created before the timezone fix was deployed
      -- The fix was deployed on March 13, 2026 at 07:38:52 UTC
      inserted_at < '2026-03-13 07:38:52'::timestamp
      -- And only if they have start times (not manual duration-only entries)
      AND start_time IS NOT NULL
    """
    
    # Add an index to help identify migrated entries in the future if needed
    execute """
    COMMENT ON TABLE time_entries IS 'Historical entries before 2026-03-13 07:38:52 UTC have been adjusted for timezone correction';
    """
  end

  def down do
    # Reverse the timezone fix by adding hours back
    execute """
    UPDATE time_entries
    SET 
      start_time = CASE 
        -- For CEST dates, add 2 hours back
        WHEN (
          (EXTRACT(MONTH FROM date) = 3 AND EXTRACT(DAY FROM date) >= 25 AND EXTRACT(DOW FROM date) = 0) OR
          (EXTRACT(MONTH FROM date) BETWEEN 4 AND 9) OR
          (EXTRACT(MONTH FROM date) = 10 AND EXTRACT(DAY FROM date) < 25)
        ) THEN 
          (start_time::time + INTERVAL '2 hours')::time
        -- For CET dates, add 1 hour back
        ELSE 
          (start_time::time + INTERVAL '1 hour')::time
      END,
      end_time = CASE 
        WHEN end_time IS NOT NULL THEN
          CASE 
            WHEN (
              (EXTRACT(MONTH FROM date) = 3 AND EXTRACT(DAY FROM date) >= 25 AND EXTRACT(DOW FROM date) = 0) OR
              (EXTRACT(MONTH FROM date) BETWEEN 4 AND 9) OR
              (EXTRACT(MONTH FROM date) = 10 AND EXTRACT(DAY FROM date) < 25)
            ) THEN 
              (end_time::time + INTERVAL '2 hours')::time
            ELSE 
              (end_time::time + INTERVAL '1 hour')::time
          END
        ELSE NULL
      END,
      paused_at = CASE 
        WHEN paused_at IS NOT NULL THEN
          CASE 
            WHEN (
              (EXTRACT(MONTH FROM date) = 3 AND EXTRACT(DAY FROM date) >= 25 AND EXTRACT(DOW FROM date) = 0) OR
              (EXTRACT(MONTH FROM date) BETWEEN 4 AND 9) OR
              (EXTRACT(MONTH FROM date) = 10 AND EXTRACT(DAY FROM date) < 25)
            ) THEN 
              (paused_at::time + INTERVAL '2 hours')::time
            ELSE 
              (paused_at::time + INTERVAL '1 hour')::time
          END
        ELSE NULL
      END
    WHERE 
      inserted_at < '2026-03-13 07:38:52'::timestamp
      AND start_time IS NOT NULL
    """
    
    # Remove comment
    execute """
    COMMENT ON TABLE time_entries IS NULL;
    """
  end
end