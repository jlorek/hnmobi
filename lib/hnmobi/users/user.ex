defmodule Hnmobi.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hnmobi.Users.User


  schema "users" do
    field :daily, :boolean, default: true
    field :email, :string
    field :kindle, :string
    field :weekly, :boolean, default: true

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :kindle, :daily, :weekly])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end
