# Cross OS Fonts

![Cross OS Fonts Banner](assets/banner/banner.png)

> Install Windows system fonts on Linux from an official Windows ISO (containing `sources/install.wim` **or** `sources/install.esd`) or an existing dual-boot Windows installation. Implemented to support any Windows edition Microsoft ships as one of those two image formats — Windows 10, Windows 11, and Windows Server ISOs should all work, though comprehensive validation across all editions and versions is pending.

Cross OS Fonts is a lightweight Bash script that copies Windows system fonts from a legitimate source and installs them for the **current Linux user**.

No packaging. No registry. No Windows VM required.

---

## Contents

- [Features](#-features)
- [How it Works](#how-it-works)
- [Requirements](#requirements)
- [Pre-Flight Checklist](#pre-flight-checklist)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Installation Location](#installation-location)
- [Uninstalling](#uninstalling)
- [Troubleshooting](#troubleshooting)
- [License Notice](#license-notice)
- [License](#license)
- [FAQ](FAQ.md)
- [Project Roadmap](PROJECT_ROADMAP.md)

---

## ✨ Features

- 📀 Extract fonts directly from an official Windows installation ISO — implemented to support both `install.wim` **and** `install.esd` images (validation pending for all Windows versions)
- 💽 Copy fonts from an existing dual-boot Windows partition
- 📁 Use an already-downloaded Windows ISO
- 🔄 Automatically detects the correct Windows edition inside the image (multi-edition ISO support implemented, validation pending)
- 💾 Creates timestamped backups before replacing existing fonts
- 👤 Installs fonts to the current user's home directory (no root needed for installation itself)
- ⚡ Refreshes the font cache automatically
- 🧭 Every yes/no prompt accepts full words ("yes"/"no") as well as single letters, case-insensitively

---

## How it Works

The script provides three installation methods.

### 🅰️ Download an Official Windows ISO

1. Open Microsoft's software-download page for the Windows version you want.
2. Generate a download link.
3. Paste the temporary URL into the script.
4. The script downloads the ISO and extracts fonts from whichever image file it contains:

```text
ISO
└── sources
    ├── install.wim   (most ISOs)
    │       or
    └── install.esd   (some ISOs use this instead)
        └── [Windows edition index]
            └── Windows
                └── Fonts
```

The script tries `install.wim` first, then falls back to `install.esd` automatically — you don't need to know in advance which one your ISO uses.

---

### 🅱️ Use a Dual-Boot Windows Installation

If Windows already exists on the machine:

- Paste a mounted path

```text
/mnt/windows
```

or

- Paste the Windows partition

```text
/dev/sda2
```

The script mounts it read-only and copies the fonts directly.

No download required.

---

### 🅲 Use an Existing Windows ISO

Already have the ISO?

Simply provide its path.

```text
~/Downloads/Windows.iso
```

The script extracts the fonts without modifying or deleting your ISO.

---

Regardless of the source, fonts are installed into

```text
~/.local/share/fonts/cross-os
```

and the font cache is refreshed automatically.

---

# Requirements

Every distro needs `wget2` (downloads the ISO in Option A), `7zip` (reads the ISO/image in Options A and C), `fontconfig` (refreshes the font cache), and `ntfs-3g` (mounts an NTFS Windows partition in Option B).

## Debian / Ubuntu

```bash
sudo apt install wget2 7zip fontconfig ntfs-3g
```

## Arch Linux

```bash
sudo pacman -S 7zip fontconfig ntfs-3g
```

`wget2` isn't in Arch's official repos — install it from the AUR with your preferred helper:

```bash
yay -S wget2
# or: paru -S wget2
```

Without an AUR helper, build it manually:

```bash
git clone https://aur.archlinux.org/wget2.git
cd wget2
makepkg -si
```

## Fedora

```bash
sudo dnf install wget2 7zip fontconfig ntfs-3g
```

## openSUSE

### openSUSE Tumbleweed

```bash
sudo zypper install wget2 7zip fontconfig ntfs-3g
```

### openSUSE Leap 15.6

`wget2` is not available in the default Leap 15.6 repositories. Use Tumbleweed or install `wget2` from an alternative source.

---

# Pre-Flight Checklist

Tick these off before running the script — saves a false start partway through a multi-gigabyte download.

## Debian / Ubuntu
- [ ] `sudo apt update`
- [ ] `sudo apt install wget2 7zip fontconfig ntfs-3g`
- [ ] `wget2 --version` runs without error
- [ ] `7z` runs without error (prints the 7-Zip banner)
- [ ] `fc-cache --version` runs without error

## Arch Linux
- [ ] `sudo pacman -S 7zip fontconfig ntfs-3g`
- [ ] `wget2` installed from the AUR (`yay -S wget2` or manual `makepkg -si`)
- [ ] `wget2 --version` runs without error
- [ ] `7z` runs without error
- [ ] `fc-cache --version` runs without error

## Fedora
- [ ] `sudo dnf install wget2 7zip fontconfig ntfs-3g`
- [ ] `wget2 --version` runs without error
- [ ] `7z` runs without error
- [ ] `fc-cache --version` runs without error

## openSUSE
- [ ] `sudo zypper install wget2 7zip fontconfig ntfs-3g`
- [ ] `wget2 --version` runs without error
- [ ] `7z` runs without error
- [ ] `fc-cache --version` runs without error

## All distros, regardless of which option you'll use
- [ ] Decided which install method you'll use (A: download, B: dual-boot partition, C: existing ISO)
- [ ] **Option A only:** ~12 GB free under `$HOME` (the ISO and its extracted image both land there before cleanup)
- [ ] **Option B only:** `ntfs-3g` installed, and you know the mount path or block device (e.g. `/dev/sda2`) — plus `sudo` access, since mounting needs it
- [ ] **Option B only:** Windows is fully shut down (not Fast Startup / hibernated) and not BitLocker-encrypted, or the mount will fail
- [ ] **Option C only:** you know the full path to your existing ISO

---

# Quick Start

> **Don't pipe this script straight into `bash`** (e.g. `wget2 -O- ... | bash`). The script asks interactive questions with `read`, and piping the script itself through stdin leaves nothing there for those prompts to read, so they get skipped or fail. Always download it to a file first, then run that file.

```bash
wget2 -O cross-os-fonts.sh https://raw.githubusercontent.com/Sumon-Kayal/Cross-os-fonts/refs/heads/main/cross-os-fonts.sh
chmod +x cross-os-fonts.sh
./cross-os-fonts.sh
```

---

# Usage

After launching the script:

1. Select one of the three installation methods (A, B, or C).
2. Provide the requested ISO path, download URL, or Windows partition.
3. Confirm backup (if existing fonts are found).
4. Confirm installation.
5. (Download mode only) choose whether to keep the downloaded ISO.

Yes/no confirmation prompts accept a full "yes"/"no" as well as a single "y"/"n" letter, in any case.

---

# Installation Location

Fonts are installed into

```text
~/.local/share/fonts/cross-os
```

No root privileges are required for installation.

Only Option **B** requires `sudo` — to mount a Windows partition.

---

# Uninstalling

To remove fonts the script installed:

```bash
rm -rf ~/.local/share/fonts/cross-os
fc-cache -fv
```

If you took a backup during installation, your previous fonts are sitting in a timestamped folder next to it:

```text
~/.local/share/fonts/cross-os_backup_YYYYMMDD_HHMMSS
```

Restore one by copying its contents back into `~/.local/share/fonts/cross-os` (or wherever you'd like) and re-running `fc-cache -fv`.

---

# Troubleshooting

## `wget2: command not found`

Install it per the [Requirements](#requirements) section above. On Arch Linux this specifically means the AUR — it isn't in `core`/`extra`.

## `7z: command not found`

Install the `7zip` package for your distro (see [Requirements](#requirements)). Older guides mention `p7zip`/`p7zip-full` — most distros have since moved to a package simply named `7zip`.

## Mount failed

Usually caused by one of the following:

- `ntfs-3g` is not installed
- Windows Fast Startup is enabled
- The partition is BitLocker encrypted

Disable Fast Startup or fully shut down Windows before trying again.

---

## Fonts directory not found

The script automatically checks every edition inside the image, and tries both `install.wim` and `install.esd`.

If no Fonts directory is found, the ISO is likely:

- a language pack
- an update image
- or another non-standard Windows ISO

---

# License Notice

> **Windows fonts are proprietary software.**

This project **does not include or redistribute any fonts.**

The script only copies fonts from:

- an official Microsoft Windows installation ISO
- or your own licensed Windows installation.

You are responsible for complying with Microsoft's licensing terms.

---

## Free Alternatives

If you prefer open-source fonts:

- Carlito (Calibri-compatible)
- Caladea (Cambria-compatible)

---

## Other Proprietary Option

```text
ttf-mscorefonts-installer
```

Installs Microsoft's older Core Fonts (Arial, Times New Roman, Courier New, etc.) under Microsoft's EULA.

---

# License

This project is licensed under the **MIT License**.

The MIT license applies **only to this script** and **does not grant any rights to Microsoft's proprietary fonts**.
