defmodule Hnmobi.Repo.Migrations.CreateLoginHashs do
  use Ecto.Migration

  def change do
    create table(:login_hashs) do
      add :hash, :uuid
      add :valid_until, :utc_datetime

      timestamps()
    end

  end
end
