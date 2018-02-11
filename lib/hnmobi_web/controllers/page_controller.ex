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
    changeset = Users.change_user(%User{})
    render(conn, "index.html", changeset: changeset)
  end


  def help(conn, _params) do
    render(conn, "help.html");
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
    |> put_flash(:info, "Check your emails!")
    |> redirect(to: page_path(conn, :index))
  end

  def config_user(conn, %{"hash" => hash}) do
    case Users.get_user_by_hash(hash) do
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: page_path(conn, :index))

      {:ok, user} ->
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

  def show(conn, %{"hnid" => hnid, "scraper" => scraper}) do
    article = HackerNews.details(hnid)

    content = case scraper do 
      "mercury" -> Mercury.get_content(article.url)
      "readability" -> Readability.summarize(article.url).article_html
      "mozilla" -> Mozilla.get_content(article.url)
    end

    content = Sanitizer.sanitize(content)

    render(conn, "convert.html", content: content, title: article.title)
  end

  def mobi(conn, %{"hnid" => hnid}) do
    {:ok, mobi_path} = Ebook.generate_single(hnid)

    conn
    |> put_resp_content_type("application/octet-stream", nil)
    |> put_resp_header("content-disposition", ~s[attachment; filename="hnid-#{hnid}.mobi"])
    |> send_file(200, mobi_path)
  end
end
