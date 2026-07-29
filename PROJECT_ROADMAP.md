# Cross OS Fonts Roadmap

> Project roadmap for developing and validating **Cross OS Fonts**.

## Vision

Provide the easiest and safest way to install Windows system fonts on
Linux using a user's own licensed Windows installation media or
installation.

------------------------------------------------------------------------

# Phase 1 -- Foundation ✅

- [x] Core Bash installer
- [x] Interactive menu
- [x] ISO support (`install.wim` **and** `install.esd`) — implemented, validation pending
- [x] Existing Windows installation support (dual-boot partition)
- [x] Use an already-downloaded local ISO (no re-download needed)
- [x] Font installation into user profile
- [x] Font cache refresh
- [x] Basic README

## Phase 1.1 -- Hardening (this patch)

- [x] Fixed yes/no prompts silently doing the opposite of what the user
      typed when they answered with a full word ("yes"/"no") instead of
      a single letter -- worst case, typing "yes" to *keep* the
      downloaded ISO deleted it instead
- [x] Fixed the Option B unmount step so a failed `umount` fails
      gracefully instead of killing the script outright
- [x] Fixed font backups silently skipping hidden/dotfiles
- [x] Replaced `curl` with `wget2`
- [x] Replaced `p7zip`/`p7zip-full` with `7zip` (current official
      package name on Arch, Fedora, Debian/Ubuntu, and openSUSE)
- [x] Generalized "Windows 11"-only wording -- any Windows 10/11/Server
      ISO now works
- [x] README rewritten: table of contents, per-distro pre-flight
      checklist, uninstall instructions, expanded troubleshooting

------------------------------------------------------------------------

# Phase 2 -- Ubuntu Family Testing 🚧

Goal: verify on **real hardware**.

## Target distributions

- [ ] Ubuntu LTS
- [ ] Linux Mint
- [ ] Ubuntu Cinnamon
- [ ] Kubuntu
- [ ] Xubuntu
- [ ] Lubuntu
- [ ] Ubuntu MATE
- [ ] Ubuntu Budgie
- [ ] Pop!\_OS
- [ ] Zorin OS
- [ ] elementary OS

## Validation checklist

- [ ] Script executes successfully
- [ ] Fonts detected
- [ ] Fonts installed correctly
- [ ] LibreOffice renders DOCX correctly
- [ ] LibreOffice renders XLSX correctly
- [ ] LibreOffice renders PPTX correctly
- [ ] OpenOffice compatibility
- [ ] PDF export matches Windows output

------------------------------------------------------------------------

# Phase 3 -- Debian Family

- [ ] Debian Stable
- [ ] MX Linux

------------------------------------------------------------------------

# Phase 4 -- RPM Family

- [ ] Fedora
- [ ] openSUSE Leap
- [ ] openSUSE Tumbleweed

------------------------------------------------------------------------

# Phase 5 -- Arch Family

- [ ] Arch Linux
- [ ] EndeavourOS
- [ ] Manjaro
- [ ] Garuda
- [ ] CachyOS

------------------------------------------------------------------------

# Documentation

- [x] Expanded README
- [ ] Screenshots
- [x] Troubleshooting
- [x] FAQ
- [ ] Compatibility matrix
- [ ] Changelog

------------------------------------------------------------------------

# Quality Assurance

- [ ] Run ShellCheck
- [ ] Test on real hardware
- [ ] Verify installer cleanup
- [ ] Test installer recovery
- [ ] Regression testing after changes

------------------------------------------------------------------------

# Future Ideas

- [ ] Better dependency detection
- [ ] Non-interactive mode
- [ ] Verbose/debug mode
- [ ] CI checks
- [ ] Resumable ISO downloads (`wget2 -c`) -- needs care: the ISO path
      is fixed per run, so resuming against a stale partial file left
      over from a *different* URL could silently splice two different
      ISOs together

------------------------------------------------------------------------

# Release Milestones

- [x] v0.1 -- Initial prototype
- [ ] v0.5 -- Ubuntu family verified
- [ ] v0.8 -- Major Linux families supported
- [ ] v1.0 -- Stable release after extensive real-hardware testing

------------------------------------------------------------------------

# Success Criteria

- Reliable installation
- Consistent Office document rendering
- Clear documentation
- Easy one-command usage
- Community feedback and bug reports
