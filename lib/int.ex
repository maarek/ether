defmodule Int do
  @moduledoc """
  Implements functions from the erlang debugger interface module.
  Since elixir has poor access to the erlang debugger, this provides
  an easy interface to work with the debugger from the repl.

  Erlang Documentation is provided in the comments.

  Unecessary function calls are passed through to the erlang :int module.

  ==Erlang Interpreter================================================

  int
  ---
  Interface module.

  i
  -
  Interface module to int, retained for backwards compatibility only.

  dbg_debugged
  ------------
  Contains the message loops for a debugged process and is the main
  entry point from the breakpoint handler in the error_handler module
  (via the int module).

  When a process is debugged, most code is executed in another
  process, called the meta process. When the meta process is
  interpreting code, the process being debugged just waits in a
  receive loop in dbg_debugged. However the debugged process itself
  calls any BIFs that must execute in the correct process (such as
  link/1 and spawn_link/1), and external code which is not
  interpreted.

  dbg_icmd, dbg_ieval
  -------------------
  Code for the meta process.

  dbg_iserver
  -----------
  Interpreter main process, keeping and distributing information
  about interpreted modules and debugged processes.

  dbg_idb
  -------
  ETS wrapper, allowing transparent access to tables at a remote node.

  dbg_iload
  ---------
  Code for interpreting a module.
 ====================================================================
"""

