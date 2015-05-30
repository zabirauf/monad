defmodule Monad.Reader do
  use Monad
  use Monad.Pipeline

  @moduledoc """
  The Reader monad.

  Monad that encapsulates a read-only value/shared environment.

  ## Examples

      iex> require Monad.Reader, as: Reader
      iex> import Reader
      iex> r = Reader.m do
      ...>       let a = 2
      ...>       b <- ask
      ...>       return a + b
      ...>     end
      iex> Reader.run(10, r)
      12
  """

  # A reader is just a function that receives the read-only value.
  @opaque reader_m :: (any -> any)

  ## Monad implementations

  @spec bind(reader_m, (any -> reader_m)) :: reader_m
  def bind(r, f), do: fn x -> f.(r.(x)).(x) end

  @doc """
  Inject `x` into a Reader monad.
  """
  @spec return(any) :: reader_m
  def return(x), do: fn _ -> x end

  ## Other functions

  @doc """
  Run Reader monad `r` by supplying it with value `x`.
  """
  @spec run(any, reader_m) :: any
  def run(x, r), do: r.(x)

  @doc """
  Ask for the Reader monad's value.
  """
  @spec ask() :: reader_m
  def ask(), do: fn x -> x end

  @doc """
  Set a different value locally for the Reader monad.
  """
  @spec local(reader_m, (any -> any)) :: reader_m
  def local(r, f), do: fn x -> r.(f.(x)) end
end
