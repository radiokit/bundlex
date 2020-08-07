defmodule Mix.Tasks.Compile.Bundlex do
  @shortdoc "Builds natives specified in bundlex.exs file"
  @moduledoc """
  #{@shortdoc}

  Accepts the following command line arguments:
  - `--store-scripts` - if set, shell scripts are stored in the project
  root folder for further analysis.
  - `--store-compiledb` - if set, a compilation database
  file (`compile_commands.json`) is create in the project root folder
  - `--dry-run` - does not build anything. Useful combined with
  `--store-scripts` option.

  Add `:bundlex` to compilers in your Mix project to have this task executed
  each time the project is compiled.
  """

  use Mix.Task.Compiler
  alias Bundlex.{BuildScript, CompilationDatabase, Native, Output, Platform, Project}
  alias Bundlex.Helper.MixHelper

  @impl true
  def run(_args) do
    {:ok, _apps} = Application.ensure_all_started(:bundlex)
    commands = []

    app = MixHelper.get_app!()
    platform = Bundlex.platform()

    project =
      with {:ok, project} <- Project.get(app) do
        project
      else
        {:error, reason} ->
          Output.raise("Cannot get project for app: #{inspect(app)}, reason: #{inspect(reason)}")
      end

    commands = commands ++ Platform.get_module(platform).toolchain_module.before_all!(platform)

    commands =
      commands ++
        case Native.resolve_natives(project, platform) do
          {:ok, nifs_commands} -> nifs_commands
          {:error, reason} -> Output.raise("Error parsing Natives, reason: #{inspect(reason)}")
        end

    build_script = BuildScript.new(commands)

    {cmdline_options, _argv, _errors} =
      OptionParser.parse(
        System.argv(),
        switches: [
          store_scripts: :boolean,
          store_compiledb: :boolean,
          dry_run: :boolean
        ]
      )

    if cmdline_options[:store_scripts] do
      {:ok, {filename, _script}} = build_script |> BuildScript.store(platform)
      Output.info("Stored build script at #{File.cwd!() |> Path.join(filename)}")
    end

    if cmdline_options[:store_compiledb] do
      db = CompilationDatabase.new(commands)

      case CompilationDatabase.store(db) do
        {:ok, filename} ->
          Output.info("Stored compilation database as #{File.cwd!() |> Path.join(filename)}")

        {:error, reason} ->
          Output.raise("Failed to create compile_commands.json:\n\n#{reason}")
      end
    end

    if cmdline_options[:dry_run] do
      {:ok, []}
    else
      case BuildScript.run(build_script, platform) do
        :ok ->
          {:ok, []}

        {:error, {:run_build_script, return_code: ret, command: cmd}} ->
          Output.raise("Build script:\n\n#{cmd}\n\nreturned non-zero code: #{ret}")
          {:error, []}

        {:error, reason} ->
          Output.raise("Error running build script, reason #{inspect(reason)}")
          {:error, []}
      end
    end
  end
end
