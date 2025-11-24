#!/bin/bash

# Variables to update for different apps
APP_NAME="balena-etcher"
DISPLAY_NAME="Balena Etcher"
REPO="balena-io/etcher"
AMD_SUFFIX="x64.AppImage"
ARM_SUFFIX=""
ICON_URL="https://upload.wikimedia.org/wikipedia/commons/2/2d/Etcher-icon.png"
# Directories
ADDONS_DIR="/userdata/system/add-ons"
CONFIGS_DIR="/userdata/system/configs"
DESKTOP_DIR="/usr/share/applications"
CUSTOM_SCRIPT="/userdata/system/custom.sh"
APP_CONFIG_DIR="${CONFIGS_DIR}/${APP_NAME,,}"
PERSISTENT_DESKTOP="${APP_CONFIG_DIR}/${APP_NAME,,}.desktop"
DESKTOP_FILE="${DESKTOP_DIR}/${APP_NAME,,}.desktop"

# Ensure directories exist
echo "Creating necessary directories..."
mkdir -p "$APP_CONFIG_DIR" "$ADDONS_DIR/${APP_NAME,,}"
mkdir -p "$ADDONS_DIR/${APP_NAME,,}/extra"

# ==========================================================
# Step 1: Detect architecture AND find newest release WITH an AppImage
# ==========================================================

echo "Detecting system architecture..."
arch=$(uname -m)

if [ "$arch" == "x86_64" ]; then
    echo "Architecture: x86_64 detected."
    SUFFIX="$AMD_SUFFIX"

elif [ "$arch" == "aarch64" ]; then
    echo "Architecture: arm64 detected."
    if [ -z "$ARM_SUFFIX" ]; then
        echo "No ARM64 AppImage suffix provided. Skipping download. Exiting."
        exit 1
    fi
    SUFFIX="$ARM_SUFFIX"

else
    echo "Unsupported architecture: $arch. Exiting."
    exit 1
fi

echo "Searching releases for the newest one containing an AppImage ($SUFFIX)..."

appimage_url=$(
    curl -s "https://api.github.com/repos/$REPO/releases" \
    | jq -r --arg SUFFIX "$SUFFIX" '
        [ .[]
          | select(.draft == false and .prerelease == false)
          | select(any(.assets[]?; .name | endswith($SUFFIX)))
        ]
        | first
        | .assets[]
        | select(.name | endswith($SUFFIX))
        | .browser_download_url
    '
)

if [ -z "$appimage_url" ] || [ "$appimage_url" = "null" ]; then
    echo "No suitable AppImage found for architecture: $arch. Exiting."
    exit 1
fi

echo "Found AppImage: $appimage_url"

# ==========================================================

# Step 2: Download the AppImage
echo "Downloading $APP_NAME AppImage from $appimage_url..."
wget -q --show-progress -O "$ADDONS_DIR/${APP_NAME,,}/${APP_NAME,,}.AppImage" "$appimage_url"

if [ $? -ne 0 ]; then
    echo "Failed to download $APP_NAME AppImage."
    exit 1
fi

chmod a+x "$ADDONS_DIR/${APP_NAME,,}/${APP_NAME,,}.AppImage"
echo "$APP_NAME AppImage downloaded and marked as executable."

# Step 2.5: Download the application icon
echo "Downloading $APP_NAME icon..."
wget -q --show-progress -O "$ADDONS_DIR/${APP_NAME,,}/extra/${APP_NAME,,}-icon.png" "$ICON_URL"

if [ $? -ne 0 ]; then
    echo "Failed to download $APP_NAME icon."
    exit 1
fi

# Step 3: Create persistent desktop entry
echo "Creating persistent desktop entry for $APP_NAME..."
cat <<EOF > "$PERSISTENT_DESKTOP"
[Desktop Entry]
Version=1.0
Type=Application
Name=$DISPLAY_NAME
Exec=$ADDONS_DIR/${APP_NAME,,}/${APP_NAME,,}.AppImage --no-sandbox
Icon=$ADDONS_DIR/${APP_NAME,,}/extra/${APP_NAME,,}-icon.png
Terminal=false
Categories=Game;batocera.linux;
EOF

chmod +x "$PERSISTENT_DESKTOP"

cp "$PERSISTENT_DESKTOP" "$DESKTOP_FILE"
chmod +x "$DESKTOP_FILE"

# Ensure the desktop entry is always restored to /usr/share/applications
echo "Ensuring $APP_NAME desktop entry is restored at startup..."
cat <<EOF > "${APP_CONFIG_DIR}/restore_desktop_entry.sh"
#!/bin/bash
# Restore $APP_NAME desktop entry
if [ ! -f "$DESKTOP_FILE" ]; then
    echo "Restoring $APP_NAME desktop entry..."
    cp "$PERSISTENT_DESKTOP" "$DESKTOP_FILE"
    chmod +x "$DESKTOP_FILE"
    echo "$APP_NAME desktop entry restored."
else
    echo "$APP_NAME desktop entry already exists."
fi
EOF
chmod +x "${APP_CONFIG_DIR}/restore_desktop_entry.sh"

# Add to startup (Option C: create or append safely)
echo "Adding desktop entry restore script to startup..."

if [ -f "$CUSTOM_SCRIPT" ]; then
    echo "Existing custom.sh found, appending restore call if not already present..."
    # Only append if our restore call isn't already there
    if ! grep -q "${APP_CONFIG_DIR}/restore_desktop_entry.sh" "$CUSTOM_SCRIPT"; then
        cat <<EOF >> "$CUSTOM_SCRIPT"

# Restore $APP_NAME desktop entry at startup
bash "${APP_CONFIG_DIR}/restore_desktop_entry.sh" &
EOF
    else
        echo "Restore call already present in custom.sh, skipping append."
    fi
else
    echo "No existing custom.sh, creating new one..."
    cat <<EOF > "$CUSTOM_SCRIPT"
#!/bin/bash
# Restore $APP_NAME desktop entry at startup
bash "${APP_CONFIG_DIR}/restore_desktop_entry.sh" &
EOF
fi

chmod +x "$CUSTOM_SCRIPT"

echo "$APP_NAME desktop entry creation complete."