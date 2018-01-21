defmodule Hnmobi.Users.LoginHash do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hnmobi.Users.LoginHash


  schema "login_hashs" do
    field :hash, Ecto.UUID
    field :valid_until, :utc_datetime
    belongs_to :user, Hnmobi.Users.User

    timestamps()
  end

  @doc false
  def changeset(%LoginHash{} = login_hash, attrs) do
    login_hash
    |> cast(attrs, [:hash, :valid_until])
    |> validate_required([:hash, :valid_until])
  end
end
