# update-all

Automate system and developer tool updates on Linux with a single command. This repo is a set of small Bash updaters orchestrated by update-all.sh. Each updater runs only if its tool is present; many actions use sudo and are non-interactive.

## Quick start

```bash
# Clone and run
chmod +x *.sh
./update-all.sh

# Run a single updater (examples)
./update-apt.sh
./update-conda.sh
./update-rust.sh
```

## What it does

update-all.sh runs a curated sequence of updaters. Highlights:

- OS packages (APT)
  - update-apt.sh: apt update/upgrade/autoremove. Auto-detects and toggles an apt proxy (Acquire::http::Proxy) and flips http/https in third-party lists accordingly.
- Snap packages
  - update-snap.sh: snap refresh; prunes disabled revisions; temporarily unmasks api.snapcraft.io in /etc/hosts if needed, if user had disabled (it to prevent snapd from accessing the internet).
- Python ecosystems
  - update-pipx.sh: pipx upgrade-all.
  - update-pip.sh: upgrades pip; can auto-configure a devpi client if detected in ~/.pip/pip.conf.
  - update-conda.sh: updates conda/conda-build and then updates all conda environments; conda clean --all.
  - update-poetry.sh: poetry self update.
- R and RStudio
  - update-R.sh: updates user R packages; checks and updates RStudio Desktop and Server .deb packages for Ubuntu Jammy (uses curl/dpkg).
- JavaScript/Node
  - update-npm.sh: npm -g update (global packages).
- Rust
  - update-rust.sh: rustup update; cargo install cargo-update; cargo install-update -a.
- Go
  - update-go.sh: detects latest Go release; downloads and installs it under ~/apps; relinks ~/apps/go; runs go-global-update to refresh installed tools.
- Julia
  - update-julia.sh: installs juliaup via cargo if available; juliaup update; Pkg.update() for default env.
- Desktop apps & tools
  - update-waterfox.sh: checks latest Waterfox release from GitHub, downloads, unpacks to /opt/waterfox (uses dtrx), and installs a .desktop entry if missing.
  - update-calibre.sh: updates Calibre via official installer.
  - update-youtube-dl.sh: self-update if installed under /usr/local/bin.
  - update-texlive.sh: tlmgr update --self/--all.
  - update-pihole.sh: pihole updatePihole.
- Containers and cleanup
  - update-lxc-containers.sh: for each RUNNING LXD container, copies these scripts into the container and runs update-all.sh inside via SSH; temporarily unmasks api.snapcraft.io if needed.
  - do-bedup.sh: runs bedup dedup if available.

Notes:
- update-steam.sh exists but is commented out in update-all.sh. It can install steamcmd and update all installed Steam apps when configured (see the script for details).
- The first lines in update-all.sh optionally self-update the repo via Git if a remote is configured.

## Requirements

- Linux with Bash; many scripts expect Ubuntu/Debian (APT) and Snap.
- Common CLI tools: sudo, curl, wget, nc, ping, sed, awk, grep.
- Tool-specific (only needed if you use that ecosystem):
  - Python: python3/pip, pipx, conda.
  - R: R, Rscript; optional RStudio Desktop/Server already installed for version checks.
  - Node: npm.
  - Rust: rustup, cargo.
  - Go: go; installs go-global-update on first run.
  - Julia: julia; optional cargo if juliaup isn’t present.
  - TeX Live: tlmgr.
  - LXD/LXC: lxc, SSH key-based auth to containers.
  - Waterfox: dtrx (for archive extraction); will use /media/adam-minipc/other/debs as a cache if writable, otherwise /tmp.

## Usage tips

- Run with bash -x for verbose tracing:
  ```bash
  bash -x ./update-all.sh
  ```
- You can comment/uncomment lines in update-all.sh to tailor what runs.
- Many steps require sudo; you may be prompted for your password.
- LXC containers: the updater tries each container’s IP and uses public key auth; ensure SSH access is set up inside containers.

## Caveats and behavior

- APT proxy handling: update-apt.sh inspects /etc/apt/apt.conf.d for Acquire::http::Proxy and flips http/https in entries under /etc/apt/sources.list.d for known hosts when a proxy is reachable.
- Snap host toggle: update-snap.sh may add/remove entries for api.snapcraft.io in /etc/hosts during refresh.
- Go install location: Go versions are placed under ~/apps/VERSION and symlinked to ~/apps/go.
- R updates: user library is updated (R_LIBS_USER); ownership of ~/R is adjusted to the current user.
- Waterfox: installs to /opt/waterfox and adds a desktop entry if missing; ensures proper ownership.

## License

No explicit license is provided. Use at your own risk.
