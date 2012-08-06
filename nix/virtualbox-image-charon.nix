{ config, pkgs, ... }:

let

  clientKeyPath = "/root/.vbox-client-key";

in

{ require = [ <nixos/modules/virtualisation/virtualbox-image.nix> ];

  services.openssh.enable = true;

  jobs."get-vbox-charon-client-key" =
    { task = true;
      path = [ config.boot.kernelPackages.virtualboxGuestAdditions ];
      script =
        ''
          set -o pipefail
          VBoxControl -nologo guestproperty get /VirtualBox/GuestInfo/Charon/ClientPublicKey | sed 's/Value: //' > ${clientKeyPath}
        '';
    } // (if config.system.build ? systemd then {
      wantedBy = [ "multi-user.target" ];
      before = [ "sshd.service" ];
      requires = [ "dev-vboxguest.device" ];
      after = [ "dev-vboxguest.device" ];
    } else {
      startOn = "starting sshd";
    });

  users.extraUsers.root.openssh.authorizedKeys.keyFiles = [ clientKeyPath ];

  boot.vesa = false;

  boot.loader.grub.timeout = 1;

  # VirtualBox doesn't seem to lease IP addresses persistently, so we
  # may get a different IP address if dhcpcd is restarted.  So don't
  # restart dhcpcd.
  jobs.dhcpcd.restartIfChanged = false;
}
