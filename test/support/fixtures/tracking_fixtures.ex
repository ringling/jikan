defmodule Jikan.TrackingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Jikan.Tracking` context.
  """

  @doc """
  Generate a client.
  """
  def client_fixture(attrs \\ %{}) do
    {:ok, client} =
      attrs
      |> Enum.into(%{
        active: true,
        contact_email: "some contact_email",
        name: "some name"
      })
      |> Jikan.Tracking.create_client()

    client
  end

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        archived: true,
        color: "some color",
        description: "some description",
        name: "some name"
      })
      |> Jikan.Tracking.create_project()

    project
  end

  @doc """
  Generate a time_entry.
  """
  def time_entry_fixture(attrs \\ %{}) do
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
      |> Jikan.Tracking.create_time_entry()

    time_entry
  end
end
