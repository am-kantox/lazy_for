defmodule Pdict do
  defstruct []

  defimpl Collectable do
    def into(struct) do
      fun = fn
        _, {:cont, x} -> Process.put(:into_cont, [x | Process.get(:into_cont)])
        _, :done -> Process.put(:into_done, true)
        _, :halt -> Process.put(:into_halt, true)
      end

      {struct, fun}
    end
  end
end
