defmodule JikanWeb.ExportController do
  use JikanWeb, :controller

  alias Jikan.Tracking

  def time_entries(conn, params) do
    user = conn.assigns.current_scope.user
    filters = build_filters_from_params(params)
    
    csv_content = Tracking.export_time_entries_to_csv(user, filters)
    filename = build_filename(filters)
    
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, csv_content)
  end

  defp build_filters_from_params(params) do
    %{}
    |> maybe_put_filter("client_id", params["client_id"])
    |> maybe_put_filter("year", params["year"])
    |> maybe_put_filter("month", params["month"])
    |> maybe_put_filter("week", params["week"])
  end

  defp maybe_put_filter(filters, _key, nil), do: filters
  defp maybe_put_filter(filters, _key, ""), do: filters
  defp maybe_put_filter(filters, key, value), do: Map.put(filters, key, value)

  defp build_filename(filters) do
    base_name = "jikan_time_entries"
    date_suffix = Date.utc_today() |> Date.to_string()
    
    filter_parts = []
    
    filter_parts = 
      case filters["client_id"] do
        nil -> filter_parts
        "" -> filter_parts
        _client_id -> filter_parts ++ ["filtered"]
      end
    
    filter_parts = 
      case filters["year"] do
        nil -> filter_parts
        "" -> filter_parts
        year -> filter_parts ++ [year]
      end
    
    filter_parts = 
      case filters["month"] do
        nil -> filter_parts
        "" -> filter_parts
        month -> filter_parts ++ [month_name_for_filename(month)]
      end
    
    filter_parts = 
      case filters["week"] do
        nil -> filter_parts
        "" -> filter_parts
        week -> filter_parts ++ ["W#{String.pad_leading(week, 2, "0")}"]
      end

    name_parts = [base_name] ++ filter_parts ++ [date_suffix]
    Enum.join(name_parts, "_") <> ".csv"
  end

  defp month_name_for_filename(month) do
    case month do
      "1" -> "Jan"
      "2" -> "Feb"
      "3" -> "Mar"
      "4" -> "Apr"
      "5" -> "Maj"
      "6" -> "Jun"
      "7" -> "Jul"
      "8" -> "Aug"
      "9" -> "Sep"
      "10" -> "Okt"
      "11" -> "Nov"
      "12" -> "Dec"
      _ -> "UnknownMonth"
    end
  end
end