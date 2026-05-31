  /*
pulled from the space between this line
  Helpers = import ./newHelpers.nix {inherit l;};
and 
The grow function def.

It's A bunch of `docs`, written somewhat confusingly/non-literally 
Will probably change/update if I add any "massive new functionality"
Otherwise just edit semantics - and add to it as I go along (as I already have).



      A function that 'grows' Cell Blocks from Cells found in 'cellsFrom'.

      This figurative glossary is so non-descriptive, yet fitting, that
      it will be easy to reason about this nomenclature even in a casual
      conversation when not having convenient access to the actual code.

      Essentially, it is a special type of importer, that detects nix &
      some companion files placed in a specific folder structure inside
      your repository.

      The root of that special folder hierarchy is declared via 'cellsFrom'.
      This is a good opportunity to isolate your actual build-relevant source
      code from other repo boilerplate or documentation as a first line measure
      to improve build caching.

      Cell Blocks are the actual typed flake outputs, for convenience, Cell Blocks
      are grouped into Block Types which usually augment a Cell Block with action
      definitions that the std TUI will be able to understand and execute.

  deSystemize function:

    The 'deSystemize' automatically folds any particular system scope of inputs one level up.

        As Such, the usual dealings with 'system' are greatly reduced by this function.
        contrary to clasical nix, _all_ outputs are automatically scoped by system, as the first-level output key.
        That's it. Never deal with it again.

    So, when dealing with inputs, no dealing with 'system' either.

      If you need to crosscompile and know your current system, `inputs.nixpkgs.system`
      always has it. And all other inputs still expose `inputs.foo.system` as a
      fall back. But use your escape hatch wisely. If you feel that you need it and
      you aren't doing cross-compilation, search for the upstream bug.
      It's there! Guaranteed!

      Finally, there are a couple of special inputs:

      - `inputs.cells` - all other cells, deSystemized (FP - should be under PerSystem)
      - `inputs.nixpkgs` - an _instatiated_ nixpkgs, configurabe via `nixpkgsConfig`
      - `inputs.self` - the `sourceInfo` (and only that) of the current flake

      Overlays? Go home or file an upstream bug. They are possible, but so heavily
      discouraged that you gotta find out for yourself if you really need to use
      them in a Cell Block. Hint: `.extend`.

      Yes, std is opinionated.
  #NOTE: @from removed-user: So you know some nerd who decided to make it's libs compatible with flake-parts is too

  */