# %%====================================================================
# %% External exports
# %%====================================================================
#
  @doc """
  --------------------------------------------------------------------
  i(AbsMods) -> {module,Mod} | error | ok
  ni(AbsMods) -> {module,Mod} | error | ok
    AbsMods = AbsMod | [AbsMod]
    AbsMod = atom() | string()
    Mod = atom()
     Options = term() ignored
  --------------------------------------------------------------------
  ## Examples
    iex> Int.i(Int)
    {:module, Int}
  """
  def i(absMods), do: i2(absMods, :local, :ok)
  def i(absMods, _options), do: i2(absMods, :local, :ok)
  def ni(absMods), do: i2(absMods, :distributed, :ok)
  def ni(absMods, _options), do: i2(absMods, :distributed, :ok)

  defp i2([absMod|absMods], dist, acc)
  when is_atom(absMod) or is_list(absMod) or is_tuple(absMod) do
    res = int_mod(absMod, dist)
    case acc do
	     :error ->
	        i2(absMods, dist, acc)
	     _ ->
	        i2(absMods, dist, res)
    end
  end

  defp i2([], _dist, acc), do: acc

  defp i2(absMod, dist, _acc)
  when is_atom(absMod) or is_list(absMod) or is_tuple(absMod) do
    int_mod(absMod, dist)
  end

  @doc """
  --------------------------------------------------------------------
  n(AbsMods) -> ok
  nn(AbsMods) -> ok
  --------------------------------------------------------------------
  ## Examples

  """
  def n(absMods), do: :int.n(absMods)
  def nn(absMods), do: :int.nn(absMods)

  defp n2([absMod|absMods], dist) when is_atom(absMod) or is_list(absMod) do
    :int.n2(absMod <> absMods, dist)
  end

  defp n2([absMod], dist) when is_atom(absMod) or is_list(absMod), do: :int.del_mod(absMod, dist)
  defp n2([], _dist), do: :int.n2([], _dist)
  defp n2(absMod, dist) when is_atom(absMod) or is_list(absMod), do: :int.del_mod(absMod, dist)

  @doc """
  --------------------------------------------------------------------
  interpreted() -> [Mod]
  --------------------------------------------------------------------
  """
  def interpreted(), do: :int.interpreted()

  @doc """
  --------------------------------------------------------------------
  file(Mod) -> File | {error, not_loaded}
    Mod = atom()
    File = string()
  --------------------------------------------------------------------
  """
  def file(mod) when is_atom(mod), do: :int.file(mod)

  @doc """
  --------------------------------------------------------------------
  interpretable(AbsMod) -> true | {error, Reason}
    AbsMod = Mod | File
    Reason = no_src | no_beam | no_debug_info | badarg | {app, App}
  --------------------------------------------------------------------
  """
  def interpretable(absMod) do
    case check(absMod) do
      {:ok, _Res} -> true
      error -> error
    end
  end

  @doc """
  --------------------------------------------------------------------
  auto_attach() -> false | {Flags, Function}
  auto_attach(false)
  auto_attach(false|Flags, Function)
    Flags = Flag | [Flag]
      Flag = init | break | exit
    Function = {Mod, Func} | {Mod, Func, Args}
  Will result in calling:
    spawn(Mod, Func, [Dist, Pid, Meta | Args]) (living process) or
    spawn(Mod, Func, [Dist, Pid, Reason, Info | Args]) (dead process)
  --------------------------------------------------------------------
  """
  def auto_attach(), do: :int.auto_attach()

  def auto_attach(false), do: :int.auto_attach(false)

  def auto_attach([], _function), do: :int.auto_attach([], _function)
  def auto_attach(flags, {mod, func}), do: :int.auto_attach(flags, {mod, func})
  def auto_attach(flags, {mod, func, args}) when is_atom(mod) and is_atom(func) and is_list(args) do
    :int.auto_attach(flags, {mod, func, args})
  end

  @doc """
  --------------------------------------------------------------------
  stack_trace() -> Flag
  stack_trace(Flag)
    Flag = all | true | no_tail | false
  --------------------------------------------------------------------
  """
  def stack_trace(), do: :int.stack_trace()

  def stack_trace(true), do: :int.stack_trace(true)
  def stack_trace(flag), do: :int.stack_trace(flag)

  @doc """
  --------------------------------------------------------------------
  break(Mod, Line) -> ok | {error, break_exists}
  delete_break(Mod, Line) -> ok
  break_in(Mod, Func, Arity) -> ok | {error, function_not_found}
  del_break_in(Mod, Function, Arity) -> ok | {error, function_not_found}
  no_break()
  no_break(Mod)
  disable_break(Mod, Line) -> ok
  enable_break(Mod, Line) -> ok
  action_at_break(Mod, Line, Action) -> ok
  test_at_break(Mod, Line, Function) -> ok
  get_binding(Var, Bindings) -> {value, Value} | unbound
  all_breaks() -> [Break]
  all_breaks(Mod) -> [Break]
    Mod = atom()
    Line = integer()
    Func = atom() function name
    Arity = integer()
    Action = enable | disable | delete
    Function = {Mod, Func} must have arity 1 (Bindings)
    Var = atom()
    Bindings = Value = term()
    Break = {Point, Options}
      Point = {Mod, Line}
      Options = [Status, Action, null, Cond]
        Status = active | inactive
        Cond = null | Function
  --------------------------------------------------------------------
  """
  def break(mod, line) when is_atom(mod) and is_integer(line) do
    :int.break(mod, line)
  end

  def delete_break(mod, line) when is_atom(mod) and is_integer(line) do
    :int.delete_break(mod, line)
  end

  def break_in(mod, func, arity) when is_atom(mod) and is_atom(func) and is_integer(arity) do
    :int.del_break_in(mod, func,arity)
  end

  def del_break_in(mod, func, arity) when is_atom(mod) and is_atom(func) and is_integer(arity) do
    :int.del_break_in(mod, func, arity)
  end

  def no_break(), do: :int.no_break()

  def no_break(mod) when is_atom(mod), do: :int.no_break(mod)

  def disable_break(mod, line) when is_atom(mod) and is_integer(line) do
    :int.disable_break(mod, line)
  end

  def enable_break(mod, line) when is_atom(mod) and is_integer(line) do
    :int.enable_break(mod, line)
  end

  def action_at_break(mod, line, action) when is_atom(mod) and is_integer(line) do
    :int.action_at_break(mod, line, action)
  end

  def test_at_break(mod, line, function) when is_atom(mod) and is_integer(line) do
    :int.test_at_break(mod, line, function)
  end

  def get_binding(var, bs), do: :int.get_binding(var, bs)

  def all_breaks(), do: :int.all_breaks()
  def all_breaks(mod) when is_atom(mod), do: :int.all_breaks(mod)

  @doc """
  --------------------------------------------------------------------
  snapshot() -> [{Pid, Init, Status, Info}]
    Pid = pid()
    Init = atom()  First interpreted function
    Status = idle | running | waiting | break | exit
    Info = {} | {Mod, Line} | ExitReason
      Mod = atom()
      Line = integer()
      ExitReason = term()
  --------------------------------------------------------------------
  """
  def snapshot(), do: :int.snapshot()

  @doc """
  --------------------------------------------------------------------
  clear()
  --------------------------------------------------------------------
  """
  def clear(), do: :int.clear()

  @doc """
  --------------------------------------------------------------------
  continue(Pid) -> ok | {error, not_interpreted}
  continue(X, Y, Z) -> ok | {error, not_interpreted}
  --------------------------------------------------------------------
  """
  def continue(pid) when is_pid(pid), do: :int.continue(pid)
  def continue(x, y, z) when is_integer(x) and is_integer(y) and is_integer(z), do: :int.continue(x, y, z)


