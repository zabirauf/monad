defmodule Monad.State do
  use Monad
  use Monad.Pipeline

  @moduledoc """
  The State monad.

  The State monad allows for stateful computations while using pure
  functions. Computations of this kind can be represented by state transformers,
  i.e. by functions that map an initial state to a result value paired with a
  final state.

  ## Examples

      iex> require Monad.State, as: State
      iex> import State
      iex> s = State.m do
      ...>       a <- get
      ...>       put (a + 1)
      ...>       return a + 10
      ...>     end
      iex> State.run(2, s)
      {12, 3}
  """

  # A state monad is just a function that receives the "under the hood" state
  # value and returns a new state.
  @type state :: any
  @opaque state_m :: (state -> {any, state})

  ## Monad implementations

  @spec bind(state_m, (any -> state_m)) :: state_m
  def bind(s, f) do
    fn st ->
      {x, st1} = s.(st)
      f.(x).(st1)
    end
  end

  @spec return(any) :: state_m
  @doc """
  Inject `x` into a State monad.
  """
  def return(x), do: fn st -> {x, st} end

  ## Other functions

  @doc """
  Run the State monad `m` with `x` as the value of the initial state.

  Returns a tuple where the first element is the result of the computation and
  the second element is the final state.
  """
  @spec run(any, state_m) :: {any, state}
  def run(x, m), do: m.(x)

  @doc """
  Get the state.
  """
  @spec get() :: state_m
  def get(), do: fn st -> {st, st} end

  @doc """
  Set a new state.

  Returns `nil`.
  """
  @spec put(state) :: state_m
  def put(st), do: fn _ -> {nil, st} end

  @doc """
  Modify the state.

  Returns `nil`.
  """
  @spec modify((state -> state)) :: state_m
  def modify(f), do: fn st -> {nil, f.(st)} end
end
