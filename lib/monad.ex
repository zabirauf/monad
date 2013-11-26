defmodule Monad do
  use Behaviour

  @moduledoc """
  Behaviour that provides monadic do-notation and pipe-notation.

  ## Terminology

  The term "monad" is used here fairly loosely to refer to the whole concept of
  monads. One way of looking at monads is as a kind of "programmable
  semicolon". Monads define what happens between the evaluation of the
  expressions. They control how and whether the results from one expression are
  passed to the next. For a better explanation of what monads are, look
  elsewhere, the internet is full of good (and not so good) monad tutorials;
  e.g. have a look at the
  [HaskellWiki](http://www.haskell.org/haskellwiki/Monads) or read ["Real World
  Haskell"](http://book.realworldhaskell.org/) or ["Learn You a Haskell for
  Great Good!"](http://learnyouahaskell.com/).

  ## Usage

  To use do-notation you need a module that implements Monad's callbacks,
  i.e. the module needs to have `return/1` and `bind/2`.  This allows you to
  write stuff like:

      def call_if_safe_div(f, x, y) do
        require Monad.Maybe, as: Maybe
        import Maybe

        Maybe.m do
          result <- case y == 0 do
                      true  -> fail "division by zero"
                      false -> return x / y
                    end
          return f.(result)
        end
      end

  The example above uses the `Maybe` monad to define `call_if_safe_div/3`. This
  function takes three arguments: a function `f` and two numbers `x` and `y`. If
  `x` is divisible by `y`, then `f` is called with `x / y` and the return value
  is `{:just, f.(x / y)}`, else the computation fails and the return value is
  `:nothing`.

  ## Do-Notation

  The do-notation supported is pretty simple. Basically there are three rules to
  remember:

  1. Every "statement" (i.e. thing on it's own line or separated by `;`) has to
     return a monadic value unless it's a "let statement".

  2. To use the value "inside" a monad write "pattern <- action" where "pattern"
     is a normal Elixir pattern and "action" is some expression which returns a
     monadic value.

  3. To use ordinary Elixir code inside a do-notation block prefix it with
     `let`. For multiple expressions or those for which precedence rules cause
     annoyances you can use `let` with a do block.

  ## Defining Monads

  To define your own monad create a module and use `use Monad`. This marks the
  module as a monad behaviour. You'll need to define `return/1` and `bind/2`.

  Here's an example which defines the `List` monad:

      defmodule Monad.List do
        use Monad

        def return(x), do: [x]
        def bind(x, f), do: Enum.flat_map(x, f)
      end

  ### Monad Laws

  `return/1` and `bind/2` need to obey a few rules (the so-called "monad laws")
  to avoid surprising the user. In the following equivalences `M` stands for
  your monad module, `a` for an arbitrary value, `m` for a monadic value and `f`
  and `g` for functions that given a value return a new monadic value.

  Equivalence means you can always substitute the left side for the right side
  and vice versa in an expression without changing the result or side-effects

  * "left identity": `M.bind(M.return(m), f) <=> f.(m)`
  * "right identity": `M.bind(m, &M.return/1) <=> m`
  * "associativity": `M.bind(m, f) |> M.bind(g) <=> m |> M.bind(fn y -> M.bind(f.(y), g))`

  See the [HaskellWiki](http://www.haskell.org/haskellwiki/Monad_laws) for more
  explanation.

  ## Pipe Support

  For monads that implement the `Monad.Pipeline` behaviour the `p` macro
  supports monadic pipelines. For example:

      Error.p, (File.read("/tmp/foo")
                |> Code.string_to_quoted(file: "/tmp/foo")
                |> Macro.safe_term)

  If any of the terms returns `{:error, x}` then that's the return value of the
  pipeline, when a term returns `{:ok, x}` the value `x` is passed to the next.

  You can also use a `do`-block for less clutter:

      Error.p do
        File.read("/tmp/foo")
        |> Code.string_to_quoted(file: "/tmp/foo")
        |> Macro.safe_term
      end

  Under the hood pipe binding works by calling the `pipebind` function in a
  monad module. If you use `use Monad.Pipeline` one is automatically created
  (you can still override it though).

  The `pipebind` function receives the AST form of a value argument and a
  function. It has to return some AST that essentially does what bind does but
  with a function that's missing the first argument. See the example below.

  """

  @doc """
  Helper for defining monads.

  Just `use Monad` in your monad module and define `return/1` and
  `bind/2` to get the `m` macro.
  """
  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Monad

      @doc """
      Monad do-notation.

      See the `Monad` module documentation and the
      """ <> "`#{inspect __MODULE__}`" <> """
      module documentation
      """
      defmacro m(do: block) do
        res = case block do
          nil ->
            raise ArgumentError, message: "missing or empty do block"
          {:__block__, meta, exprs} ->
            {:__block__, meta, Monad.Internal.expand(__MODULE__, exprs)}
          expr ->
            {:__block__, [], Monad.Internal.expand(__MODULE__, [expr])}
        end
        Monad.Internal.transform_return(__MODULE__, res)
      end
    end
  end

  @type monad :: any

  @doc """
  Inject a value into a monad.
  """
  @callback return(any) :: monad

  @doc """
  Bind a value in the monad to the passed function which returns a new monad.
  """
  @callback bind(monad, (any -> monad)) :: monad
