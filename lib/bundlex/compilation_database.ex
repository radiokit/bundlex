defmodule Bundlex.CompilationDatabase do
  @moduledoc false

  @file_name "compile_commands.json"

  defmodule Object do
    @moduledoc false

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

    @spec from_command(command :: String.t()) :: Bunch.Type.try_t(t())
    def from_command(command) do
      {:ok, %__MODULE__{
        directory: File.cwd!(),
        file: "TODO",
        command: command,
      }}
    end
  end

  @type t :: [Object.t()]

  @type command_t :: String.t()

  @spec new([command_t]) :: Bunch.Type.try_t(t)
  def new(commands) do
    Bunch.Enum.try_map(commands, &Object.from_command/1)
  end

  @spec store(db :: t, name :: String.t()) :: Bunch.Type.try_t(String.t())
  def store(db, name \\ @file_name) do
    with {:ok, json} <- Jason.encode(db, pretty: true),
         :ok <- File.write(name, json) do
      {:ok, name}
    end
  end
end
