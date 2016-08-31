{ config, pkgs, ... }:

{
  imports =
    [
      ./devenv.nix
    ];
  
  boot.kernelPackages = pkgs.linuxPackages_4_6;

  nix.extraOptions = ''
    gc-keep-outputs = true
    gc-keep-derivations = true
  '';
  nixpkgs.config = {
    packageOverrides = pkgs: {
      stdenv = pkgs.stdenv // {
        platform = pkgs.stdenv.platform // {
          kernelExtraConfig =
            ''
              CHROME_PLATFORMS y
              X86_MSR y
            '' ;
        };
      };

      bluez = pkgs.bluez5;

      emacs = pkgs.stdenv.lib.overrideDerivation pkgs.emacs (oldAttrs: {
        configureFlags = "--with-x --with-xft --with-x-toolkit=no --without-gconf --without-sound";
      });

      rofi = pkgs.rofi.override { i3Support = true; };
    };
  };


  environment.etc = {
    "i3.conf".text = builtins.readFile ./cfg/i3;
    "i3status.conf".text = builtins.readFile ./cfg/i3status;
    "tmux.conf".text = builtins.readFile ./cfg/tmux;
  };

  services.udev = {
    extraRules = ''
KERNEL=="sd?", ACTION=="add", ENV{ID_FS_UUID}=="0d630b58-260e-4fbf-bb53-f7813aab2d42", \
RUN+="${pkgs.cryptsetup}/bin/cryptsetup luksOpen --key-file /etc/nixos/priv/keyfile /dev/disk/by-uuid/0d630b58-260e-4fbf-bb53-f7813aab2d42 btrbx01", \
RUN+="/bin/mount -o noatime,ssd,autodefrag,compress=zlib,space_cache,degraded,recovery /dev/mapper/btrbx01 /root/btrbk", \
RUN+="${pkgs.btrbk}/sbin/btrbk -c /etc/nixos/cfg/btrbk-chrome-home.conf run", \
RUN+="${pkgs.coreutils}/bin/sync", \
RUN+="${pkgs.utillinux}/bin/umount /root/btrbk", \
RUN+="${pkgs.cryptsetup}/bin/cryptsetup close btrbx01"
    '';
  };

  #system.autoUpgrade.enable = true;
  #system.autoUpgrade.channel = https://nixos.org/channels/nixos-15.09;
  systemd.extraConfig = "";

  services.logind.extraConfig = ''
    HandleLidSwitch=ignore
    LidSwitchIgnoreInhibited=no
    HandlePowerKey=hibernate
  '';

  services.xserver = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      configFile = "/etc/i3.conf";
    };
    displayManager.slim = {
      enable = true;
      theme = pkgs.fetchurl {
        url    = "https://github.com/jagajaga/nixos-slim-theme/archive/Final.tar.gz";
        sha256 = "4cab5987a7f1ad3cc463780d9f1ee3fbf43603105e6a6e538e4c2147bde3ee6b";
      };
    };
    desktopManager.xterm.enable = false;
    layout = "us,ru";
    xkbOptions = "ctrl:nocaps,grp:ctrl_shift_toggle";
  };

  # hardware.cpu.intel.updateMicrocode = true;

  # Audio
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.bluetooth.enable = true;

  hardware.opengl.s3tcSupport = true;
  services.xserver.useGlamor = true;
  ## services.xserver.multitouch.enable = true;
  services.printing.enable = false;
  nixpkgs.config.allowUnfree = true;
  services.xserver.wacom.enable = true;
  services.xserver.synaptics = {
    enable = true;
    buttonsMap = [ 1 2 3 ];
    palmDetect = true;
    tapButtons = true;
    twoFingerScroll = true;
  };
  fonts.fontconfig.dpi = 96;
  boot.cleanTmpDir = true;
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = "1048576";
  };

  i18n = {
    consoleFont = "lat9w-16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  environment.systemPackages = with pkgs; [
    btrfsProgs gptfdisk parted btrbk libressl # dropbear
    dosfstools #fuse sshfsFuse go-mtpfs
    emacs zsh joe git rsync wget psmisc gnupg tmux silver-searcher
    # networkmanagerapplet
    # pavucontrol
    evilvte liberation_ttf
    # gimp
    #nodejs mosh
    unzip
    dmenu rofi dunst i3lock i3status libnotify
    xlibs.xhost xlibs.xev xlibs.xauth
    #python27Packages.glances
    ponymix
    vorbis-tools
    #chromium
    firefox
    # conkeror
    w3m surf #torbrowser
    # qutebrowser
    # weston
    #tor polipo # cjdns
    # android-udev-rules androidsdk
  ];

  programs.zsh.enable = true;
  environment.shells = [ "/run/current-system/sw/bin/zsh" ];
  environment.variables.EDITOR = pkgs.lib.mkForce "jmacs";
  environment.variables.VISUAL = "emacsclient";
  environment.variables.TERMINAL = pkgs.lib.mkForce "evilvte";
  networking.networkmanager.enable = true;
  nix.useSandbox = true;

  nixpkgs.config.evilvte.config = builtins.readFile ./cfg/evilvte;

  services.udisks2.enable = true;
  # services.gnome3.at-spi2-core.enable = true;

  programs.ssh.startAgent = false;
  powerManagement.cpuFreqGovernor = "powersave";
  #virtualisation.docker.enable = true;
  #virtualisation.docker.extraOptions = "-s btrfs -g /docker";

  # virtualisation.libvirtd.enable = true;
  # virtualisation.libvirtd.enableKVM = true;
}
