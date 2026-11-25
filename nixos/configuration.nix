{ pkgs, zen-browser, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="xhci_hcd", ATTR{power/wakeup}="disabled"
  '';

  security.polkit.enable = true;
  services.udisks2.enable = true;

  fileSystems."/mnt/shared" = {
    device = "/dev/disk/by-uuid/6A7C-DFD0";
    fsType = "exfat";
    options = [
      "noatime"
      "nofail"
      "uid=1000"
      "gid=100"
      "dmask=0022"
      "fmask=0133"
      "x-gvfs-show"   # show in the Nautilus sidebar
    ];
  };

  networking.hostName = "excalibur";
  networking.networkmanager.enable = true;

  # Bluetooth: runs the bluez daemon (bluetoothctl); bluetui is the TUI for it
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.logind.settings.Login.HandleLidSwitch = "ignore";

  time.timeZone = "Europe/Madrid";
  time.hardwareClockInLocalTime = true;
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };

  console = {
    font = "ter-v24n";
    packages = with pkgs; [ terminus_font ];
    keyMap = "colemak";
  };

  users.users.suhaylmv = {
    isNormalUser = true;
    description = "Suhayl";
    extraGroups = [ "networkmanager" "wheel" "video" "storage" "input" "docker" ];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.iosevka
    jetbrains-mono
  ];

  environment.sessionVariables = {
    XCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    XCURSOR_SIZE  = "24";
    NIXOS_OZONE_WL = "1"; # Electron/Chromium apps use native Wayland
  };
  environment.localBinInPath = true;

  programs.dconf.enable = true;

  # also creates hyprlock's PAM service
  programs.hyprlock.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib   # libstdc++
    zlib
    openssl
  ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  environment.systemPackages = with pkgs; [
    # system utils
    vim
    wget
    glib
    killall
    zip
    unzip
    htop
    btop
    tree
    file
    atuin
    nitch
    fzf
    yazi
    ffmpeg-full
    file-roller
    unrar
    ncdu
    exfatprogs
    chafa                    # image previews in the terminal (wallpaper picker)

    # daemons & dependencies
    wl-clipboard
    clipse                   # clipboard history
    networkmanagerapplet
    pavucontrol
    bluetui                  # Bluetooth TUI
    brightnessctl
    playerctl
    grim
    slurp
    quickshell
    hyprsunset               # night light (warm screen); schedule lives in quickshell/NightLight.qml
    libnotify                # notify-send, for testing notifications

    # hypr
    hypridle
    grimblast                # screenshots
    satty                    # screenshot annotation
    hyprpicker
    hyprpolkitagent

    # basic apps
    libreoffice
    hunspell            # spell checking for LibreOffice
    hunspellDicts.en_US
    hunspellDicts.es_ES
    nautilus
    ghostty
    kitty
    gnome-calculator
    mpv
    xdg-utils
    papirus-icon-theme
    kdePackages.ocean-sound-theme   # Quickshell's sounds (Sounds.qml)
    nwg-look
    zathura
    shotwell
    foliate
    gnome-disk-utility
    snapshot
    _7zz
    peazip
    eyedropper
    vesktop

    # theming
    catppuccin-cursors.mochaDark

    # apps
    gapless
    mailspring
    obsidian
    tana
    blanket
    zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
    yt-dlp
    qbittorrent
    anki
    telegram-desktop
    obs-studio
    # SCID is Tk, an X11 app: Hyprland gives X apps real pixels
    # (xwayland.force_zero_scaling, so they're sharp), and Tk then has to
    # scale itself. XWayland always reports 96 dpi (Tk scaling 1.333 px per
    # point); x1.33 for the monitor = 1.773. This replaces the stock `scid`
    # launcher, which runs SCID's start.tcl the same way, minus the scaling.
    (writeShellScriptBin "scid" ''
      export TCLLIBPATH="${tk}/lib/tk8.6''${TCLLIBPATH:+ $TCLLIBPATH}"
      exec ${scid}/bin/tkscid ${writeText "scid-scaled.tcl" ''
        package require Tk 8.6
        tk scaling 1.773
        source ${scid}/share/tcl/start.tcl
      ''} "$@"
    '')

    # dev tools
    zed-editor
    jetbrains.datagrip
    postman
    insomnia
    httpie
    git
    stow
    gh
    lazygit
    jq
    yq-go
    curl
    gnumake
    ripgrep
    fd
    tree-sitter
    shfmt
    claude-code
    typst
    tinymist
    typstyle
    libxkbcommon

    # go & backend
    go
    gopls
    golangci-lint
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc
    buf
    grpcurl
    openapi-generator-cli
    postgresql
    redis

    # frontend & typescript
    nodejs
    typescript-language-server
    pnpm
    bun
    typescript
    tailwindcss_4

    # other languages
    python3
    gcc
    cargo
    lua-language-server
    stylua
    nil
    nixd
    nixfmt
  ];

  # ZSH
  programs.zsh.enable = true;
  users.users.suhaylmv.shell = pkgs.zsh;
  # .zshrc runs compinit itself; a second one rebuilds the cache every start
  programs.zsh.enableGlobalCompInit = false;
  programs.zsh.promptInit = "";

  virtualisation.docker.enable = true;

  # Flatpak
  services.flatpak.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  # Nautilus needs this for thumbnails and trash
  services.gvfs.enable = true;

  programs.hyprland.enable = true;
  systemd.user.targets.hyprland-session = {
    description = "Hyprland compositor session";
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "start-hyprland";
        user = "suhaylmv";
      };
    };
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.power-profiles-daemon.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # release of the first install, don't bump it
  system.stateVersion = "25.11";
}
