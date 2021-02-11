let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {
    config = { };
    overlays = [
      (import ./nix/overlay.nix)
    ];
  };
  profileEnv = pkgs.writeTextFile {
    name = "profile-env";
    destination = "/.profile";
    # This gets sourced by direnv. Set NIX_PATH, so `nix-shell` uses the same nixpkgs as here.
    text = ''
      export NIX_PATH=nixpkgs=${toString pkgs.path}
    '';
  };

in
rec {
  inherit pkgs profileEnv;

  env = pkgs.buildEnv {
    name = "wire-server-deploy";
    paths = [
      profileEnv
      pkgs.ansible_with_libs
      pkgs.awscli
      pkgs.gnumake
      pkgs.gnupg
      pkgs.helmfile
      pkgs.kubectl
      pkgs.kubernetes-helm
      pkgs.moreutils
      pkgs.pythonForAnsible
      pkgs.skopeo
      pkgs.sops
      pkgs.terraform_0_13
      pkgs.yq

      pkgs.create-container-dump
      pkgs.list-helm-containers
      pkgs.mirror-apt
      pkgs.generate-gpg1-key
      pkgs.kubeadm

    ];
  };

  # The container we use for offline deploys. Where people probably do not have
  # nix + direnv :)
  container = pkgs.dockerTools.buildImage {
    name = "quay.io/wire/wire-server-deploy";
    fromImage = pkgs.dockerTools.pullImage (import ./nix/docker-alpine.nix);
    # we don't want git or ssh or anything in here, the ansible folder is
    # mounted into here.
    contents = [
      pkgs.cacert
      pkgs.coreutils
      pkgs.bashInteractive
      pkgs.openssh # ansible needs this too, even with paramiko

      # The enivronment
      env
      # provide /usr/bin/env and /tmp in the container too :-)
      #(pkgs.runCommandNoCC "foo" {} "
      #  mkdir -p $out/usr/bin $out/tmp
      #  ln -sfn ${pkgs.coreutils}/bin/env $out/usr/bin/env
      #")
    ];
    config = {
      Volumes = {
        "/wire-server-deploy" = { };
      };
      WorkingDir = "/wire-server-deploy";
      Env = [
        "KUBECONFIG=/wire-server-deploy/ansible/kubeconfig"
        "ANSIBLE_CONFIG=/wire-server-deploy/ansible/ansible.cfg"
      ];
    };
  };
}
