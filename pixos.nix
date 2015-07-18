{ config, pkgs, ... }:

{
  
  boot.kernelPackages = pkgs.linuxPackages_3_19;
  
  nixpkgs.config = {
    packageOverrides = pkgs: {
      stdenv = pkgs.stdenv // {
        platform = pkgs.stdenv.platform // {
          kernelExtraConfig = "CHROME_PLATFORMS y" ;
        };
      };

      bluez = pkgs.bluez5;
    };
  };


  environment.etc = {
    "i3.conf".text = builtins.readFile ./cfg/i3;
    "i3status.conf".text = builtins.readFile ./cfg/i3status;
    "tmux.conf".text = builtins.readFile ./cfg/tmux;
  };

  systemd.extraConfig = "";

  services.logind.extraConfig = ''
    HandleLidSwitch=ignore
    LidSwitchIgnoreInhibited=no
    HandlePowerKey=hibernate
  '';

  services.udev.packages = [
      pkgs.libmtp
  ];
  services.xserver = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      configFile = "/etc/i3.conf";
    };
    displayManager.slim.enable = true;
    desktopManager.xterm.enable = false;
    startGnuPGAgent = true;
    layout = "us,ru";
    xkbOptions = "ctrl:nocaps,grp:ctrl_shift_toggle";
  };
  services.xserver.displayManager.desktopManagerHandlesLidAndPower = false;

  hardware.cpu.intel.updateMicrocode = true;
  hardware.pulseaudio.enable = true;
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
    btrfsProgs gptfdisk parted libressl dropbear fuse sshfsFuse
    emacs fish zsh joe git rsync wget psmisc gnupg tmux 
    networkmanagerapplet pavucontrol 
    evilvte liberation_ttf
    gimp nodejs unzip i3status mosh
    dmenu dunst alock xlibs.xev 
    python27Packages.glances
    chromium firefox-bin w3m surf
  ];

  environment.shells = [ "/run/current-system/sw/bin/zsh" ];
  environment.variables.EDITOR = pkgs.lib.mkForce "jmacs";
  environment.variables.VISUAL = "emacsclient";
  environment.variables.TERMINAL = pkgs.lib.mkForce "evilvte";
  networking.networkmanager.enable = true;
  nix.useChroot = true;

  nixpkgs.config.evilvte.config = builtins.readFile ./cfg/evilvte;
  services.udisks2.enable = true;
  services.gnome3.at-spi2-core.enable = true;

  programs.ssh.startAgent = false;
  powerManagement.cpuFreqGovernor = "powersave";
  virtualisation.docker.enable = true;
  virtualisation.docker.extraOptions = "-s btrfs -g /docker";

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.enableKVM = true;
}
