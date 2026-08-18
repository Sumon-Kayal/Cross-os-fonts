#!/bin/bash
set -e

BASE_DIR="$HOME/.cross-os-fonts"
FONTS_EXTRACT_DIR="$BASE_DIR/extract"
ISO_FILE="$BASE_DIR/source.iso"
TARGET_DIR="$HOME/.local/share/fonts/cross-os"
BACKUP_DIR="$HOME/.local/share/fonts/cross-os_backup_$(date +%Y%m%d_%H%M%S)"
MOUNT_POINT="$HOME/.cross-os-fonts/mount"
FONT_SRC=""
MOUNTED_BY_SCRIPT=0
MOUNT_ERR_FILE=$(mktemp)

# Runs on ANY exit (success, error, or Ctrl+C) — guarantees a partition we
# mounted never stays mounted if something fails mid-script.
cleanup_on_exit() {
    if [[ "$MOUNTED_BY_SCRIPT" -eq 1 ]] && mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        echo "🔌 Cleaning up: unmounting $MOUNT_POINT..."
        sudo umount "$MOUNT_POINT" 2>/dev/null || true
        rmdir "$MOUNT_POINT" 2>/dev/null || true
    fi
    rm -f "$MOUNT_ERR_FILE" 2>/dev/null || true
}
trap cleanup_on_exit EXIT

echo "=================================================="
echo "              cross-os-fonts                      "
echo "=================================================="

# --- Shared: yes/no confirmation prompt ---
# Accepts y / yes / n / no, case-insensitive (typing the full word "yes"
# or "no" used to be silently misread as the opposite of what the user
# meant). Anything else, including a bare Enter, falls back to $2 (the
# displayed default).
# Usage: confirm "Question text" "y"   -> shows [Y/n], defaults to yes
#        confirm "Question text" "n"   -> shows [y/N], defaults to no
confirm() {
    local prompt="$1" default="$2" reply hint
    if [[ "$default" == "y" ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
    read -rp "$prompt $hint " reply
    reply="${reply,,}"
    case "$reply" in
        y|yes) return 0 ;;
        n|no)  return 1 ;;
        *)     [[ "$default" == "y" ]] ;;
    esac
}

