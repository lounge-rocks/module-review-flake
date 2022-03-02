{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # inputs.pkgsReview.url = "github:Artturin/nixpkgs/pipewirejackldpath";
  # inputs.pkgsReview.url = "github:stuebinm/nixpkgs/master";
  inputs.pkgsReview.url =
    "github:stuebinm/nixpkgs?ref=feature/mattermost-secrets";

  # inputs.pkgsReview.url = "/home/pinpox/code/github.com/NixOS/nixpkgs";
  #inputs.pkgsReview.url = "/home/artturin/nixgits/my-nixpkgs";

  outputs = inputs@{ self, nixpkgs, pkgsReview }: {

    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ({ pkgs, ... }: {

          # Disable old module from upstream nixpkgs, if the module is not new
          disabledModules = [ "services/web-apps/mattermost.nix" ];
          imports = [

            # Include the module from the fork/fork you want to test
            "${inputs.pkgsReview}/nixos/modules/services/web-apps/mattermost.nix"

            # For virtualisation settings
            "${inputs.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
          ];

          system.activationScripts.create-mm-secrets = ''
            cat > /var/lib/mattermost/secrets.json << END

            {
              "PasswordSettings": {
                "MinimumLength": 7
              }
            }

            END
          '';

          # Test-Specific configuration for the module
          services.mattermost = {
            enable = true;
            mutableConfig = false;
            siteUrl = "http://localhost";

            secretFile = "/var/lib/mattermost/secrets.json";

            extraConfig = {
              PasswordSettings = {
                MinimumLength = 5;
                Lowercase = false;
                Number = false;
                Uppercase = false;
                Symbol = false;
              };
            };

          };

          console = {
            font = "Lat2-Terminus16";
            keyMap = "colemak";
          };

          services.qemuGuest.enable = true;
          networking.firewall.enable = false;

          virtualisation.forwardPorts = [

            # forward local port 2222 -> 22, to ssh into the VM
            {
              from = "host";
              host.port = 2222;
              guest.port = 22;
            }
            {
              from = "host";
              host.port = 8065;
              guest.port = 8065;
            }

            # forward local port 80 -> 10.0.2.10:80 in the VLAN
            {
              from = "guest";
              guest.address = "10.0.2.10";
              guest.port = 80;
              host.address = "127.0.0.1";
              host.port = 80;
            }
          ];

          # Documentation for these is in nixos/modules/virtualisation/qemu-vm.nix
          virtualisation = {
            memorySize = 1024 * 3;
            diskSize = 1024 * 3;
            cores = 4;
            msize = 104857600;
          };

          users.mutableUsers = false;
          users.users.root = { password = "root"; };
          users.users.user = {
            password = "user";
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
        })
      ];
    };
    # So that we can just run 'nix run' instead of
    # 'nix build ".#nixosConfigurations.vm.config.system.build.vm" && ./result/bin/run-nixos-vm'
    defaultPackage.x86_64-linux =
      self.nixosConfigurations.vm.config.system.build.vm;

    defaultApp.x86_64-linux = {
      type = "app";
      program = "${self.defaultPackage.x86_64-linux}/bin/run-nixos-vm";
    };
  };
}
