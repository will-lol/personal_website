{
  description = "Go example flake for Zero to Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, gitignore, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: 
      let
        overlays = [];
        pkgs = import nixpkgs { inherit system overlays; };
        goBuild = pkgs.buildGoModule {
          name = "personal-website";
          src = gitignore.lib.gitignoreSource ./.;
	  vendorSha256 = null; 
        };
        dockerImage = pkgs.dockerTools.buildImage {
          name = "personal_website";
	  config = { 
	    Cmd = [ "${goBuild}/bin/personal-website" ]; 
	    Labels = {
	      "org.opencontainers.image.source" = "https://github.com/will-lol/personal_website";
	    };
	  };
        };
      in
        {
          packages = {
            docker = dockerImage;
            goPackage = goBuild;
          };
          defaultPackage = dockerImage;
          devShell = pkgs.mkShell {
            packages = with pkgs; [ go docker ];
          };
        }
    );
}
