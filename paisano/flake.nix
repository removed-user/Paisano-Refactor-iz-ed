# SPDX-FileCopyrightText: 2022 The Standard Authors
#
# SPDX-License-Identifier: Unlicense
{
  #FIXME:
  #Dropped Below Arg, cutting off nosys inputs
  #inputs.nosys.url = "github:divnix/nosys";
  inputs.call-flake.url = "github:divnix/call-flake";
  inputs.yants = {
    url = "github:divnix/yants";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = {
    nixpkgs,
    call-flake,
    #FIXME:
    #Dropped Below Output Arg, cutting off nosys function outputs
    #nosys,
    yants,
    self,
  }: let
    l = nixpkgs.lib // builtins;
    # deSystemize = nosys.lib.deSys;
    paths = import ./paths.nix;
    types = import ./types {inherit l yants paths;};
  in {
    inherit (import ./soil {inherit l;}) pick harvest winnow;
    inherit (import ./grow {inherit l paths types call-flake;}) grow growOn;
    #FIXME:
    # function Arg Dropped from above, disables deSystemize, may break other functions using it depending on the way it carries output to next function
    # deSystemize
    isDirty = rev: rev == "not-a-commit";
  };
}
