defmodule Hnmobi.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :kindle, :string
      add :daily, :boolean, default: false, null: false
      add :weekly, :boolean, default: false, null: false

      timestamps()
    end

  end
end
