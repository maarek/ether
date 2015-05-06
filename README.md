[![Build Status](https://api.travis-ci.org/maarek/ether.svg?branch=master)](https://travis-ci.org/maarek/ether) | [![Inline docs](http://inch-ci.org/github/maarek/ether.svg?branch=develop)](http://inch-ci.org/github/maarek/ether)

Ether
=====

`Ether` provides functionality to hook Elixir into the Erlang debugger.

Since this project is new a short disclaimer is in order. Presently, 
`Ether` currently only wraps Erlang's int module. This module is the 
Interpreter Interface and it's primary use is with the debugger 
modules included in erlang. Since erlang can change their debugger 
at any time, this might be a little unstable. Hopefully as things 
advance, we can move away from that dependency and advance an elixir 
debugger.

## Install As Dependency

As a dependency to a mix.es file:
```elixir
def application() do
  [applications: [:ether]]
end

defp deps do
  [{:ether, github: "maarek/ether"}]
end
```

```
$ mix deps.get
```