# %%====================================================================
# %% External exports only to be used by Debugger
# %%====================================================================

  @doc """
  --------------------------------------------------------------------
  start()
  stop()
  Functions for starting and stopping dbg_iserver explicitly.
  --------------------------------------------------------------------
  """
  def start(), do: :int.start()
  def stop(),  do: :int.stop()

  @doc """
  --------------------------------------------------------------------
  subscribe()
  Subscribe to information from dbg_iserver. The process calling this
  function will receive the following messages:
    {int, {interpret, Mod}}
    {int, {no_interpret, Mod}}
    {int, {new_process, Pid, Function, Status, Info}}
    {int, {new_status, Pid, Status, Info}}
    {int, {new_break, {Point, Options}}}
    {int, {delete_break, Point}}
    {int, {break_options, {Point, Options}}}
    {int, no_break}
    {int, {no_break, Mod}}
    {int, {auto_attach, false|{Flags, Function}}}
    {int, {stack_trace, Flag}}
  --------------------------------------------------------------------
  """
  def subscribe(), do: :int.subscribe()

  @doc """
  --------------------------------------------------------------------
  attach(Pid, Function)
    Pid = pid()
    Function = {Mod, Func} | {Mod, Func, Args} (see auto_attach/2)
  Tell dbg_iserver to attach to Pid using Function. Will result in:
    spawn(Mod, Func, [Pid, Status | Args])
  --------------------------------------------------------------------
  """
  def attach(pid, {mod, func}), do: :int.attach(pid, {mod, func})
  def attach(pid, function),    do: :int.attach(pid, function)

  @doc """
  --------------------------------------------------------------------
  step(Pid)
  next(Pid)
  (continue(Pid))
  finish(Pid)
  --------------------------------------------------------------------
  """
  def step(pid),   do: :int.step(pid)
  def next(pid),   do: :int.next(pid)
  def finish(pid), do: :int.finish(pid)

# %%====================================================================
# %% External exports only to be used by an attached process
# %%====================================================================

  @doc """
  --------------------------------------------------------------------
  attached(Pid) -> {ok, Meta} | error
    Pid = Meta = pid()
  Tell dbg_iserver that I have attached to Pid. dbg_iserver informs
  the meta process and returns its pid. dbg_iserver may also refuse,
  if there already is a process attached to Pid.
  --------------------------------------------------------------------
  """
  def attached(pid), do: :int.attached(pid)

  @doc """
  --------------------------------------------------------------------
  meta(Meta, Cmd)
    Meta = pid()
    Cmd = step | next | continue | finish | skip | timeout | stop
    Cmd = messages => [Message]
  meta(Meta, Cmd, Arg)
    Cmd = trace,       Arg = bool()
    Cmd = stack_trace  Arg = all | notail | false
    Cmd = stack_frame  Arg = {up|down, Sp}
        => {Sp, Mod, Line} | top | bottom
    Cmd = backtrace    Arg = integer()
        => {Sp, Mod, {Func, Arity}, Line}
    Cmd = eval        Arg = {Cm, Cmd} | {Cm, Cmd, Sp}
  --------------------------------------------------------------------
  """
  def meta(meta, :step),        do: :int.meta(meta, :step)
  def meta(meta, :next),        do: :int.meta(meta, :next)
  def meta(meta, :continue),    do: :int.meta(meta, :continue)
  def meta(meta, :finish),      do: :int.meta(meta, :finish)
  def meta(meta, :skip),        do: :int.meta(meta, :skip)
  def meta(meta, :timeout),     do: :int.meta(meta, :timeout)
  def meta(meta, :stop),        do: :int.meta(meta, :stop)
  def meta(meta, :messages),    do: :int.meta(meta, :messages)

  def meta(meta, :trace, trace),      do: :int.meta(meta, :trace, trace)
  def meta(meta, :stack_trace, flag), do: :int.meta(meta, :stack_trace, flag)
  def meta(meta, :bindings, stack),   do: :int.meta(meta, :bindings, stack)
  def meta(meta, :stack_frame, arg),  do: :int.meta(meta, :stack_frame, arg)
  def meta(meta, :backtrace, n),      do: :int.meta(meta, :backtrace, n)
  def meta(meta, :eval, arg),         do: :int.meta(meta, :eval, arg)

  @doc """
  --------------------------------------------------------------------
  contents(Mod, Pid) -> string()
    Mod = atom()
    Pid = pid() | any
  Return the contents of an interpreted module.
  --------------------------------------------------------------------
  """
  def contents(mod, pid) do
    :int.contents(mod, pid)
  end

  @doc """
  --------------------------------------------------------------------
  functions(Mod) -> [[Name, Arity]]
    Mod = Name = atom()
    Arity = integer()
  --------------------------------------------------------------------
  """
  def functions(mod) do
    :int.functions(mod)
  end

