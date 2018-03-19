defmodule HnmobiWeb.Test do
  defstruct user: nil, link: nil
end

defmodule HnmobiWeb.PageController do
  use HnmobiWeb, :controller
  require Logger

  alias Hnmobi.Main.Ebook
  alias Hnmobi.Main.HackerNews
  alias Hnmobi.Main.Algolia
  alias Hnmobi.Main.Mercury
  alias Hnmobi.Main.Mozilla
  alias Hnmobi.Main.Sanitizer
  alias Hnmobi.Users
  alias Hnmobi.Users.User

  alias HnmobiWeb.Test

  @kindle_adress "@kindle.com"

  def index(conn, _params) do
    hash = get_session(conn, :hash)

    # let's check if the session is still valid
    case Users.get_user_by_hash(hash) do
      {:error, _} ->
        changeset = Users.change_user(%User{})
        render(conn, "index.html", changeset: changeset)
      {:ok, _} ->
        redirect(conn, to: page_path(conn, :config_user, hash))
    end
  end

  def help(conn, _params) do
    render(conn, "help.html");
  end

  def next_steps(conn, _params) do
    render(conn, "next-steps.html")
  end

  def create_user(conn, %{"user" => user}) do
    email = user["email"]

    if email =~ @kindle_adress do
      conn
      |> put_flash(:error, "Please don't use your kindle email address for login/registration!")
      |> redirect(to: page_path(conn, :index))
    end

    db_user = Users.get_user_by_email(email)

    db_user =
      case is_nil(db_user) do
        true ->
          Users.create_user(user)
          Users.get_user_by_email(email)

        false ->
          db_user
      end

    test = %Test{user: db_user}

    test
    |> Users.invalidate_old_links()
    |> Users.create_login_link()
    |> Users.send_login_link()

    conn
    |> redirect(to: page_path(conn, :next_steps))
  end

  def config_user(conn, %{"hash" => hash}) do
    case Users.get_user_by_hash(hash) do
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: page_path(conn, :index))

      {:ok, user} ->
        conn = put_session(conn, :hash, hash)
        changeset = Users.change_user(user)
        render(conn, "config.html", user: user, changeset: changeset)
    end
  end

  def update_user(conn, %{"user" => user}) do
    hash = user["login_hash"]["hash"]
    {:ok, db_user} = Users.get_user_by_hash(hash)
    user = Map.pop(user, "login_hash")
    {_, user} = user
    Users.update_user(db_user, user)

    conn
    |> put_flash(:info, "Your config has been updated")
    |> redirect(to: page_path(conn, :config_user, hash))
  end

  def top(conn, _params) do
    result = Algolia.top()
    render(conn, "top.html", items: result)
  end

  def sponsors(conn, _params) do
    render(conn, "sponsors.html")
  end

  def show(conn, %{"hnid" => hnid, "scraper" => scraper}) do
    article = HackerNews.details(hnid)

    case is_nil(article) do
      true ->
        conn
        |> put_flash(:error, "HNID #{hnid} has some missing properties")
        |> redirect(to: "/top")
      false ->
        content = case scraper do
          "mercury" -> Mercury.get_content(article.url)
          "readability" -> Readability.summarize(article.url).article_html
          "mozilla" -> Mozilla.get_content(article.url)
        end

        content = Sanitizer.sanitize(content)
        render(conn, "convert.html", content: content, title: article.title)
    end
  end

  def mobi(conn, %{"hnid" => hnid}) do
    case Ebook.generate_single(hnid) do
      {:ok, mobi_path} ->
        conn
        |> put_resp_content_type("application/octet-stream", nil)
        |> put_resp_header("content-disposition", ~s[attachment; filename="hnid-#{hnid}.mobi"])
        |> send_file(200, mobi_path)
      _ ->
        conn
        |> put_flash(:error, "Could not generate eBook for HNID #{hnid}")
        |> redirect(to: "/top")
    end
  end
end
