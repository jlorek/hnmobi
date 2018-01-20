defmodule HnmobiWeb.PageController do
  use HnmobiWeb, :controller
  require Logger

  alias Hnmobi.Main.UserEmail
  alias Hnmobi.Main.Mailer
  alias Hnmobi.Main.HackerNews
  alias Hnmobi.Main.Mercury
  alias Hnmobi.Users
  alias Hnmobi.Users.User

  def index(conn, _params) do
    changeset = Users.change_user(%User{})
    render(conn, "index.html", changeset: changeset)
  end

  def show(conn, %{"messenger" => localVar}) do
    HnmobiWeb.Endpoint.broadcast!("topic:subtopic", "new_msg", %{
      body: "Someone is visiting hello/" <> localVar
    })

    render(conn, "show.html", templateVar: localVar)
  end

  def top(conn, _params) do
    result = HackerNews.top()
    email = get_session(conn, :email)
    render(conn, "top.html", items: result, email: email)
  end

  def create_user(conn, %{"user" => user}) do
    Users.create_or_get_user(user)
    |> Users.create_login_link
    |> Users.send_login_link

    conn
    |> redirect(to: page_path(conn, :index))
  end

  def convert(conn, %{"hnid" => hnid}) do
    article = HackerNews.details(hnid)
    content = Mercury.reader(article["url"])
    render(conn, "convert.html", content: content, title: article["title"])
  end

  defp prepare_html(path, %{"url" => url, "title" => title}) do
    content = Mercury.reader(url)

    html_path = Path.join(path, "article.html")
    Logger.info("html_path = #{html_path}")

    {:ok, html_handle} = File.open(html_path, [:write, :utf8])
    IO.write(html_handle, "<html><head><title>#{title}</title></head><body>")

    IO.write(
      html_handle,
      "<div id=\"cover-image\"><img src=\"https://www.vaporfi.com/media/catalog/product/cache/9/thumbnail/100x100/9df78eab33525d08d6e5fb8d27136e95/v/z/vz_eliquid_banana_bash.jpg\" /></div>"
    )

    IO.write(html_handle, content)
    IO.write(html_handle, "</body>")
    File.close(html_handle)

    html_path
  end

  defp prepare_epub(path, html_path) do
    epub_path = Path.join(path, "pandoc.epub")
    Logger.info("epub_path = #{epub_path}")

    # process_padoc = System.cmd "pandoc", ["-s", "-f html", "-t epub", "-o #{epub_path}", html_path]
    pandoc_path = Application.fetch_env!(:hnmobi, :pandoc_path)
    pandoc_arguments = " -s -f html -t epub -o #{epub_path} #{html_path}"
    pandoc_process = System.cmd(System.get_env("SHELL"), ["-c", pandoc_path <> pandoc_arguments])
    pandoc_output = elem(pandoc_process, 0)
    Logger.info(pandoc_output)

    if String.contains?(pandoc_output, "WARNING") do
      Logger.warn("Pandoc was not pleased but did the job!")
    end

    epub_path
  end

  defp prepare_mobi(path, epub_path) do
    mobi_path = Path.join(path, "kindle.mobi")
    Logger.info("mobi_path = #{mobi_path}")

    # https://groups.google.com/forum/#!topic/elixir-lang-talk/ZrqKW1NhDCw 
    kindlegen_path = Application.fetch_env!(:hnmobi, :kindlegen_path)
    kindlegen_arguments = " #{epub_path} -o #{Path.basename(mobi_path)}"

    kindlegen_process =
      System.cmd(System.get_env("SHELL"), ["-c", kindlegen_path <> kindlegen_arguments])

    kindleget_output = elem(kindlegen_process, 0)
    Logger.info(kindleget_output)

    if String.contains?(kindleget_output, "Error") do
      Logger.error("Kindlegen was not happy at all...")
    end

    mobi_path
  end

  defp get_mobi(hnid) do
    article = HackerNews.details(hnid)
    {:ok, temp_path} = Temp.mkdir()
    html_path = prepare_html(temp_path, article)
    epub_path = prepare_epub(temp_path, html_path)
    mobi_path = prepare_mobi(temp_path, epub_path)
    {article, mobi_path}
  end

  def send(conn, %{"hnid" => hnid}) do
    {article, mobi_path} = get_mobi(hnid)
    email = get_session(conn, :email)

    UserEmail.deliver(article["title"], mobi_path, email) |> Mailer.deliver()

    conn
    |> put_flash(:info, "Check your mail!")
    |> redirect(to: "/top")
  end

  def mobi(conn, %{"hnid" => hnid}) do
    {_article, mobi_path} = get_mobi(hnid)

    conn
    |> put_resp_content_type("application/octet-stream", nil)
    |> put_resp_header("content-disposition", ~s[attachment; filename="kindle.mobi"])
    |> send_file(200, mobi_path)
  end
end
