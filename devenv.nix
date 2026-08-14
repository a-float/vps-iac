{ pkgs, lib, config, inputs, ... }:

{
  env.ANSIBLE_VAULT_PASSWORD_FILE  = ".ansible_vault_pass";

  packages = [ pkgs.git ];

  languages.ansible.enable = true;

  scripts.ansible-play.exec = ''
    ansible-playbook -i inventory/hosts.yml site.yml
  '';
}
