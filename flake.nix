{
  description = "Just Cook development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
        devShells.${system}.default = pkgs.mkShell {
            packages = [
                pkgs.ruby_4_0
                pkgs.nodejs_26
                pkgs.pnpm
            ];
        };
    };
}
