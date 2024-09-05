{
  inputs.nixpkgs.url = "github:dpaetzel/nixpkgs/dpaetzel/nixos-config";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      python = pkgs.python311;

      mymlxtend = python.pkgs.mlxtend.overridePythonAttrs (old: {
        meta.broken = false;
        # No time to fix test paths under NixOS rn.
        # disabledTestPaths = [ ];
        doCheck = false;
      });

      imodels = python.pkgs.buildPythonPackage rec {
        # enablePython = true;
        # pythonPackages = python;
        pyproject = true;
        build-system = with python.pkgs; [ setuptools wheel ];

        pname = "imodels";
        version = "dev";
        src = self;

        dependencies = with python.pkgs; [
          matplotlib
          mymlxtend # >=0.18.0',  # some lower versions are missing fpgrowth
          numpy # <2.0.0',
          # tested with pandas 2.2.2 (but installing this pandas version will try to use newer np versions)
          pandas # <2.2.2',
          requests # used in c4.5
          scipy
          scikit-learn # >=1.2.0',  # recently updated this
          tqdm # used in BART
        ];
      };
    in {
      packages.${system}.default = imodels;

      # You can test this by doing `nix develop path:path/to/this/repo`. Make
      # sure to change directory beforehand so Python doesn't attempt to import
      # from this repository's `imodels` folder.
      devShell.${system} = pkgs.mkShell {
        buildInputs = [ (python.withPackages (ps: [ imodels ])) ];

        shellHook = ''
          echo "WARNING: Make sure to exit the repository's directory before"\
               "entering the dev shell as otherwise Python will try to import"\
               "local files."
          python -c 'import imodels; '\
               && echo 'It works!'
        '';
      };

    };
}
