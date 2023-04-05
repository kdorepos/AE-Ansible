# Ansible
[<img src=".gitlab/ansible_logo.png" align="right" width="90">](https://github.com/kdorepos/AE-Ansible)

> This is all a giant work-in-progress.

Ansible is an open source toolkit, written in Python, which is used for configuration management, application deployment, continuous delivery, IT infrastructure automation and general automation

## Folder Structure
- **.gitlab** - just houses the Ansible logo
- **content** - houses all of the network dependent content, no playbooks or roles
    - **config** - just houses `ansible.cfg`
    - **group_files** - houses different files that are potentially referenced by multiple playbooks/roles
    - **group_vars** - houses different variable files that are potentially referenced by multiple playbooks/roles
    - **inventories** - houses inventory files for ansible to use
    - **secrets** - holds the main vault file for all of Ansible
- **core** - houses playbooks, roles, and emergency playbooks
    - **emergency** - only used to hold the site shutdown playbook
    - **playbooks** - many, many playbooks
    - **role_runners** - playbooks speficially written to run roles
    - **roles** - many, many roles - ask Leroy/Kevin for clarification on these

## About ansible.cfg
`ansible.cfg` is now located under `/opt/ansible/config`. This gives admins an easier way to manage `ansible.cfg`. This file is symbolicaly-linked to `/etc/ansible/ansible.cfg`, which is where Ansible points to for its running config. We are now able to make changes and track changes in Gitlab for `ansible.cfg`.
