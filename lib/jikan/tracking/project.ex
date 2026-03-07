defmodule Jikan.Tracking.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :description, :string
    field :color, :string, default: "#3B82F6"
    field :archived, :boolean, default: false
    field :hourly_rate, :decimal
    
    belongs_to :client, Jikan.Tracking.Client
    belongs_to :user, Jikan.Accounts.User
    has_many :time_entries, Jikan.Tracking.TimeEntry

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :color, :archived, :hourly_rate, :client_id, :user_id])
    |> validate_required([:name, :color, :archived, :client_id, :user_id])
    |> validate_format(:color, ~r/^#[0-9A-Fa-f]{6}$/, message: "must be a valid hex color code")
    |> validate_number(:hourly_rate, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:client_id)
    |> foreign_key_constraint(:user_id)
  end
end
