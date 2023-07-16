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
        name = "personal-website";
        image  = {
          inherit name;
	  registry = "ghcr.io";
	  owner = "will-lol";
	};

        overlays = [];
        pkgs = import nixpkgs { inherit system overlays; };
        goBuild = pkgs.buildGoModule {
	  inherit name;
          src = gitignore.lib.gitignoreSource ./.;
	  vendorSha256 = null; 
        };
        dockerImage = pkgs.dockerTools.buildImage {
          name = "${image.registry}/${image.owner}/${image.name}";
	  config = { 
	    Cmd = [ "${goBuild}/bin/${name}" ]; 
	    Labels = {
	      "org.opencontainers.image.source" = "https://github.com/${image.owner}/${image.name}";
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
