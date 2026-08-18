# FAQ

Common questions about **Cross OS Fonts**. See the [README](README.md) for
setup and usage, and the [Project Roadmap](PROJECT_ROADMAP.md) for what's
done and what's still planned.

---

## About the Project

### Why did I build this?

Office documents made on Windows don't look the same when opened on
Linux. Calibri, Cambria, and the other modern default Office fonts
usually aren't installed there, so LibreOffice/OpenOffice quietly
substitutes something else — text reflows, page counts shift, layouts
drift. Metric-compatible fonts like Carlito and Caladea get close, but
"close" isn't "identical," and `ttf-mscorefonts-installer` only covers
the older Core Fonts (Arial, Times New Roman, etc.), not
Calibri/Cambria. The only reliable fix is the real fonts, and the only
legitimate way to get them is from a Windows installation you're
already licensed for — so this script automates pulling them from your
own ISO or dual-boot partition instead of approximating.

### Do I need a licensed copy of Windows?

Yes. The script only copies fonts from an ISO or partition you already
have a license for — it doesn't bundle or redistribute any fonts
itself.

### Which Windows versions work?

The tool is implemented to support any ISO whose image contains
`sources/install.wim` or `sources/install.esd` — that should cover
Windows 10, 11, and Server editions, though not all combinations have
been validated yet. See the [Project
Roadmap](PROJECT_ROADMAP.md#validation-checklist) for what's been
tested.

---

## Setup

### Do I need root/sudo?

Only for Option B (mounting a raw partition like `/dev/sda2`).
Downloading an ISO and installing fonts never needs root.

### Why wget2 instead of curl, and 7zip instead of p7zip?

Both distro package names moved — most repos now ship the archive tool
as `7zip`, and `wget2` is the actively maintained successor to `wget`.

### wget2 isn't found on Arch — is that a bug?

No — it's AUR-only on Arch (`yay -S wget2`). Everything else (`7zip`,
`fontconfig`, `ntfs-3g`) is in the official repos.

### What about openSUSE Leap?

`wget2` is available in openSUSE Tumbleweed but not in Leap 15.6's
default repositories. Use Tumbleweed or install `wget2` from an
alternative source.

---

## Using the Script

### Will it overwrite fonts I already installed with this tool?

No — it detects existing fonts in `~/.local/share/fonts/cross-os` and
offers a timestamped backup before touching anything.

### How do I remove the fonts later?

```bash
rm -rf ~/.local/share/fonts/cross-os
fc-cache -fv
```

See [Uninstalling](README.md#uninstalling) in the README for restoring
from a backup.

### Can I pipe this script straight into `bash`?

Don't — the script asks interactive questions, and piping it consumes
the input those prompts need. Download it to a file first, then run
the file.

### My ISO download died partway through — do I start over?

Yes, currently. Resumable downloads are on the roadmap but need a
safety check first (a stale partial file from a *different* URL could
otherwise get silently spliced together).

### My ISO has multiple Windows editions (Home, Pro, etc.) — which one does it use?

It checks each edition in order and uses the first one where it
actually finds font files.

### What happens to the ISO afterward?

Option A asks if you want to keep or delete it after install. Option C
never touches your existing ISO file at all.

### Does it work with a BitLocker-encrypted Windows partition?

No — decrypt or disable BitLocker first, same as with Fast
Startup/hibernation, or the mount will fail.

---

## Known Limitations

### Is LibreOffice/Office rendering guaranteed to match Windows exactly?

Not yet verified — that's still an open item in the roadmap's
[Phase 2 validation checklist](PROJECT_ROADMAP.md#validation-checklist).

---

See also: [README](README.md) · [Project Roadmap](PROJECT_ROADMAP.md)
