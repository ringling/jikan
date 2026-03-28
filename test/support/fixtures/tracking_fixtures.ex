defmodule Jikan.TrackingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Jikan.Tracking` context.
  """

  import Jikan.AccountsFixtures

  @doc """
  Generate a client.
  """
  def client_fixture(attrs \\ %{}) do
    user = user_fixture()
    client_fixture(user, attrs)
  end

  def client_fixture(user, attrs) do
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
  def project_fixture(attrs \\ %{}) do
    user = user_fixture()
    project_fixture(user, attrs)
  end

  def project_fixture(user, attrs) do
    # Create a client if client_id is not provided
    attrs = 
      if Map.has_key?(attrs, :client_id) do
        attrs
      else
        client = client_fixture(user)
        Map.put(attrs, :client_id, client.id)
      end
    
    {:ok, project} =
      attrs
      |> Enum.into(%{
        archived: true,
        color: "#FF0000",
        description: "some description",
        name: "some name"
      })
      |> then(fn attrs -> Jikan.Tracking.create_project(user, attrs) end)

    project
  end

  @doc """
  Generate a time_entry.
  """
  def time_entry_fixture(attrs \\ %{}) do
    user = user_fixture()
    time_entry_fixture(user, attrs)
  end

  def time_entry_fixture(user, attrs) do
    # Create a project if project_id is not provided
    attrs = 
      if Map.has_key?(attrs, :project_id) do
        attrs
      else
        project = project_fixture(user)
        Map.put(attrs, :project_id, project.id)
      end
    
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
