#!/bin/bash

# Function to display error messages and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Variables
REPO_URL="https://github.com/soaibsafi/jatiyo-macos.git"
KEYBOARD_LAYOUTS_DIR="/Library/Keyboard Layouts"
TMP_DIR=$(mktemp -d)

# Check if the temporary directory was created successfully
if [[ ! -d "$TMP_DIR" ]]; then
    error_exit "Failed to create a temporary directory."
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    error_exit "git is not installed. Please install git and try again."
fi

# Clone the repository
echo "Cloning jatiyo-macos repository..."
if ! git clone "$REPO_URL" "$TMP_DIR" &> /dev/null; then
    rm -rf "$TMP_DIR"
    error_exit "Failed to clone the repository. Please check your internet connection and try again."
fi

# Copy the keylayout and icon files to the Keyboard Layouts directory
echo "Installing Bengali keyboard layout..."
if ! sudo cp "$TMP_DIR/jatiyo.keylayout" "$KEYBOARD_LAYOUTS_DIR/"; then
    rm -rf "$TMP_DIR"
    error_exit "Failed to copy jatiyo.keylayout to $KEYBOARD_LAYOUTS_DIR. Please check permissions."
fi

if ! sudo cp "$TMP_DIR/jatiyo.icns" "$KEYBOARD_LAYOUTS_DIR/"; then
    rm -rf "$TMP_DIR"
    error_exit "Failed to copy jatiyo.icns to $KEYBOARD_LAYOUTS_DIR. Please check permissions."
fi

# Clean up temporary files
rm -rf "$TMP_DIR"

# Success message
echo "Installation complete!"
echo "Please follow these steps to enable the Bengali keyboard layout:"
echo "1. Open System Preferences -> Keyboard -> Input Sources."
echo "2. Click the '+' button at the bottom left corner."
echo "3. Select 'Other' from the list and choose 'বাংলা-জাতীয়'."
echo "4. (Optional) Set a keyboard shortcut from the 'Shortcut' tab."

exit 0