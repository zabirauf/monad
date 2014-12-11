defmodule Monad.Maybe do
  use Monad
  use Monad.Pipeline

  @moduledoc """
  The Maybe monad.

  The `Maybe` monad encapsulates an optional value. A `maybe` monad either
  contains a value `x` (represented as "`{:just, x}`") or is empty (represented
  as "`:nothing`").

  `Maybe` can be used a simple kind of error monad, where all errors are
  represented by `:nothing`.

  ## Examples

      iex> require Monad.Maybe, as: Maybe
      iex> Maybe.m do
      ...>   x <- {:just, 1}
      ...>   y <- {:just, 2}
      ...>   return x + y
      ...> end
      {:just, 3}

      iex> require Monad.Maybe, as: Maybe
      iex> Maybe.m do
      ...>   x <- {:just, 1}
      ...>   y <- :nothing
      ...>   return x + y
      ...> end
      :nothing
  """

  @type maybe_m :: {:just, any} | :nothing

  ## Monad implementations

  @spec bind(maybe_m, (any -> maybe_m)) :: maybe_m
  @doc """
  Bind the value inside Maybe monad `m` to function `f`.

  Note that the computation shortcircuits if `m` is `:nothing`.
  """
  def bind(m, f)
  def bind({:just, x}, f), do: f.(x)
  def bind(:nothing, _), do: :nothing

  @doc """
  Inject `x` into a Maybe monad, i.e. returns `{:just, x}`.
  """
  @spec return(any) :: maybe_m
  def return(x), do: {:just, x}

  ## Auxiliary functions

  @doc """
  Signal failure, i.e. returns `:nothing`.
  """
  @spec fail(any) :: maybe_m
  def fail(msg)
  def fail(_), do: :nothing

  @doc """
  Call function `f` with `x` if `m` is `{:just, x}`, otherwise call function `f`
  with default value `d`.
  """
  @spec maybe(any, (any -> any), maybe_m) :: any
  def maybe(d, f, m)
  def maybe(_, f, {:just, x}), do: f.(x)
  def maybe(d, f, :nothing), do: f.(d)

  @doc """
  Returns true if given `{:just, x}` and false if given `:nothing`.
  """
  @spec is_just(maybe_m) :: boolean
  def is_just({:just, _}), do: true
  def is_just(:nothing), do: false

  @doc """
  Returns true if given `:nothing` value and false if given `{:just, x}`.
  """
  @spec is_nothing(maybe_m) :: boolean
  def is_nothing(:nothing), do: true
  def is_nothing({:just, _}), do: false

  @doc """
  Extracts value `x` out of `{:just, x}` or raises an error if given `:nothing`.
  """
  @spec from_just(maybe_m) :: any
  def from_just(m)
  def from_just({:just, x}), do: x
  def from_just(:nothing), do: raise "Monad.Maybe.from_just: :nothing"

  @doc """
  Extracts value `x` out of `{:just, x}` or returns default `d` if given
  `:nothing`.
  """
  @spec from_maybe(any, maybe_m) :: any
  def from_maybe(d, m)
  def from_maybe(_, {:just, x}), do: x
  def from_maybe(d, :nothing), do: d

  @doc """
  Converts maybe value `m` to a list.

  Returns an empty list if given `:nothing` or returns a list `[x]` if given
  `{:just, x}`.

  ## Examples

      iex> maybe_to_list :nothing
      []

      iex> maybe_to_list {:just, 42}
      [42]

  """
  @spec maybe_to_list(maybe_m) :: [any]
  def maybe_to_list(m)
  def maybe_to_list({:just, x}), do: [x]
  def maybe_to_list(:nothing), do: []

  @doc """
  Converts list `l` to a maybe value.

  Returns `:nothing` if given the empty list; returns `{:just, x}` when given
  the nonempty list `l`, where `x` is the head of `l`.

  ## Examples

      iex> list_to_maybe []
      :nothing

      iex> list_to_maybe [1, 2, 3]
      {:just, 1}

  """
  @spec list_to_maybe([any]) :: maybe_m
  def list_to_maybe(l)
  def list_to_maybe([x | _]), do: {:just, x}
  def list_to_maybe([]), do: :nothing

  @doc """
  Takes a list of `maybe`s and returns a list of all the `just` values.

  ## Example

      iex> cat_maybes [{:just, 1}, :nothing, {:just, 2}, :nothing, {:just, 3}]
      [1, 2, 3]

  """
  @spec cat_maybes([maybe_m]) :: [any]
  def cat_maybes(l) do
    for x <- l, is_just(x), do: from_just x
  end

  @doc """
  Map function `f` over the list `l` and throw out elements for which `f`
  returns `:nothing`.
  """
  @spec map_maybes((any -> maybe_m), [any]) :: [any]
  def map_maybes(f, l) do
    for x <- l, is_just(f.(x)), do: from_just f.(x)
  end
end
