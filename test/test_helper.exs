defmodule LazyFor.CLIFormatter do
  @moduledoc false
  use GenServer

  ## Callbacks

  def init(opts) do
    config = %{
      seed: opts[:seed],
      trace: opts[:trace],
      colors: Keyword.put_new(opts[:colors], :enabled, IO.ANSI.enabled?()),
      width: get_terminal_width(),
      slowest: opts[:slowest],
      test_counter: %{},
      test_timings: [],
      failure_counter: 0,
      skipped_counter: 0,
      excluded_counter: 0,
      invalid_counter: 0
    }

    {:ok, config}
  end

  def handle_cast({:suite_started, _opts}, config) do
    IO.puts("Started")
    {:noreply, config}
  end

  def handle_cast({:suite_finished, run_us, load_us}, config) do
    IO.inspect({{:suite_finished, run_us, load_us}, config}, label: "Finished")
    {:noreply, config}
  end

  def handle_cast(_, config) do
    {:noreply, config}
  end

  defp get_terminal_width do
    case :io.columns() do
      {:ok, width} -> max(40, width)
      _ -> 80
    end
  end
end

ExUnit.configure(formatters: [ExUnit.CLIFormatter, LazyFor.CLIFormatter])

ExUnit.start()