end

defmodule Monad.Internal do
  # Internal helpers for the monad stuff.
  @moduledoc false

  @doc false
  def expand(_, [expr]) do
    [expr]
  end
  def expand(mod, [{:let, _, let_exprs} | exprs]) do
    if length(let_exprs) == 1 and is_list(hd(let_exprs)) do
      case Keyword.fetch(hd(let_exprs), :do) do
        :error ->
          let_exprs ++ expand(mod, exprs)
        {:ok, e} ->
          [e | expand(mod, exprs)]
      end
    else
      let_exprs ++ expand(mod, exprs)
    end
  end
  def expand(mod, [{:<-, _, [lhs, rhs]} | exprs]) do
    # x <- m ==> bind(b, fn x -> ... end)
    expand_bind(mod, lhs, rhs, exprs)
  end
  def expand(mod, [expr | exprs]) do
    # m ==> bind(b, fn _ -> ... end)
    expand_bind(mod, quote(do: _), expr, exprs)
  end

  defp expand_bind(mod, lhs, rhs, exprs) do
    [quote do
      unquote(mod).bind(unquote(rhs),
                        fn unquote(lhs) ->
                             unquote_splicing(expand(mod, exprs))
                        end)
    end]
  end

  @doc false
  # Find unqualified mentions of `return` in the AST and translate them to
  # `mod.return`.
  def transform_return(mod, {:return, _, [arg]} ) do
    quote do unquote(mod).return(unquote(arg)) end
  end
  def transform_return(mod, {call, meta, args}) do
    {call, meta, transform_return(mod, args)}
  end
  def transform_return(mod, l) when is_list(l) do
    Enum.map(l, &transform_return(mod, &1))
  end
  def transform_return(mod, {l, r}) do
    { transform_return(mod, l), transform_return(mod, r) }
  end
  def transform_return(_mod, x) do
    x
  end
end

defmodule Monad.Pipeline do
  @moduledoc """
  Helper for defining monads that support pipelines.

  Just use `use Monad.Pipeline` in your monad module and define `return/1` and
  `bind/2` and get `pipebind/2` for free.
  """
  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Monad.Pipeline
      @doc """
      Pipeline form of the monad.

      See `Monad` module documentation.
      """
      defmacro p(pipeline) when is_list(pipeline) do
        case pipeline[:do] do
          nil                         ->
            raise ArgumentError, message:
              "Monad.p called with a list but it's not a keyword list with " <>
              "a 'do' key (i.e. not a passed do block)"
          { __block__, _, [expr] }    -> p_expand(expr)
          expr                        -> p_expand(expr)
        end
      end
      defmacro p(pipeline), do: p_expand(pipeline)

      defp p_expand(pipeline) do
        # Enum.reduce is a left fold
        Macro.unpipe(pipeline)
        |> Enum.reduce(&(__MODULE__.pipebind(&2, &1)))
      end

      def pipebind(x, fc) do
        quote location: :keep do
          # I think there should be no conflict with the variable used in `fn`,
          # but just to be sure let's use an odd variable name.
          bind(unquote(x), fn _monad_pipebind_arg ->
            unquote(Macro.pipe(quote do _monad_pipebind_arg end, fc))
          end)
        end
      end

      defoverridable [pipebind: 2]
    end
  end

  @doc """
  Like bind/2 but works on ASTs and the second argument should be a function
  call where the first argument is missing.
  """
  @callback pipebind(Macro.t, Macro.t) :: Macro.t
end
