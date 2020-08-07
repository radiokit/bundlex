defmodule Bundlex.Toolchain.GCC do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Toolchain.Common.{Unix, Compilers}

  def compilers, do: %Compilers{c: "gcc", cpp: "g++"}

  @impl Toolchain
  def compiler_commands(native, native_interface \\ nil) do
    {cflags, lflags} =
      cond do
        native.type == :native && native_interface == :nif -> {"-fPIC", "-rdynamic -shared"}
        native.type == :lib -> {"-fPIC", ""}
        true -> {"", ""}
      end

    compiler = compilers() |> Map.get(native.language)

    Unix.compiler_commands(
      native,
      "#{compiler} #{cflags}",
      "#{compiler} #{lflags}",
      native.language,
      native_interface,
      wrap_deps: &"-Wl,--whole-archive #{&1} -Wl,--no-whole-archive"
    )
  end
end
