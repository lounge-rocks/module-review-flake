{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # inputs.pkgsReview.url = "github:Artturin/nixpkgs/pipewirejackldpath";
  inputs.pkgsReview.url = "github:stuebinm/nixpkgs/master";
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

          # Test-Specific configuration for the module
          services.mattermost = {
            enable = true;
            mutableConfig = false;
          };

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
