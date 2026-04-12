{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      home-manager,
    }:
    let
      user = "yohanesray";
      configuration =
        { pkgs, ... }:
        {

          system.primaryUser = user;
          users.users.${user}.home = "/Users/${user}";
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.vim
            pkgs.nixfmt
          ];

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          homebrew = {
            enable = true;

            # GUI
            casks = [
              "zed"
              "rectangle"
              "whatsapp"
            ];

            brews = [

            ];

            # Homebrew package repositories
            taps = [ "homebrew/cask" ];

            onActivation = {
              cleanup = "zap";
            };

          };

        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Yohaness-MacBook-Pro
      darwinConfigurations."Yohaness-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = user;

              # Optional: Declarative tap management
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };

              # Optional: Enable fully-declarative tap management
              #
              # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
              mutableTaps = false;
            };
          }
          # Optional: Align homebrew taps config with nix-homebrew
          (
            { config, ... }:
            {
              homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
            }
          )

          #--------------------------------------------------------------------
          # Home Manager - Your Personal User Configuration
          # This manages your dotfiles, shell, and user-level packages
          #--------------------------------------------------------------------
          home-manager.darwinModules.home-manager
          {
            # Use the same nixpkgs as your system config
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # Your personal user settings
            home-manager.users.${user} =
              { pkgs, ... }:
              {
                #--------------------------------------------------------------
                # Home Manager Metadata
                #--------------------------------------------------------------
                home = {
                  enableNixpkgsReleaseCheck = false;
                  stateVersion = "25.05";
                };

                #--------------------------------------------------------------
                # SSH Config - Manage your SSH keys and host settings
                # This creates your ~/.ssh/config file
                #--------------------------------------------------------------
                # programs.ssh = {
                #   enable = true;
                #   enableDefaultConfig = false;
                #   matchBlocks = {
                #     # GitHub SSH configuration
                #     "github.com" = {
                #       identityFile = "~/.ssh/id_ed25519";
                #       identitiesOnly = true;
                #       extraOptions = {
                #         AddKeysToAgent = "yes"; # Auto-load key into ssh-agent
                #         UseKeychain = "yes"; # Store passphrase in macOS Keychain
                #       };
                #     };
                #   };
                # };

                #--------------------------------------------------------------
                # Git Config - Your version control settings
                # This creates your ~/.gitconfig file
                #--------------------------------------------------------------
                programs.git = {
                  enable = true;
                  settings = {
                    user = {
                      name = "yohanesray21";
                      email = "yohanesrfsilitonga21@gmail.com";
                    };
                    # Use "main" instead of "master" for new repos
                    init.defaultBranch = "main";
                  };
                };

                #--------------------------------------------------------------
                # Zsh Config - Your shell configuration
                # This manages your ~/.zshrc
                #--------------------------------------------------------------
                programs.zsh = {
                  enable = true;
                  enableCompletion = true; # Press TAB to autocomplete
                  autosuggestion.enable = true; # Fish-style suggestions
                  syntaxHighlighting.enable = true; # Color your commands
                };

              };
          }

        ];
      };
    };
}
