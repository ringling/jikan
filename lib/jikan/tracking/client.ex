defmodule Jikan.Tracking.Client do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clients" do
    field :name, :string
    field :contact_email, :string
    field :active, :boolean, default: true
    
    belongs_to :user, Jikan.Accounts.User
    has_many :projects, Jikan.Tracking.Project

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(client, attrs) do
    client
    |> cast(attrs, [:name, :contact_email, :active, :user_id])
    |> validate_required([:name, :active, :user_id])
    |> unique_constraint(:name, name: :clients_name_user_id_index)
    |> foreign_key_constraint(:user_id)
  end
end
