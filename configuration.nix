# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./pixos.nix
    ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    # Install grub on SD card
    device = "/dev/disk/by-id/usb-Generic_STORAGE_DEVICE_000000000207-0:0";
    # Makes grub ask for passphrase
    enableCryptodisk = true;
    # splash by vermaden (C)
    # http://vermaden.deviantart.com/art/Linux-bootsplash-111504504
    splashImage = "/etc/nixos/cfg/splash.png";
  };

  # Only way I found to save original ChromeOS and use Pixel's ssd
  # for swap LVM volume on cryptsetup plain mode with offset.
  # And for sake of not entering passphrase 3 times (grub, luksopen
  # and in my custom initrd command) I store keyfile in initrd.
  # But injection of file in builder context without creating
  # extrautils derivation is .. from $src which points to this PWD of
  # this config - wierd, huh?

  boot.initrd.extraUtilsCommands = ''
    cp -v ${src/../priv/keyfile} $out/bin/keyfile
  '';
  boot.initrd.extraUtilsCommandsTest = "[ -e $out/bin/keyfile ]";

  boot.initrd.luks.devices = [
    { device = "/dev/disk/by-partuuid/413f91ce-dfce-4933-bb9c-c4f750be6be0";
      name = "card";
      keyFile = "/bin/keyfile";
      preLVM = true;
    }
  ];
  
  boot.initrd.postDeviceCommands = "cryptsetup open --type plain --offset 41943040 --size 72790016 --key-file /bin/keyfile --key-size 512 --hash sha512 --cipher aes-xts-plain64 /dev/sda1 chrome && lvm vgscan --mknodes && lvm vgchange -ay";

  networking.hostName = "pixos";
  networking.hostId = "b737546f";

  users.extraUsers.dmn = {
     name = "dmn";
     group = "dmn";
     extraGroups = [ "wheel" "plugdev" "disk" "storage" "audio" "video" "networkmanager" "systemd-journal" "fuse" "docker" ];
     isNormalUser = true;
     createHome = true;
     shell = "/run/current-system/sw/bin/zsh";
     uid = 1000;
  };
  users.extraGroups.dmn.gid = 1000;
}
