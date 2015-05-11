defmodule Ether do
  @moduledoc """
  `Ether` provides the default macros and functions for debugging
  your applications.

  Besides the functions available in this module, the `Int` module
  exposes more advanced functionality exposed in erlang's debugger
  interface module.
  """

  ### NOTES ###
  # Two different UI modes
  # :dbg_wx_trace - For the wx ui at :debugger.start
  # :dbg_ui_trace - For windows ui?

  @doc """
  Starts the graphical debugger

  start() -> {status, pid} | :error | :ok
  start(mode) -> {status, pid} | :error | :ok
  """
  def start() do
    :debugger.start()
  end
  def start(mode) when mode==:local or mode==:global do
    :debugger.start(mode)
  end


  @doc """
  Stops the graphical debugger

  stop() -> :error | :ok
  """
  def stop() do
    :debugger.stop()
  end


  @doc """
  Starts the graphical debugger
  Loads the module
  Attaches the debugger to the process upon start

  ## Examples

      iex> quick_start(Integer, :to_string, [3])
      "3"

  quick_start(module, function, args) -> result
  """
  def quick_start(module, function, args) do
    start() # Start the debugger if it's not started already
    load(module) # Load the module
    auto_attach([:init]) # Attach the debugger upon module start
    :erlang.apply(module, function, args) # Call the function with args
  end


  @doc """
  Loads the module by name

  ## Examples

      iex> Ether.load(Ether)
      {:module, Ether}

  load(module) -> {:module, module}
  """
  def load(module), do: Int.i(module)

  @doc """
  Unloads the module by name

  ## Examples

      iex> Ether.unload(Ether)
      :ok

  unload(module) -> :error | :ok
  """
  def unload(module), do: Int.n(module)


  @doc """
  Checks what modules have been loaded

  loaded?() -> [modules]
  loaded?(module) -> true | false
  """
  def loaded?(), do: Int.interpreted
  def loaded?(module), do: Enum.member?(loaded?, module)


  @doc """
  Attaches the debugger

  Flags:
    :init - Upon Initialization
    :break - Upon Break
    :exit - Upon Exit

  ## Examples

      iex> Ether.attach([:init])
      :ok

  attach(flags) -> :ok, false
  """
  def attach(flags), do: auto_attach(flags)

  defp auto_attach(flags) do
    case which_gui() do
	    :gs -> :int.auto_attach(flags, {:dbg_ui_trace, :start, []})
	    :wx -> :int.auto_attach(flags, {:dbg_wx_trace, :start, []})
    end
  end

  defp which_gui() do
    try do
	    :wx.new()
	    :wx.destroy()
	    :wx
    catch
      _ -> :gs
    end
  end


  @doc """
  Displays information about what the debugger is attached to

  attached?() -> {flags, function} | false
  """
  def attached?(), do: Int.auto_attach


  @doc """
  Unattaches the debugger

  unattach() -> :ok
  """
  def unattach(), do: Int.auto_attach(false)


  @doc """
  List all breakpoints

  breakpoints() ->
  """
  def breakpoints(), do: Int.all_breaks()


  @doc """
  Enable a breakpoint for a module at a specified line number

  ## Examples

      iex> Ether.enable_breakpoint(Ether, 134)
      :ok

  enable_breakpoint(module, line) -> :ok
  """
  def enable_breakpoint(module, line) do
    Int.enable_break(module, line)
  end


  @doc """
  Enable many or all breakpoints

  enable_breakpoints() -> :ok
  enable_breakpoints([{module, line}]) -> :ok
  """
  def enable_breakpoints() do
    list = Enum.map Int.all_breaks, fn({x,_}) -> x end
    enable_breakpoints list
  end
  def enable_breakpoints(breakpoints) when is_list breakpoints do
    breakpoints |>
    Enum.each fn({{mod, line}, _options}) -> Int.enable_break(mod, line) end
  end


  @doc """
  Disable a breakpoint for a module at a specified line number

  ## Examples

      iex> Ether.disable_breakpoint(Ether, 134)
      :ok

  disable_breakpoint(module, line) -> :ok
  """
  def disable_breakpoint(module, line) do
    Int.disable_breakpoint(module, line)
  end


  @doc """
  Disable many or all breakpoints

  disable_breakpoints() -> :ok
  disable_breakpoints([{module, line}]) -> :ok
  """
  def disable_breakpoints() do
    list = Enum.map Int.all_breaks, fn({x,_}) -> x end
    disable_breakpoints list
  end
  def disable_breakpoints(breakpoints) when is_list breakpoints do
    breakpoints |>
    Enum.each fn({mod, line}) -> Int.disable_break(mod, line) end
  end


  @doc """
  Delete a breakpoint for a module at a specified line number

  ## Examples

      iex> Ether.delete_breakpoint(module, line)
      :ok

  delete_breakpoint(module, line) -> :ok | {:error, :function_not_found}
  """
  def delete_breakpoint(module, line) do
    Int.delete_breakpoint(module, line)
  end


  @doc """
  Delete many or all breakpoints

  delete_breakpoints() -> :ok
  delete_breakpoints([{module, line}]) -> :ok | :error
  """
  def delete_breakpoints(), do: Int.no_break
  def delete_breakpoints(breakpoints) do
    breakpoints |>
    Enum.each fn({{mod, line}, _options}) -> Int.delete_break(mod, line) end
  end


  @doc """
  Add a breakpoint

  ## Examples

      iex> Ether.add_breakpoint(Ether, 123)
      :ok

      iex> Ether.add_breakpoint(Ether, 123, fn -> IO.puts "Broken" end)
      :ok

  add_breakpoint(module, line) -> :ok | {:error, :break_exists}
  add_breakpoint(module, line, action) -> :ok | {:error | :break_exists}
  """
  def add_breakpoint(module, line) do
    Int.break(module, line)
  end
  def add_breakpoint(module, line, action) do
    status = Int.break(module, line)
    set_action(module, line, action)
    status
  end


  @doc """
  Sets an action upon breaking

  set_action(module, line, action) -> :ok
  """
  def set_action(module, line, action) do
    Int.action_at_break(module, line, action)
  end

  ########################################
  # Actions while attached
  ########################################

  @doc """
  Resume the debugger

  resume(meta_pid) -> :ok
  """
  def resume(meta_pid) when is_pid meta_pid do
    Int.continue(meta_pid)
  end


  @doc """
  Suspend the debugger

  suspend(meta_pid) -> :ok
  """
  def suspend(meta_pid) when is_pid meta_pid do
    :dbg_icmd.stop(meta_pid)
  end


  @doc """
  Step into

  step_into(pid) -> :ok
  """
  def step_into(pid) do
    Int.step(pid)
  end


  @doc """
  Step over

  step_over(pid) -> :ok
  """
  def step_over(pid) do
    Int.next(pid)
  end


  @doc """
  Step out of

  step_out(pid) -> :ok
  """
  def step_out(pid) do
    Int.finish(pid)
  end


  @doc """

  """


end
