{ pkgs, lib, config, inputs, ... }:

{
  env.DOCKERHUB_USERNAME = "afloaty";
  env.DOCKERHUB_REPOSITORY = "nanobot";
  env.ANSIBLE_VAULT_PASSWORD_FILE = ".ansible_vault_pass";

  packages = [ pkgs.git ];

  languages.ansible.enable = true;

  scripts.ansible-play.exec = ''
    ansible-playbook -i inventory/hosts.yml site.yml
  '';

  pre-commit.hooks.ansible-vault-encrypted = {
    enable = true;
    name = "check Ansible vault encryption";
    entry = "grep -q '^\\$ANSIBLE_VAULT;'";
    files = "^group_vars/all/vault$";
    language = "system";
  };
}
