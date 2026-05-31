/*
This file implements the unique import signature of each block.
*/
#FIXME:
# Options
#1. Remove entirely, "file seems to be taking on 'input modifications' for nosys"; may need to pull out/remap some attrs
#2. Remove deSystemize, and check functionality of returns
#3. Find out What 'exactly' deSystemize returns, and replace with flake-parts equivalent
{
  l,
  deSystemize,
}: cfg: let
  self = cfg.inputs.self.sourceInfo // {rev = cfg.inputs.self.sourceInfo.rev or "not-a-commit";};
  instantiateNixpkgsWith = system: nixpkgs:
    (
      if cfg.nixpkgsConfig != {}
      then
        (import nixpkgs {
          inherit system;
          config = cfg.nixpkgsConfig;
        })
      # numtide/nixpkgs-unfree blocks re-import
      else nixpkgs.legacyPackages.${system}
    )
    // {inherit (nixpkgs) outPath sourceInfo;};
in
  system: cells: additionalInputs: let
    currentNixpkgs =
      if additionalInputs ? nixpkgs
      then additionalInputs.nixpkgs
      else if cfg.inputs ? nixpkgs
      then cfg.inputs.nixpkgs
      else null;
  in (
    (cfg.inputs // additionalInputs)
    #FIXME: Dropped the below deSystemize call. For now just that, later; possibly updating the // merge methods.
    # (deSystemize system (cfg.inputs // additionalInputs))
    // {
      inherit self;

      cells = cells; # recursion on cells
      #FIXME: Dropped the below deSystemize call; and let cells be cells
      # cells = deSystemize system cells; # recursion on cells
    }
    // l.optionalAttrs (currentNixpkgs != null) {
      nixpkgs =
        (instantiateNixpkgsWith system currentNixpkgs)
        //
        # mimick deSystemize behaviour
        (builtins.mapAttrs
          (system: _: instantiateNixpkgsWith system currentNixpkgs)
          currentNixpkgs.legacyPackages);
    }
  )
