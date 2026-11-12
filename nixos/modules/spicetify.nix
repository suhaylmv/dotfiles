{ pkgs, spicetify-nix, ... }:

let
  # spicetify-nix exposes themes and extensions as packages
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ spicetify-nix.nixosModules.spicetify ];

  programs.spicetify = {
    enable = true; # installs Spotify system-wide, patched with Spicetify

    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";

    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle  # the "shuffle+" extension
    ];
  };
}
