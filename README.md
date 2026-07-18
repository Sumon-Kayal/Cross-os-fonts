# cross-os-fonts

A small Bash script that copies system fonts from an official Windows installer image or an existing dual-boot Windows partition, and installs them for the current user on Linux.

This works directly against the official bootable installer ISO, which 7-Zip can read natively.

## How it works

The script offers three ways to source the fonts:

- **[A] Download the official ISO** — you open Microsoft's download page yourself, copy the generated (time-limited) link, and paste it in. The script downloads the ISO, then digs through two nested containers (`sources/install.wim` → `Windows/Fonts`) to pull out the fonts.
- **[B] Use an existing dual-boot Windows partition** — if Windows is already installed alongside Linux on this machine, paste either an already-mounted path (e.g. `/mnt/windows`) or a raw block device (e.g. `/dev/sda2`), and the script mounts it read-only, finds `Windows/Fonts`, and copies from there directly. No download needed.
- **[C] Use an ISO you already have** — if you've already downloaded the ISO, paste its path and the script extracts fonts from it without downloading anything again. Your original ISO is never modified or deleted.

All three paths converge on the same install step: fonts are backed up (timestamped) if you already have some installed, then copied to `~/.local/share/fonts/cross-os` and the font cache is refreshed.

Multi-edition ISOs are handled automatically — the script detects every edition packed inside `install.wim` and tries each one until it finds a valid `Fonts` folder, rather than assuming the first edition is always the right one.

## Requirements

- `curl` (Option A only)
- `7z` (`p7zip-full`) (Options A and C)
- `fc-cache` (`fontconfig`)
- `ntfs-3g` (Option B, if mounting an NTFS partition yourself)

Install on Debian/Ubuntu:
```bash
sudo apt install curl p7zip-full fontconfig ntfs-3g
```

## Usage

```bash
chmod +x cross-os-fonts.sh
./cross-os-fonts.sh
```

Follow the prompts:
1. Choose **A**, **B**, or **C** depending on how you want to source the fonts.
2. Provide the URL, drive path, or ISO path as asked.
3. Confirm backup of existing fonts (if any).
4. Confirm font installation.
5. (Option A only) choose whether to keep the downloaded ISO.

Fonts are installed to `~/.local/share/fonts/cross-os` (user-level, no root required for the install step itself — Option B's mount step needs `sudo`).

## Troubleshooting

- **"Mount failed" in Option B**: usually means `ntfs-3g` isn't installed. Run `sudo apt install ntfs-3g` and try again. Partitions with BitLocker or a hibernation lock from Fast Startup can also refuse read-only mounts from Linux — fully shut down Windows (not "Fast Startup" sleep) before mounting.
- **"Fonts directory not found" in Option A/C**: the script tries every edition packed into `install.wim`, not just the first one, so this usually means the source ISO itself is non-standard (a language pack ISO, an update-only ISO, etc.) rather than a full installer ISO.

## ⚠️ Licensing notice

The fonts this script copies are proprietary and licensed as part of the source operating system. The vendor's EULA does not grant rights to extract and redistribute these fonts for use outside a licensed installation. This script is provided for personal, informational, and educational use on a machine where you hold a valid license for the source OS. You are responsible for complying with the applicable font licensing terms.

If you just want visually similar open alternatives without any licensing concerns, consider:
- `ttf-mscorefonts-installer` (apt) — for older core fonts
- [Carlito](https://fontlibrary.org/en/font/carlito) / Caladea — metric-compatible substitutes for Calibri/Cambria

## License

This script is released under the [MIT License](LICENSE). The MIT license covers this script only — it does not extend any rights to the fonts it extracts.
