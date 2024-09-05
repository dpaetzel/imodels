{
  # For test devShell only.
  inputs = {
    nixpkgs.url =
      #   # "github:dpaetzel/nixpkgs/dpaetzel/nixos-config";
      "github:dpaetzel/nixpkgs/update-clipmenu";
    overlays.url = "github:dpaetzel/overlays/master";
  };

  outputs =
    {
      self,
      nixpkgs, # for devShell only
      overlays, # for devShell only
    }:
    let
      imodelsOverlay = final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (
            python-final: python-prev:
            let
              mymlxtend = python-prev.mlxtend.overridePythonAttrs (old: {
                meta.broken = false;
                # No time to fix test paths under NixOS rn.
                # disabledTestPaths = [ ];
                doCheck = false;
              });
            in
            {

              imodels = python-prev.buildPythonPackage rec {
                # enablePython = true;
                # pythonPackages = python;
                pyproject = true;
                build-system = with python-prev; [
                  setuptools
                  wheel
                ];

                pname = "imodels";
                version = "dev";
                src = self;

                dependencies = with python-prev; [
                  # See comments on versions in pyproject.toml.
                  matplotlib
                  mymlxtend
                  numpy
                  pandas
                  requests
                  scipy
                  scikit-learn
                  tqdm
                ];
              };
            }
          )
        ];
      };
    in
    {
      overlays.imodels = imodelsOverlay;

      # You can test whether it's importable by doing `nix develop`.
      devShell.x86_64-linux =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [
              overlays.overlays.mydefaults
              imodelsOverlay
            ];
          };
        in

        pkgs.mkShell {
          buildInputs = [ (pkgs.mypython.withPackages (ps: [ ps.imodels ])) ];

          shellHook = ''
            cwd=$(pwd)
            echo Entering temp dir …
            cd $(mktemp --directory)
            echo Checking whether import works …
            python -c 'import imodels'\
                 && echo '✅ Importing works!' \
                 || true
            echo Switching back to original directory …
            cd "$cwd"
          '';
        };

    };
}
