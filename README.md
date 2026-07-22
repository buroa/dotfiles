# dotfiles

My dotfiles managed by [Chezmoi](https://www.chezmoi.io/).

## Machines

| Machine   | Device                | Shell | Packages          |
| --------- | --------------------- | ----- | ----------------- |
| `darwin`  | Laptop (macOS)        | fish  | Homebrew          |
| `truenas` | NAS (TrueNAS Scale)   | fish  | mise              |
| `fedora`  | Dev box (Fedora IoT)  | fish  | rpm-ostree + mise |

`chezmoi init` derives the machine from the OS: the `/etc/os-release` id on Linux
(`fedora`, `truenas`), otherwise the OS name (`darwin` on macOS). It stores this as
`machine` in the local chezmoi config. No prompt. Everything else keys off that
value: `.chezmoiignore` selects which files and scripts apply per machine, and
`.chezmoidata/packages.yaml` supplies the mise tool list. The content files stay
free of machine conditionals.

## Bootstrap

### darwin

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi
chezmoi init --apply buroa/dotfiles
```

The brew bundle hook installs everything in the brewfile on first apply.
Afterwards, make fish the login shell:

```sh
echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells
chsh -s "$(brew --prefix)/bin/fish"
```

### truenas

TrueNAS Scale has no usable package manager (the base OS is reset on updates),
so install chezmoi to `~/.local/bin` with the official script:

```sh
sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply buroa/dotfiles
```

TrueNAS Scale mounts `/tmp` noexec, which breaks chezmoi script hooks and mise
installs. A post-init script must exist to remount it with exec (System →
Advanced Settings → Init/Shutdown Scripts, type Command, when Post Init):

```sh
mount -o remount,exec /tmp
```

mise is bootstrapped automatically and the declared tools are installed during
the first apply. Afterwards, set the login shell to zsh in the TrueNAS UI:
fish comes from mise and can't be registered in `/etc/shells` (the base OS is
sealed), so `.zshrc` execs into fish for interactive sessions instead.
Re-run `chezmoi apply` after major TrueNAS updates.

### fedora

Fedora IoT is an immutable `rpm-ostree` system: `/usr` is read-only, so the
base tools (`fish`, `git`, `mise`, `starship`) are layered into the OS image
and activated with a reboot. The `terra-release` repo provides `mise` and
`starship`.

**0. Passwordless sudo** (optional, dev box only — the provisioning below is
sudo-heavy). Add a `wheel` NOPASSWD drop-in, validated with `visudo` so a typo
can't lock you out of sudo:

```sh
echo '%wheel ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/10-wheel-nopasswd
sudo chmod 0440 /etc/sudoers.d/10-wheel-nopasswd
sudo visudo -cf /etc/sudoers.d/10-wheel-nopasswd   # must print "... parsed OK"
```

Your user must be in the `wheel` group (`id -nG | grep -qw wheel`); add it with
`sudo usermod -aG wheel "$USER"` and re-login if not.

**1. Host provisioning** (needs `sudo`; ends in a reboot that activates the
layered packages, permissive SELinux, and the disabled firewall):

```sh
# Terra repo -> mise + starship
sudo curl -fsSL https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo \
  | sudo tee /etc/yum.repos.d/terra.repo
sudo rpm-ostree install --idempotent terra-release
# libatomic: runtime dep for the mise-managed node build (not in the base image)
# systemd-networkd: not in Fedora IoT's base image; layered for step 2 below
sudo rpm-ostree install --idempotent --assumeyes \
  fish git mise starship libatomic systemd-networkd

# Permissive SELinux + no host firewall (dev box)
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
sudo systemctl disable --now firewalld.service

sudo systemctl reboot
```

**2. Network — switch to systemd-networkd** (optional; Fedora IoT defaults to
NetworkManager, which is fine to keep). Do this *after* the reboot and ideally
from the console: dropping NetworkManager kills any in-flight SSH session.
`systemd-networkd` does nothing until it has a `.network` file, so write the
config **first**, enable networkd, and disable NetworkManager **last** — the
reverse order leaves the box with no networking.

```sh
# Replicate the current DHCP setup on the wired link (adjust the interface name)
printf '[Match]\nName=ens2\n\n[Network]\nDHCP=yes\n' \
  | sudo tee /etc/systemd/network/20-wired.network

# Bring networkd + DNS up, hand /etc/resolv.conf to systemd-resolved
sudo systemctl enable --now systemd-networkd systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Only now retire NetworkManager
sudo systemctl disable --now NetworkManager
```

**3. Per-user setup** (after the reboot):

```sh
# Pull your SSH public keys from GitHub for remote login
export GITHUB_USER="buroa"
curl https://github.com/$GITHUB_USER.keys > ~/.ssh/authorized_keys

# fish is a real login shell here (it is in /etc/shells), so no zsh layer
chsh -s /usr/bin/fish
```

**4. chezmoi.** It is not layered; install it to `~/.local/bin` with the
official script (as on truenas), then let the first apply take over. mise then
manages chezmoi going forward (it is in the fedora tool list):

```sh
sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply buroa/dotfiles
```

The machine resolves to `fedora` from `/etc/os-release`. The mise-install hook
installs the declared tools into `~/.local`; nothing else is layered onto the OS
image. Re-run `chezmoi apply` after pulling changes.

### Fish plugins

`~/.config/fish/fish_plugins` is managed by chezmoi, and the `update-fisher`
hook bootstraps [fisher](https://github.com/jorgebucaran/fisher) and re-runs
`fisher update` whenever the plugin list changes.

## Notes

- The machine is derived from the OS at `chezmoi init` and stored as `machine` in
  the local chezmoi config (`~/.config/chezmoi/chezmoi.yaml`), not in this repo.
  Because that value lives in the config, run `chezmoi init` once after pulling
  changes that touch machine detection so the config regenerates before `apply`.
  To override on an unusual host, edit `machine` in that file and re-apply.
- `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` are symlinks to
  `~/.config/agents/AGENTS.md`, so Claude Code and Codex share one set of
  global agent instructions.
