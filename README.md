# Cross OS Fonts

![Cross OS Fonts Banner](assets/banner/banner.png)

> Install Windows system fonts on Linux from an official Windows ISO or an existing dual-boot Windows installation.

Cross OS Fonts is a lightweight Bash script that copies Windows system fonts from a legitimate source and installs them for the **current Linux user**.

No packaging. No registry. No Windows VM required.

---

## ✨ Features

- 📀 Extract fonts directly from an official Windows installation ISO
- 💽 Copy fonts from an existing dual-boot Windows partition
- 📁 Use an already-downloaded Windows ISO
- 🔄 Automatically detects the correct Windows edition inside `install.wim`
- 💾 Creates timestamped backups before replacing existing fonts
- 👤 Installs fonts to the current user's home directory
- ⚡ Refreshes the font cache automatically

---

# How it Works

The script provides three installation methods.

## 🅰️ Download the Official Windows ISO

1. Open Microsoft's Windows download page.
2. Generate a download link.
3. Paste the temporary URL into the script.
4. The script downloads the ISO and extracts fonts from:

```

ISO
└── sources
└── install.wim
└── Windows
└── Fonts

```

---

## 🅱️ Use a Dual-Boot Windows Installation

If Windows already exists on the machine:

- Paste a mounted path

```

/mnt/windows

```

or

- Paste the Windows partition

```

/dev/sda2

```

The script mounts it read-only and copies the fonts directly.

No download required.

---

## 🅲 Use an Existing Windows ISO

Already have the ISO?

Simply provide its path.

```

~/Downloads/Win11.iso

```

The script extracts the fonts without modifying or deleting your ISO.

---

Regardless of the source, fonts are installed into

```

~/.local/share/fonts/cross-os

```

and the font cache is refreshed automatically.

---

# Requirements

## Debian / Ubuntu

```bash
sudo apt install curl p7zip-full fontconfig ntfs-3g
```

## Arch Linux

```bash
sudo pacman -S curl p7zip fontconfig ntfs-3g
```

## Fedora

```bash
sudo dnf install curl p7zip p7zip-plugins fontconfig ntfs-3g
```

## openSUSE

```bash
sudo zypper install curl 7zip fontconfig ntfs-3g
```

---

# Quick Start

Run directly from GitHub:

```bash
curl -O https://raw.githubusercontent.com/Sumon-Kayal/Cross-os-fonts/refs/heads/Sumon-Kayal-patch-1/cross-os-fonts.sh
chmod +x cross-os-fonts.sh
bash cross-os-fonts.sh
```

Or download first:

```bash
curl -O https://raw.githubusercontent.com/Sumon-Kayal/Cross-os-fonts/refs/heads/Sumon-Kayal-patch-1/cross-os-fonts.sh

chmod +x cross-os-fonts.sh

./cross-os-fonts.sh
```

---

# Usage

After launching the script:

1. Select one of the three installation methods.
2. Provide the requested ISO path, download URL, or Windows partition.
3. Confirm backup (if existing fonts are found).
4. Confirm installation.
5. (Download mode only) choose whether to keep the downloaded ISO.

---

# Installation Location

Fonts are installed into

```

~/.local/share/fonts/cross-os

```

No root privileges are required for installation.

Only Option **B** requires `sudo` to mount a Windows partition.

---

# Troubleshooting

### Mount failed

Usually caused by one of the following:

- `ntfs-3g` is not installed
- Windows Fast Startup is enabled
- The partition is BitLocker encrypted

Disable Fast Startup or fully shut down Windows before trying again.

---

### Fonts directory not found

The script automatically checks every edition inside `install.wim`.

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

```
ttf-mscorefonts-installer
```

Installs Microsoft's older Core Fonts (Arial, Times New Roman, Courier New, etc.) under Microsoft's EULA.

---

# License

This project is licensed under the **MIT License**.

The MIT license applies **only to this script** and **does not grant any rights to Microsoft's proprietary fonts**.