# --- Shared: back up existing fonts + install ---
install_fonts() {
    if ! command -v fc-cache &> /dev/null; then
        echo "❌ 'fc-cache' is required. Install with: sudo apt install fontconfig"
        exit 1
    fi

    local font_count
    font_count=$(find "$FONT_SRC" -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.ttc" \) | wc -l)
    if [[ "$font_count" -eq 0 ]]; then
        echo "❌ No font files found in: $FONT_SRC"
        exit 1
    fi
    echo "✅ Found $font_count font files."

    if [[ -d "$TARGET_DIR" ]] && [[ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
        echo ""
        if confirm "Existing fonts found in $TARGET_DIR. Back up before overwriting?" "y"; then
            mkdir -p "$BACKUP_DIR"
            # "/." (not "/*") so this also catches any hidden/dotfiles —
            # a bare glob silently matches nothing if only dotfiles exist.
            if ! cp -r "$TARGET_DIR"/. "$BACKUP_DIR"/ 2>/dev/null; then
                echo "❌ Backup failed. Aborting installation."
                exit 1
            fi
            echo "🗄️  Backed up existing fonts to $BACKUP_DIR"
        fi
    fi

    echo ""
    if confirm "Install all $font_count found fonts now?" "y"; then
        mkdir -p "$TARGET_DIR"
        local copy_failed=0
        while IFS= read -r -d '' font_file; do
            if ! cp "$font_file" "$TARGET_DIR/"; then
                copy_failed=1
                break
            fi
        done < <(find "$FONT_SRC" -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.ttc" \) -print0)
        if [[ "$copy_failed" -eq 1 ]]; then
            echo "❌ Font installation failed."
            exit 1
        fi
        fc-cache -fv > /dev/null
        echo "✅ Fonts installed to $TARGET_DIR"
    else
        echo "⏭️  Skipped installation."
    fi
}

# --- Shared: given a path to an ISO file, extract Fonts from it ---
# Implemented to support both install.wim and install.esd — should work
# with Windows 10, 11, and Server editions, though validation is incomplete.
# Not limited to Windows 11.
extract_fonts_from_iso() {
    local iso_path="$1"

    if ! command -v 7z &> /dev/null; then
        echo "❌ '7z' is required. Install with: sudo apt install 7zip"
        exit 1
    fi

    if [[ ! -f "$iso_path" ]]; then
        echo "❌ ISO file not found: $iso_path"
        exit 1
    fi
    if [[ ! -s "$iso_path" ]]; then
        echo "❌ ISO file is empty: $iso_path"
        exit 1
    fi

    rm -rf "$FONTS_EXTRACT_DIR"
    mkdir -p "$FONTS_EXTRACT_DIR"

    echo "📂 Extracting Windows image from ISO..."
    # Try both known image filenames — only one will normally exist, so
    # the other extraction attempt is expected to fail and is ignored.
    7z x "$iso_path" -o"$FONTS_EXTRACT_DIR" "sources/install.wim" -r -y > /dev/null 2>&1 || true
    7z x "$iso_path" -o"$FONTS_EXTRACT_DIR" "sources/install.esd" -r -y > /dev/null 2>&1 || true

    IMAGE_PATH="$FONTS_EXTRACT_DIR/sources/install.wim"
    if [[ ! -f "$IMAGE_PATH" ]]; then
        IMAGE_PATH="$FONTS_EXTRACT_DIR/sources/install.esd"
    fi
    if [[ ! -f "$IMAGE_PATH" ]]; then
        echo "❌ Neither install.wim nor install.esd found — ISO may be corrupt or not a standard bootable Windows ISO."
        exit 1
    fi

    echo "🔍 Detecting available Windows editions in $(basename "$IMAGE_PATH")..."
    # Each edition inside the image shows up as a numbered top-level folder (1, 2, 3...).
    # Multi-edition ISOs can have several; single-edition ISOs just "1".
    # Use -slt (structured listing) for reliable parsing across 7z versions.
    local indices
    indices=$(7z l -slt "$IMAGE_PATH" 2>/dev/null | grep '^Path = ' | sed 's/^Path = //' | grep -oE '^[0-9]+' | sort -un)
    if [[ -z "$indices" ]]; then
        indices="1"
    fi

    echo "📂 Extracting fonts (this can take a minute)..."
    for idx in $indices; do
        rm -rf "$FONTS_EXTRACT_DIR/wim_out"
        7z x "$IMAGE_PATH" -o"$FONTS_EXTRACT_DIR/wim_out" "${idx}/Windows/Fonts" -r -y > /dev/null 2>&1 || true
        FONT_SRC=$(find "$FONTS_EXTRACT_DIR/wim_out" -type d -iname "Fonts" 2>/dev/null | head -n 1)
        if [[ -n "$FONT_SRC" ]] && [[ -n "$(find "$FONT_SRC" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' \) 2>/dev/null)" ]]; then
            echo "✅ Using edition index $idx"
            break
        fi
        FONT_SRC=""
    done

    if [[ -z "$FONT_SRC" ]]; then
        echo "❌ Fonts directory not found inside $(basename "$IMAGE_PATH") (tried indices: $indices)."
        exit 1
    fi
}

# --- Option A: download official ISO ---
run_option_a() {
    if ! command -v wget2 &> /dev/null; then
        echo "❌ 'wget2' is required. Install with: sudo apt install wget2"
        echo "   (Arch Linux: wget2 isn't in the official repos — install it from the AUR, e.g. 'yay -S wget2')"
        exit 1
    fi

    echo ""
    echo "Open Microsoft's software-download page for the Windows version"
    echo "you want, for example:"
    echo "  https://www.microsoft.com/software-download/windows11"
    echo ""
    echo "Choose 'Download Disk Image (ISO)', select the edition and"
    echo "language, and copy the generated link. Any Windows ISO whose"
    echo "image contains sources/install.wim or sources/install.esd"
    echo "works here — this isn't limited to Windows 11."
    echo ""
    read -rp "Paste the Windows ISO download URL here: " DOWNLOAD_URL

    if [[ -z "$DOWNLOAD_URL" ]]; then
        echo "❌ No URL provided."
        exit 1
    fi
    if [[ ! "$DOWNLOAD_URL" =~ ^https:// ]]; then
        echo "❌ URL must start with https://"
        exit 1
    fi

    mkdir -p "$BASE_DIR"
    echo "🌐 Downloading ISO (~5-6GB, be patient)..."
    if ! wget2 -O "$ISO_FILE" "$DOWNLOAD_URL"; then
        echo "❌ Download failed."
        exit 1
    fi

    extract_fonts_from_iso "$ISO_FILE"
    install_fonts

    echo ""
    if confirm "Keep the downloaded ISO at $ISO_FILE?" "n"; then
        echo "💾 ISO kept at: $ISO_FILE"
    else
        rm -f "$ISO_FILE"
        echo "🧹 ISO deleted."
    fi
    rm -rf "$FONTS_EXTRACT_DIR"
}

# --- Option C: use an already-downloaded ISO on disk ---
run_option_c() {
    echo ""
    read -rp "Paste the full path to your existing Windows ISO: " LOCAL_ISO_PATH

    if [[ -z "$LOCAL_ISO_PATH" ]]; then
        echo "❌ No path provided."
        exit 1
    fi
    # Expand ~ if user types it
    LOCAL_ISO_PATH="${LOCAL_ISO_PATH/#\~/$HOME}"

    if [[ ! -f "$LOCAL_ISO_PATH" ]]; then
        echo "❌ File not found: $LOCAL_ISO_PATH"
        exit 1
    fi
    if [[ "$LOCAL_ISO_PATH" != *.iso && "$LOCAL_ISO_PATH" != *.ISO ]]; then
        confirm "⚠️  That file doesn't have a .iso extension — continue anyway?" "n" || exit 1
    fi

    extract_fonts_from_iso "$LOCAL_ISO_PATH"
    install_fonts

    rm -rf "$FONTS_EXTRACT_DIR"
    echo "ℹ️  Original ISO left untouched at: $LOCAL_ISO_PATH"
}

# --- Option B: use an existing dual-boot Windows partition ---
run_option_b() {
    echo ""
    echo "You can provide either:"
    echo "  1) A path that's already mounted (e.g. /mnt/windows, /media/you/OS)"
    echo "  2) An unmounted block device (e.g. /dev/sda2) — the script will mount it"
    echo ""
    read -rp "Paste the Windows drive path or device: " DRIVE_PATH

    if [[ -z "$DRIVE_PATH" ]]; then
        echo "❌ No path provided."
        exit 1
    fi

    if [[ -b "$DRIVE_PATH" ]]; then
        # It's a raw block device — mount it ourselves
        if ! command -v mount &> /dev/null; then
            echo "❌ 'mount' command not available."
            exit 1
        fi
        echo "🔧 Mounting $DRIVE_PATH to $MOUNT_POINT (requires sudo)..."
        mkdir -p "$MOUNT_POINT"
        if ! sudo mount -o ro "$DRIVE_PATH" "$MOUNT_POINT" 2>"$MOUNT_ERR_FILE"; then
            echo "❌ Mount failed:"
            cat "$MOUNT_ERR_FILE"
            echo "If this is an NTFS partition, make sure ntfs-3g is installed:"
            echo "  sudo apt install ntfs-3g"
            exit 1
        fi
        MOUNTED_BY_SCRIPT=1
        SEARCH_ROOT="$MOUNT_POINT"
    elif [[ -d "$DRIVE_PATH" ]]; then
        SEARCH_ROOT="$DRIVE_PATH"
    else
        echo "❌ Path not found: $DRIVE_PATH"
        exit 1
    fi

    echo "🔍 Looking for Windows/Fonts under $SEARCH_ROOT..."
    FONT_SRC=$(find "$SEARCH_ROOT" -maxdepth 3 -type d -ipath "*/Windows/Fonts" 2>/dev/null | head -n 1)

    if [[ -z "$FONT_SRC" ]]; then
        echo "❌ Could not find a Windows/Fonts directory under $SEARCH_ROOT."
        echo "Make sure this is the root of your Windows (C:) partition."
        exit 1
    fi
    echo "✅ Found: $FONT_SRC"

    install_fonts

    if [[ "$MOUNTED_BY_SCRIPT" -eq 1 ]]; then
        echo ""
        if confirm "Unmount $DRIVE_PATH now?" "y"; then
            if sudo umount "$MOUNT_POINT"; then
                rmdir "$MOUNT_POINT" 2>/dev/null || true
                MOUNTED_BY_SCRIPT=0
                echo "🔌 Unmounted."
            else
                echo "⚠️  Unmount failed — you may need to run: sudo umount $MOUNT_POINT"
                echo "   (the script will retry silently on exit)"
            fi
        else
            MOUNTED_BY_SCRIPT=0
            echo "ℹ️  Mount preserved at $MOUNT_POINT"
        fi
    fi
}

# --- Menu ---
echo ""
echo "How do you want to get the fonts?"
echo "  [A] Download an official Windows ISO from Microsoft"
echo "  [B] Use an existing dual-boot Windows partition on this machine"
echo "  [C] Use a Windows ISO you already have downloaded"
echo ""
read -rp "Choose A, B, or C: " MODE

case "${MODE^^}" in
    A) run_option_a ;;
    B) run_option_b ;;
    C) run_option_c ;;
    *) echo "❌ Invalid option. Choose A, B, or C."; exit 1 ;;
esac

echo "=================================================="
echo "✅ Done."
echo "=================================================="
