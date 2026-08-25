<!--
SPDX-FileCopyrightText: 2018-2025 Slavi Pantaleev
SPDX-FileCopyrightText: 2019-2022 Aaron Raimist
SPDX-FileCopyrightText: 2019-2023 MDAD project contributors
SPDX-FileCopyrightText: 2023 QEDeD
SPDX-FileCopyrightText: 2024 Fabio Bonelli
SPDX-FileCopyrightText: 2024 Nikita Chernyi
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara
SPDX-FileCopyrightText: 2026 spatterlight

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Molecule Testing

This role supports [Molecule](https://docs.ansible.com/projects/molecule/), an Ansible testing framework designed for developing and testing Ansible collections, playbooks, and roles.

## Prerequisites

To utilize Molecule you need to prepare several requirements:

- **x86** computer running one of these operating systems that make use of [systemd](https://systemd.io/):
  - **Archlinux**
  - **CentOS**, **Rocky Linux**, **AlmaLinux**, or possibly other RHEL alternatives (although your mileage may vary)
  - **Debian** (10/Buster or newer)
  - **Ubuntu** (18.04 or newer, although [20.04 may be problematic](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/ansible.md#supported-ansible-versions) if you run the Ansible playbook on it)
- `root` access on the computer which Molecule runs against
- [Ansible](http://ansible.com/) program
- [Python](https://www.python.org/)
  - Most distributions install Python by default, but some don't (e.g. Ubuntu 18.04) and require manual installation (something like `apt-get install python3`)
- [Docker](https://www.docker.com)
  - Access to Docker UNIX socket (`/var/run/docker.sock`) is required by default

## Installation

To set up the environment for using Molecule, run the command below on the terminal:

```bash
python3 -m venv ./molecule/venv
source ./molecule/venv/bin/activate
pip3 install -r ./molecule/requirements.txt
```

## Scenarios

Currently these testing scenarios are available:

All three scenarios install I hate money the way the role does, and then check the same set of things: that the service answers HTTP on the port the role configured (deliberately not the image's own default of 8000, so that a `PORT` that never reached the container shows up as nothing listening), that the configuration the container generated for itself carries the role's values and not the image's defaults, that the version the running process reports is the one `ihatemoney_version` pins, and that a directory listed in `ihatemoney_container_additional_volumes` really is mounted inside the container.

They differ in the database and in what that lets them prove:

### `default`

SQLite, kept in the role's own data directory rather than in the `/database` volume the image would fall back to. Creates a project over the HTTP API and then reads it back out of the SQLite file.

This is also the scenario that turns Traefik labels on, and checks the label file for the port, the hostname and the path prefix. It serves I hate money under a path prefix rather than at the root, so that `APPLICATION_ROOT` and the `stripprefix` middleware are exercised.

### `mariadb`

MariaDB, over a Unix socket. Creates a project over the HTTP API, then asks MariaDB itself for the row, and checks that no SQLite database was created on the side.

### `postgres`

Postgres, over a Unix socket. Creates a project over the HTTP API, then asks Postgres itself for the row, and checks that no SQLite database was created on the side.

Both database scenarios leave Traefik labels off and check that the label file contains nothing Traefik-shaped at all.

## Running

By default it is configured to run the scenarios on Ubuntu 26.04.

```bash
molecule test --scenario-name default
```

You can utilize other distributions by setting one to the `MOLECULE_DISTRO` environment variable:

```bash
# Ubuntu 24.04
MOLECULE_DISTRO=ubuntu2404 molecule test --scenario-name default

# Debian 13
MOLECULE_DISTRO=debian13 molecule test --scenario-name default

# Debian 12
MOLECULE_DISTRO=debian12 molecule test --scenario-name default
```