# %%====================================================================
# %% External exports only to be used by error_handler
# %%====================================================================

  def eval(mod, func, args) do
     :int.eval(mod, func, args)
  end

# %%====================================================================
# %% Internal functions
# %%====================================================================

  defp int_mod({mod, src, beam, beamBin}, dist)
  when is_atom(mod) and is_list(src) and is_list(beam) and is_binary(beamBin) do
    try do
	    case is_file(src) do
	      true ->
		      check_application(src)
		      case check_beam(beamBin) do
		        {:ok, exp, abst, _beamBin} ->
			        load({mod, src, beam, beamBin, exp, abst}, dist)
            :error ->
              :error
          end
        false ->
		      :error
	    end
    catch
	    reason ->
	      reason
    end
  end

  defp int_mod(absMod, dist) when is_atom(absMod) or is_list(absMod) do
    case check(absMod) do
	    {:ok, res} ->
	      load(res, dist)
	    {:error, {:app, app}} ->
	      :io.format("** Cannot interpret ~p module: ~p~n", [app, absMod])
        :error
	    _error ->
	      :io.format("** Invalid beam file or no abstract code: ~tp\n", [absMod])
	      :error
    end
  end

  defp check(mod) when is_atom(mod) do
    try do
      check_module(mod)
    catch
      x -> x
    end
  end

  defp check(file) when is_list(file) do
    try do
      check_file(file)
    catch
      x -> x
    end
  end

  defp load({mod, src, beam, beamBin, exp, abst}, dist) do
    everywhere(dist,
  	           fn () ->
  		           :code.purge(mod)
  		           :erts_debug.breakpoint({mod,:_,:_}, false)
  		           {:module, mod} = :code.load_binary(mod, beam, beamBin)
  	           end)
    case :erl_prim_loader.get_file(:filename.absname(src)) do
  	  {:ok, srcBin, _} ->
  	    md5 = :code.module_md5(beamBin)
  	    bin = :erlang.term_to_binary({:interpreter_module, exp, abst,srcBin,md5})
  	    {:module, mod} = :dbg_iserver.safe_call({:load, mod, src, bin})
  	    everywhere(dist,
  		             fn () ->
  			             true = :erts_debug.breakpoint({mod,:_,:_}, true) > 0
  		             end)
  	    {:module, mod};
  	  :error ->
  	    :error
    end
  end

  defp check_module(mod) do
    case :code.which(mod) do    # Gets the path to the beam file
	    beam when is_list(beam) -> # Yes it'll be a char list
	      case find_src(mod, beam) do   # We need to get the source path
		      src when is_list(src) ->
		        check_application(src)
		        case check_beam(beam) do
			        {:ok, exp, abst, beamBin} ->
			          {:ok, {mod, src, beam, beamBin, exp, abst}}
			        :error ->
			          {:error, :no_debug_info}
		        end
		      :error ->
		        {:error, :no_src}
	      end
	    _ ->
	      {:error, :badarg}
    end
  end

  defp check_file(name0) do
    src =
	    case is_file(name0) do
	      true -> name0
	      false ->
          name = name0 <> ".erl"
		      case is_file(name) do
		        true -> name
		        false ->
              name = name0 <> ".ex"
              case is_file(name) do
                true -> name
                false -> :error
              end
		      end
	    end
    cond do
      is_list(src) ->
	      check_application(src)
	      mod = :int.scan_module_name(src)
	      case :int.find_beam(mod, src) do
		      beam when is_list(beam) ->
		        case check_beam(Beam) do
			        {:ok, exp, abst, beamBin} ->
			          {:ok, {mod, src, beam, beamBin, exp, abst}}
			        :error ->
			          {:error, :no_debug_info}
		        end
		      :error ->
		        {:error, :no_beam}
	      end
	    true ->
	      {:error, :badarg}
    end
  end


  # Try to avoid interpreting a kernel, stdlib, gs or debugger module.
  defp check_application(src) do
    case :lists.reverse(:filename.split(:filename.absname(src))) do
	    [_mod, "src", appS|_] ->
	      check_application2(appS)
	    _ -> :ok
    end
  end
  defp check_application2("kernel-" <> _), do: throw({:error,{:app,:kernel}})
  defp check_application2("stdlib-" <> _), do: throw({:error,{:app,:stdlib}})
  defp check_application2("erts-" <> _), do: throw({:error,{:app,:erts}})
  defp check_application2("gs-" <> _), do: throw({:error,{:app,:gs}})
  defp check_application2("debugger-" <> _), do: throw({:error,{:app,:debugger}})
  defp check_application2(_), do: :ok

  defp find_src(mod, beam) do
    src0 = :filename.rootname(List.to_string(beam)) <> ".erl"
    case is_file(src0) do
	    true -> src0
	    false ->
	      ebinDir = :filename.dirname(beam)
	      src = :filename.join([:filename.dirname(ebinDir), "src", :filename.basename(src0)])
	      case is_file(src) do
		      true -> src
		      false -> # Check if it could be from elixir
            src0 = mod.__info__(:compile)[:source]
            # src0 = :filename.rootname(List.to_string(beam)) <> ".ex"
            case is_file(src0) do
              true -> src0
              false ->
                ebinDir = :filename.dirname(beam)
                src = :filename.join([:filename.dirname(ebinDir), "src", :filename.basename(src0)])
                case is_file(src) do
                  true -> src
                  false -> :error
                end
            end
	      end
    end
  end

  defp check_beam(beamBin) when is_binary(beamBin) do
    case :beam_lib.chunks(beamBin, [:abstract_code, :exports]) do
	    {:ok,{_mod,[{:abstract_code,:no_abstract_code}|_]}} ->
	      :error
	    {:ok,{_mod,[{:abstract_code,abst},{:exports,exp}]}} ->
	      {:ok, exp, abst, beamBin}
	     _ ->
	       :error
    end
  end

  defp check_beam(beam) when is_list(beam) do
    {:ok, bin, _fullPath} = :erl_prim_loader.get_file(:filename.absname(beam))
    check_beam(bin)
  end

  defp is_file(name) do
    :filelib.is_regular(:filename.absname(name)) #, :erl_prim_loader)
  end

  defp everywhere(:distributed, fun) do
    case Process.alive?(self()) do
	    true -> :rpc.multicall(:erlang, :apply, [fun,[]])
	    false -> fun.()
    end
  end

  defp everywhere(:local, fun), do: fun.()

  defp scan_module_name(file) do
    try do
      {:ok, bin, _fullPath} = :erl_prim_loader.get_file(:filename.absname(file))
        scan_module_name_1([], <<>>, bin, enc(bin))
    catch
        _, _ ->
            throw({:error, :no_beam})
    end
  end

  defp scan_module_name_1(cont0, b0, bin0, enc) do
    n = min(100, byte_size(bin0))
    {bin1, bin} = :erlang.split_binary(bin0, n)
    {chars, b1} =
      case :unicode.characters_to_list(:erlang.list_to_binary([b0, bin1]), enc) do
        {:incomplete, list, binary} -> {list, binary}
        list when is_list(list) and list != [] -> {list, <<>>}
      end
    scan_module_name_2(cont0, chars, b1, bin, enc)
  end

  defp scan_module_name_2(cont0, chars, b1, bin, enc) do
    case :erl_scan.tokens(cont0, chars, _anyLine \\ 1) do
      {:done, {:ok, ts, _}, rest} ->
        scan_module_name_3(ts, rest, b1, bin, enc)
      {:more, cont} ->
        scan_module_name_1(cont, b1, bin, enc)
    end
  end

  defp scan_module_name_3([{'-',_},{:atom,_,:module},{'(',_} | _]=ts,
                   _chars, _b1, _bin, _enc) do
    scan_module_name_4(ts)
  end

  defp scan_module_name_3([{'-',_},{:atom,_,_} | _], chars, b1, bin, enc) do
    scan_module_name_2("", chars, b1, bin, enc)
  end

  defp scan_module_name_4(ts) do
    {:ok, {:attribute,_,:module,m}} = :erl_parse.parse_form(ts)
    true = is_atom(m)
    m
  end

  defp enc(bin) do
    case :epp.read_encoding_from_binary(bin) do
      :none -> :epp.default_encoding()
      encoding -> encoding
    end
  end

end
