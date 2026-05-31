{
  l,
  #FIXME:
  #Removing an expected arg likely has side-effects
  # deSystemize,
  call-flake,
  paths,
  types,
}: let
  inherit (types) Block Target;
  ImportSignatureFor = import ./newImportSignatureFor.nix {inherit l;};
  #FIXME:
  #Arg Was part of the inherit above (in newImportSignatureFor)
  #deSystemize
  ExtractFor = import ./newExtractFor.nix {inherit l types paths;};
  ProcessCfg = import ./newProcessCfg.nix {inherit l types;};
  Helpers = import ./newHelpers.nix {inherit l;};
  grow = {
    inputs,
    cellsFrom,
    cellBlocks,
    ### systems should probably be fed in as an arg with importApply on a module that imports the other modules
    # systems ? [
    #   "x86_64-linux"
    #   "aarch64-linux"
    #   "x86_64-darwin"
    #   "aarch64-darwin"
    # ],
    nixpkgsConfig ? {},
  } @ cfg: let
    # preserve pos of `systems` if not using the default
    cfg' =
      cfg
      // (
        if cfg ? systems
        then {}
        else {inherit systems;}
      );
    inherit (ProcessCfg cfg' inputs.self.sourceInfo) systems' cells' cellBlocks';
    inherit (Helpers) accumulate optionalLoad;

    __ImportSignatureFor = ImportSignatureFor {inherit inputs nixpkgsConfig;};
    ___extract = ExtractFor cellsFrom;

    cells = res.output; # recursion on cells (with system)

    # List of all flake outputs injected by std in the outputs and inputs.cells format
    loadOutputFor = system: let
      __extract = ___extract system;
      # Load a cell, return the flake outputs injected by std
      _ImportSignatureFor = cell: maybeWithFlake: let
        additionalInputs = (
          if l.pathExists maybeWithFlake
          then (call-flake (dirOf maybeWithFlake)).outputs
          else {}
        );
      in {
        inputs = __ImportSignatureFor system cells additionalInputs;
        inherit cell;
      };
      loadCellFor = cellName: let
        _extract = __extract cellName;
        cellP = paths.cellPath cellsFrom cellName;
        loadCellBlock = cellBlock: let
          blockP = paths.cellBlockPath cellP cellBlock;
          isFile = l.pathExists blockP.file;
          isDir = l.pathExists blockP.dir;
          signature = let
            # pass through the current cell and cell block names for introspection
            outputMeta =
              res.output
              // {
                __cr = [cellName cellBlock.name];
              };
          in
            _ImportSignatureFor outputMeta cellP.flake; # recursion on cell
          import' = {
            displayPath,
            importPath,
          }: let
            # since we're not really importing files within the framework
            # the non-memoization of scopedImport doesn't have practical penalty
            block =
              Block "paisano/import: ${displayPath}"
              (l.scopedImport signature importPath);
          in
            if l.typeOf block == "set"
            then block
            else block signature;
          importPaths =
            if isFile
            then {
              displayPath = blockP.file';
              importPath = blockP.file;
            }
            else if isDir
            then {
              displayPath = blockP.dir';
              importPath = blockP.dir;
            }
            else throw "unreachable!";
          Target' = {displayPath, ...}: Target "paisano/import: ${displayPath}";
          imported = Target' importPaths (import' importPaths);
          # extract instatiates actions and extracts metadata for the __std registry
          targetTracer = name: l.traceVerbose "Paisano loading for ${system} ${importPaths.importPath}:${name}";
          extracted = l.optionalAttrs (cellBlock.cli or true) (l.mapAttrs (_extract cellBlock targetTracer signature.inputs) imported);
        in
          optionalLoad (isFile || isDir)
          [
            # top level output
            {${cellBlock.name} = imported;}
            # __std.actions (slow)
            {${cellBlock.name} = l.mapAttrs (_: set: set.actions) extracted;}
            # __std.init (fast)
            (
              {
                cellBlock = cellBlock.name;
                blockType = cellBlock.type;
                targets = l.mapAttrsToList (_: set: set.init) extracted;
              }
              // (l.optionalAttrs (l.pathExists blockP.readmeDir) {readme = blockP.readmeDir;})
              // (l.optionalAttrs (l.pathExists blockP.readme) {inherit (blockP) readme;})
            )
            # __std.ci
            {
              ci = l.mapAttrsToList (_: set: set.ci) extracted;
            }
          ];
        res = accumulate (l.map loadCellBlock cellBlocks');
      in [
        # top level output
        {${cellName} = res.output;}
        # __std.actions (slow)
        {${cellName} = res.actions;}
        # __std.init (fast)
        (
          {
            cell = cellName;
            cellBlocks = res.init; # []
          }
          // (l.optionalAttrs (l.pathExists cellP.readme) {inherit (cellP) readme;})
        )
        # __std.ci
        {
          inherit (res) ci;
        }
      ]; # };
      res = accumulate (l.map loadCellFor cells');
    in [
      # top level output
      {${system} = res.output;}
      # __std.actions (slow)
      {${system} = res.actions;}
      # __std.init (fast)
      {
        name = system;
        value = res.init;
      }
      # __std.ci
      {
        ci = [
          {
            name = system;
            value = res.ci;
          }
        ];
      }
    ];
    res = accumulate (l.map loadOutputFor systems');
  in
    assert l.assertMsg ((l.compareVersions l.nixVersion "2.10.3") >= 0) "The truth is: you'll need a newer nix version (minimum: v2.10.3).";
      res.output
      // {
        __std.__schema = "v0";
        __std.ci = l.listToAttrs res.ci;
        __std.init = l.listToAttrs res.init;
        __std.actions = res.actions;
        __std.cellsFrom = l.baseNameOf cellsFrom;
      };

  growOn = import ./grow-on.nix {inherit l grow;};
in {inherit grow growOn;}
