defmodule Jikan.TrackingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Jikan.Tracking` context.
  """

  @doc """
  Generate a client.
  """
  def client_fixture(user, attrs \\ %{}) do
    {:ok, client} =
      attrs
      |> Enum.into(%{
        active: true,
        contact_email: "some contact_email",
        name: "some name"
      })
      |> then(fn attrs -> Jikan.Tracking.create_client(user, attrs) end)

    client
  end

  @doc """
  Generate a project.
  """
  def project_fixture(user, attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        archived: true,
        color: "some color",
        description: "some description",
        name: "some name"
      })
      |> then(fn attrs -> Jikan.Tracking.create_project(user, attrs) end)

    project
  end

  @doc """
  Generate a time_entry.
  """
  def time_entry_fixture(user, attrs \\ %{}) do
    {:ok, time_entry} =
      attrs
      |> Enum.into(%{
        billable: true,
        date: ~D[2026-03-02],
        description: "some description",
        duration_minutes: 42,
        end_time: ~T[14:00:00],
        start_time: ~T[14:00:00]
      })
      |> then(fn attrs -> Jikan.Tracking.create_time_entry(user, attrs) end)

    time_entry
  end
end
