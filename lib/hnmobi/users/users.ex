defmodule Hnmobi.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias Ecto.UUID

  alias Hnmobi.Repo

  alias Hnmobi.Users.User
  alias Hnmobi.Users.LoginHash

  alias Hnmobi.Main.LoginEmail
  alias Hnmobi.Main.Mailer

  require Logger

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email) do
    user = Repo.get_by(User, email: email)
    user
  end

  def get_daily_recipients() do
    Repo.all(from u in User, where: u.daily, select: u.kindle)
    |> Enum.filter(fn email -> !is_nil(email) && email != "" end)
    # check for valid email
  end

  def get_weekly_recipients() do
    Repo.all(from u in User, where: u.weekly, select: u.kindle)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_login_link(test) do
    valid_until = Timex.shift(Timex.now(), hours: 12)

    login_hash =
      %LoginHash{hash: UUID.generate(), user: test.user, valid_until: valid_until}
      |> Repo.insert!()

    link = HnmobiWeb.Router.Helpers.page_url(HnmobiWeb.Endpoint, :config_user, login_hash.hash)
    %{test | link: link}
  end

  def invalidate_old_links(test) do
    from(lh in LoginHash, where: lh.user_id == ^test.user.id) |> Repo.delete_all
    test
  end

  def send_login_link(test) do
    LoginEmail.deliver(test) |> Mailer.deliver()
  end

  def get_user_by_hash(hash) when is_nil(hash) do
    {:error, "Login hash was nil"}
  end

  def get_user_by_hash(hash) do
    login_hash = Repo.get_by(LoginHash, hash: hash) |> Repo.preload([:user, user: :login_hash])
    now = Timex.now

    if is_nil(login_hash) or Timex.after?(now, login_hash.valid_until) do
      {:error, "Login link not valid or user doesn't exist anymore."}
    else
      {:ok, login_hash.user}
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
