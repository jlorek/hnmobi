defmodule Hnmobi.Main.Pandoc do
    require Logger
  
    defp cover_path() do Path.join(System.cwd!(), "pandoc/static/cover.jpg") end

    def convert(working_directory, files) do
      epub_path = Path.join(working_directory, "pandoc.epub")
      Logger.info "epub_path = #{epub_path}"

      cover_path = cover_path()
      Logger.info "cover_path = #{cover_path}"
      unless (File.exists?(cover_path)) do
        Logger.warn "Cover image should be located at '#{cover_path}' but could not be found"
      end

      input_files = Enum.join(files, " ");
      pandoc_path = Application.fetch_env!(:hnmobi, :pandoc_path)
      pandoc_arguments = " -s -f html -t epub --epub-cover-image=#{cover_path} -o #{epub_path} #{input_files}"
      shell_arguments = pandoc_path <> pandoc_arguments

      Logger.info "Executing shell command '#{shell_arguments}'"
      pandoc_process = System.cmd System.get_env("SHELL"), ["-c", shell_arguments]
      pandoc_output = elem(pandoc_process, 0)
      Logger.info("<pandoc_output>")
      Logger.info pandoc_output
      Logger.info("</pandoc_output>")
  
      if String.contains?(pandoc_output, "WARNING") do
          Logger.warn "Pandoc executed with warning(s)"
      end
  
      {:ok, epub_path}
    end
  end
    