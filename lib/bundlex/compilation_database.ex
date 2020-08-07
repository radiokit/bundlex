defmodule Bundlex.CompilationDatabase do
  @moduledoc false

  @file_name "compile_commands.json"

  defmodule Object do
    @moduledoc false

    alias Bundlex.Toolchain

    @type t :: %__MODULE__{
            directory: String.t(),
            file: String.t(),
            command: String.t()
          }

    @derive Jason.Encoder

    @enforce_keys [
      :directory,
      :file,
      :command
    ]
    defstruct @enforce_keys

    @spec from_command(command :: String.t()) :: [t()]
    def from_command(command) do
      # HACK This is a pretty hacked out implementation, that should never be
      # published as release code. Ideally we should rework our Toolchain/command generation
      # code to generate "rules" and "builds" with multiple "inputs" and "outputs",
      # similarly to how Ninja works. Eventually we night adapt such model to generate
      # Ninja build scripts and use Ninja itself to perform real builds of user code.

      # This implementation assumes that the source file is always passed as the last argument
      # to the compiler, which happens to be true on Linux and macOS.

      compilers =
        case Bundlex.platform() do
          :linux -> Toolchain.GCC.compilers()
          :macosx -> Toolchain.XCode.compilers()
          _ -> raise "Generating compilation database is unsupported yet on this platform."
        end
        |> Map.from_struct()
        |> Map.values()

      command = command |> String.trim()

      with true <- Enum.any?(compilers, &String.starts_with?(command, &1)),
           file =
             command
             |> OptionParser.split()
             |> List.last(),
           true <- Path.extname(file) != ".o",
           object = %__MODULE__{
             directory: File.cwd!(),
             file: file,
             command: command
           } do
        [object]
      else
        _ -> []
      end
    end
  end

  @type t :: [Object.t()]

  @type command_t :: String.t()

  @spec new([command_t]) :: t
  def new(commands) do
    Enum.flat_map(commands, &Object.from_command/1)
  end

  @spec store(db :: t, name :: String.t()) :: Bunch.Type.try_t(String.t())
  def store(db, name \\ @file_name) do
    with {:ok, json} <- Jason.encode(db, pretty: true),
         :ok <- File.write(name, json) do
      {:ok, name}
    end
  end
end
