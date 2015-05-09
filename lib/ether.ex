defmodule Ether do
  @moduledoc """
  `Ether` provides the default macros and functions for debugging
  your applications.

  Besides the functions available in this module, the `Int` module
  exposes more advanced functionality exposed in erlang's debugger
  interface module.
  """

  @doc """
  start() -> {status, pid} | error | ok
  start(mode) -> {status, pid} | error | ok
  """
  def start() do
    :debugger.start(:global, :default, :default)
  end
  def start(mode) when mode==:local or mode==:global do
    :debugger.start(mode, :default, :default)
  end

  @doc """
  stop()
  """
  def stop() do
    :debugger.stop()
  end

  @doc """
  quick_start(module, function, args)
  """
  def quick_start(module, function, args) do
    start() # Start the debugger if it's not started already
    Int.i(module) # Load the module
    Int.auto_attach([:init], {:dbg_wx_trace, :start, []}) # Attach the debugger upon module start
    :erlang.apply(module, function, args) # Call the function with args
  end

end
