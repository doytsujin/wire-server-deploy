self: super: {
  ansible_with_libs = super.python3Packages.toPythonApplication (super.python3Packages.ansible.overridePythonAttrs (old: rec {
    propagatedBuildInputs = old.propagatedBuildInputs or [ ] ++ [
      super.python3Packages.boto
      super.python3Packages.boto3
      super.python3Packages.six
    ];
  }));

  pythonForAnsible = (self.python3.withPackages (_: self.ansible.requiredPythonModules));

  mirror-bionic = self.callPackage ./pkgs/mirror-bionic {};

  kubectl_1_14_10 = self.callPackage ./pkgs/kubectl_1_14_10.nix { };
  kubeadm = self.callPackage ./pkgs/kubeadm { };

  k8s-binaries = self.callPackage ./pkgs/k8s-binaries { };

  # These are some simple shell scripts invoked to assemble the offline package
  scripts = {
    create-container-dump = super.runCommandNoCC "create-container-dump"
      {
        nativeBuildInputs = [ super.makeWrapper ];
      } ''
      install -Dm755 ${./scripts/create-container-dump.sh} $out/bin/create-container-dump
      wrapProgram $out/bin/create-container-dump --prefix PATH : '${super.lib.makeBinPath [ self.skopeo ]}'
    '';

    list-helm-containers = super.runCommandNoCC "list-helm-containers"
      {
        nativeBuildInputs = [ super.makeWrapper ];
      } ''
      install -Dm755 ${./scripts/list-helm-containers.sh} $out/bin/list-helm-containers
      wrapProgram $out/bin/list-helm-containers --prefix PATH : '${super.lib.makeBinPath [ self.kubernetes-helm ]}'
    '';

    mirror-bionic =
      super.runCommandNoCC "mirror-bionic"
        {
          nativeBuildInputs = [ super.makeWrapper ];
        } ''
        install -Dm755 ${./scripts/mirror-bionic.sh} $out/bin/mirror-bionic
        # we need to *--set* PATH here, otherwise aptly will pick the wrong gpg
        wrapProgram $out/bin/mirror-bionic --set PATH '${super.lib.makeBinPath (with self; [ aptly bash coreutils curl gnupg1orig gnused gnutar ])}'
      '';
  };
}