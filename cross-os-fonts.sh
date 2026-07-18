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
        read -rp "Existing fonts found in $TARGET_DIR. Back up before overwriting? [Y/n] " backup_confirm
        if [[ ! "$backup_confirm" =~ ^[Nn]$ ]]; then
            mkdir -p "$BACKUP_DIR"
            if ! cp -r "$TARGET_DIR"/* "$BACKUP_DIR/" 2>/dev/null; then
                echo "❌ Backup failed. Aborting installation."
                exit 1
            fi
            echo "🗄️  Backed up existing fonts to $BACKUP_DIR"
        fi
    fi

    echo ""
    read -rp "Install all $font_count found fonts now? [Y/n] " install_confirm
    if [[ ! "$install_confirm" =~ ^[Nn]$ ]]; then
        mkdir -p "$TARGET_DIR"
        if ! find "$FONT_SRC" -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.ttc" \) -exec cp {} "$TARGET_DIR/" \; ; then
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
extract_fonts_from_iso() {
    local iso_path="$1"

    if ! command -v 7z &> /dev/null; then
        echo "❌ '7z' is required. Install with: sudo apt install p7zip-full"
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

    mkdir -p "$FONTS_EXTRACT_DIR"

    echo "📂 Extracting install.wim from ISO..."
    if ! 7z x "$iso_path" -o"$FONTS_EXTRACT_DIR" "sources/install.wim" -r -y > /dev/null 2>&1; then
        echo "❌ Could not extract install.wim from ISO. ISO may be corrupt or wrong format."
        exit 1
    fi

    WIM_PATH="$FONTS_EXTRACT_DIR/sources/install.wim"
    if [[ ! -f "$WIM_PATH" ]]; then
        echo "❌ install.wim not found — this may not be a standard bootable Windows 11 ISO."
        exit 1
    fi

    echo "🔍 Detecting available Windows editions in install.wim..."
    # Each edition inside a WIM shows up as a numbered top-level folder (1, 2, 3...).
    # Multi-edition ISOs can have several; single-edition ISOs just "1".
    # Use -slt (structured listing) for reliable parsing across 7z versions.
    local indices
    indices=$(7z l -slt "$WIM_PATH" 2>/dev/null | grep '^Path = ' | sed 's/^Path = //' | grep -oE '^[0-9]+' | sort -un)
    if [[ -z "$indices" ]]; then
        indices="1"
    fi

    echo "📂 Extracting fonts from install.wim (this can take a minute)..."
    for idx in $indices; do
        rm -rf "$FONTS_EXTRACT_DIR/wim_out"
        7z x "$WIM_PATH" -o"$FONTS_EXTRACT_DIR/wim_out" "${idx}/Windows/Fonts" -r -y > /dev/null 2>&1 || true
        FONT_SRC=$(find "$FONTS_EXTRACT_DIR/wim_out" -type d -iname "Fonts" 2>/dev/null | head -n 1)
        if [[ -n "$FONT_SRC" ]] && [[ -n "$(find "$FONT_SRC" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' \) 2>/dev/null)" ]]; then
            echo "✅ Using edition index $idx"
            break
        fi
        FONT_SRC=""
    done

    if [[ -z "$FONT_SRC" ]]; then
        echo "❌ Fonts directory not found inside install.wim (tried indices: $indices)."
        exit 1
    fi
}

# --- Option A: download official ISO ---
run_option_a() {
    if ! command -v curl &> /dev/null; then
        echo "❌ 'curl' is required. Install with: sudo apt install curl"
        exit 1
    fi

    echo ""
    echo "Open this page in your browser:"
    echo "  https://www.microsoft.com/software-download/windows11"
    echo ""
    echo "Choose 'Download Windows 11 Disk Image (ISO)', select"
    echo "the edition and language, and copy the generated link."
    echo ""
    read -rp "Paste the Windows 11 ISO download URL here: " DOWNLOAD_URL

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
    curl -L --fail -o "$ISO_FILE" "$DOWNLOAD_URL"

    extract_fonts_from_iso "$ISO_FILE"
    install_fonts

    echo ""
    read -rp "Keep the downloaded ISO at $ISO_FILE? [y/N] " keep_iso
    if [[ ! "$keep_iso" =~ ^[Yy]$ ]]; then
        rm -f "$ISO_FILE"
        echo "🧹 ISO deleted."
    else
        echo "💾 ISO kept at: $ISO_FILE"
    fi
    rm -rf "$FONTS_EXTRACT_DIR/wim_out" "$FONTS_EXTRACT_DIR/sources"
}

# --- Option C: use an already-downloaded ISO on disk ---
run_option_c() {
    echo ""
    read -rp "Paste the full path to your existing Windows 11 ISO: " LOCAL_ISO_PATH

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
        echo "⚠️  That file doesn't have a .iso extension — continue anyway? [y/N]"
        read -rp "> " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    fi

    extract_fonts_from_iso "$LOCAL_ISO_PATH"
    install_fonts

    rm -rf "$FONTS_EXTRACT_DIR/wim_out" "$FONTS_EXTRACT_DIR/sources"
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
        read -rp "Unmount $DRIVE_PATH now? [Y/n] " unmount_confirm
        if [[ ! "$unmount_confirm" =~ ^[Nn]$ ]]; then
            sudo umount "$MOUNT_POINT"
            rmdir "$MOUNT_POINT" 2>/dev/null || true
            MOUNTED_BY_SCRIPT=0
            echo "🔌 Unmounted."
        else
            MOUNTED_BY_SCRIPT=0
            echo "ℹ️  Mount preserved at $MOUNT_POINT"
        fi
    fi
}

# --- Menu ---
echo ""
echo "How do you want to get the fonts?"
echo "  [A] Download the official Windows 11 ISO from Microsoft"
echo "  [B] Use an existing dual-boot Windows partition on this machine"
echo "  [C] Use a Windows 11 ISO you already have downloaded"
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
