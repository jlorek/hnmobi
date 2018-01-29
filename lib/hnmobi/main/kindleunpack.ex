defmodule Hnmobi.Main.Kindleunpack do
    require Logger
  
    def extract_kf7(mobi_path) do
        output_dir = Path.join(Path.dirname(mobi_path), "kindleunpack")
        mobi_file = Path.basename(mobi_path)
        kf7_path = Path.join(output_dir, "mobi7-#{mobi_file}")
        Logger.info("kf7_path = #{kf7_path}")

        script_path = Path.join(System.cwd!(), "bin/KindleUnpack/lib/kindleunpack.py")
        unpack_arguments = "-s #{mobi_path} #{output_dir}"
        shell_arguments = "python #{script_path} #{unpack_arguments}"

        Logger.info("Executing shell command '#{shell_arguments}'")
        kindleunpack_process = System.cmd(System.get_env("SHELL"), ["-c", shell_arguments])
        kindleunpack_output = elem(kindleunpack_process, 0)
        Logger.info("<kindleunpack_output>")
        Logger.info(kindleunpack_output)
        Logger.info("</kindlunpack_output>")

        if File.exists?(kf7_path) do
            {:ok, kf7_path}
        else
            {:error}
        end
    end
end
  