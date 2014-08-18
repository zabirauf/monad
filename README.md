# Monad

[![Build Status](https://travis-ci.org/rmies/monad.png?branch=develop)](https://travis-ci.org/rmies/monad)
[![hex.pm version](https://img.shields.io/hexpm/v/monad.svg)](https://hex.pm/packages/monad)
[![hex.pm downloads](https://img.shields.io/hexpm/dt/monad.svg)](https://hex.pm/packages/monad)

This library provides do-syntax and monads for
[Elixir](http://elixir-lang.org/). It is heavily inspired by
[Haskell](http://haskell.org/).

## Contributing Guidelines

To contribute:

1. Fork the `monad` repository on [GitHub](https://github.com/rmies/monad).

2. Clone your fork or add the remote if you already have a clone of
   the repository.

        git clone git@github.com:your_username/monad.git
        # or
        git remote add mine git@github.com:your_username/monad.git

3. Create a feature branch for your change.

        git checkout -b feature/name-of-your-branch

4. Make your change and commit. Use a clear and descriptive commit
   message, see [this note](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

5. Push to your fork of the repository and then send a pull-request
   through GitHub.

        git push mine feature/name-of-your-branch

6. We will review your patch and merge it into the main repository or
   send you feedback.

### Coding Style

* Golden rule: just follow the style of the rest of the code.
* Avoid unneccesary whitespace in expressions with braces and brackets
  (tuples / lists). Don't write `{ :ok, a }`, write `{:ok,
  a}`. Whitespace is allowed in nested expressions if it significantly
  improves readability, but if things get that complicated prefer to
  rewrite the expression to be simpler (one spot where that's not
  always possible is pattern matching).
* Add documentation to all modules (`@moduledoc`) and public
  functions/macro's (`@doc`). Exception: implementations of callbacks
  don't need (but may have) documentation, if you leave off the
  documentation a default will be provided by the documentation
  generator.
* In documentation use the first line as a short summary, this will
  show up in the function/module/whatever overview in the
  documentation.
* Line length: limit the numbers of characters per line to 80.
* Avoid trailing whitespace.

### Branching Model

Use [Vincent Driessen's branching model](http://nvie.com/posts/a-successful-git-branching-model/)
(as supported by [git-flow](https://github.com/nvie/gitflow), of
course you're free to do it by hand).
