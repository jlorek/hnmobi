defmodule Hnmobi.Repo.Migrations.AddUserToLoginHash do
  use Ecto.Migration

  def change do
    alter table(:login_hashs) do
      add :user_id, references(:users) 
    end
  end
end
