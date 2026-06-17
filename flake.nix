{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
			pkgs = import nixpkgs {
				inherit system;
				config = {
					allowUnfree = true;
				};
			};
      libs = with pkgs; [
          libX11
          libXext
          libXcursor
          libXrandr
          libXi
          libXinerama
          libGL
          libGLU
          mesa
          zlib
          curl
          alsa-lib
      ];
      env = pkgs.buildEnv {
        name = "jai-libs";
        paths = libs;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          jai
        ] ++ libs;
        shellHook = ''
					export LD_LIBRARY_PATH="${env}/lib:/run/opengl-driver/lib:/run/opengl-driver-32/lib:$LD_LIBRARY_PATH"
        '';
      };
			apps.${system}.default = {
			   type = "app";
				 program = let
				 wrappedApp = pkgs.writeShellScriptBin "compile" ''
					export LD_LIBRARY_PATH="${env}/lib:/run/opengl-driver/lib:/run/opengl-driver-32/lib:$LD_LIBRARY_PATH"
					jai "$@"
				 '';
				 in "${wrappedApp}/bin/compile";
			};
    };
}