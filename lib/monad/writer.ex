defmodule Monad.Writer do
  use Behaviour

  @moduledoc """
  The Writer monad.

  Allows saving output values "under the hood".

  To use this you'll first need to create a writer module with the desired
  combining semantics.

  The writer is lazy, only when you run it will the functions in the monad be
  evaluated.

  Note that the writer monad module needs to be defined outside of the module
  that uses it due to an Elixir restriction.

  ## Examples

      # Outside the module.
      defmodule ListWriter do
        def initial, do: []
        def combine(new, acc), do: acc ++ new
      end

      # In the module.
      alias ListWriter, as: LW
      use Monad
      w = ListWriter.m do
            LW.tell [1]
            a <- return 2
            LW.tell [2]
            return a + 1
          end
      w.run()
      # {3, [1|2]}
  """

  @typedoc """
  Represents the output type of the monad in typespecs.
  """
  @type output :: any

  # A writer is just a function that outputs an "under the hood" value
  # or the under the hood value directly.
  @opaque writer_m :: (() -> {any, output})

  defmacro __using__(_env) do
    quote do
      use Monad

      @behaviour Monad.Writer

      alias Monad.Writer, as: W

      @spec bind(W.writer_m, ((any) -> W.writer_m)) :: W.writer_m
      def bind(w, f) do
        fn ->
          { x, acc } = w.()
          { y, new } = f.(x).()
          { y, combine(new, acc) }
        end
      end

      @spec return(any) :: W.writer_m
      def return(x), do: fn -> { x, initial } end

      @doc """
      Run the writer. Returns the return value and the output value.
      """
      @spec run(W.writer_m) :: { any, W.output }
      def run(m), do: m.()

      @doc """
      Add a value to the output. Returns `nil`.
      """
      @spec tell(W.output) :: W.writer_m
      def tell(o), do: fn -> {nil, o} end
    end
  end

  @doc """
  Returns an initial output value.
  """
  defcallback initial() :: output

  @doc """
  Adds a new piece of output to the output list.
  """
  defcallback combine(output, output) :: output
end
