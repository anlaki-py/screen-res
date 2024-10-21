#!/bin/bash

# Configuration file paths
CONFIG_DIR="$HOME/.config/android-screen-manager"
CONFIG_FILE="$CONFIG_DIR/config.conf"
PRESET_FILE="$CONFIG_DIR/screen_presets.txt"
BACKUP_FILE="$CONFIG_DIR/screen_backup.txt"

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create configuration directory and files if they don't exist
create_config_files() {
    mkdir -p "$CONFIG_DIR"
    if [[ ! -f $CONFIG_FILE ]]; then
        echo "# Device Configuration" > "$CONFIG_FILE"
        echo "DEFAULT_WIDTH=1080" >> "$CONFIG_FILE"
        echo "DEFAULT_HEIGHT=2400" >> "$CONFIG_FILE"
        echo "DEFAULT_DENSITY=440" >> "$CONFIG_FILE"
        echo "SCREEN_DIAGONAL=6.1" >> "$CONFIG_FILE"
        echo "DEVICE_NAME=Generic Android Device" >> "$CONFIG_FILE"
    fi
    touch "$PRESET_FILE"
}

# Load configuration
load_config() {
    if [[ -f $CONFIG_FILE ]]; then
        source "$CONFIG_FILE"
    else
        create_config_files
        source "$CONFIG_FILE"
    fi
}

# Initial setup wizard
setup_wizard() {
    dialog --title "First Time Setup" --msgbox "Welcome to Android Screen Resolution Manager!\nLet's configure your device settings." 8 50

    DEVICE_NAME=$(dialog --inputbox "Enter your device name:" 8 40 "Generic Android Device" 3>&1 1>&2 2>&3 3>&-)
    SCREEN_DIAGONAL=$(dialog --inputbox "Enter your screen diagonal size (in inches):" 8 40 "6.1" 3>&1 1>&2 2>&3 3>&-)
    
    # Get current resolution and density as defaults
    CURRENT_SIZE=$(wm size | cut -d: -f2 | tr -d ' ')
    CURRENT_DENSITY=$(wm density | cut -d: -f2 | tr -d ' ')
    
    DEFAULT_WIDTH=$(echo $CURRENT_SIZE | cut -d'x' -f1)
    DEFAULT_HEIGHT=$(echo $CURRENT_SIZE | cut -d'x' -f2)
    DEFAULT_DENSITY=$CURRENT_DENSITY

    # Save configuration
    cat > "$CONFIG_FILE" << EOF
# Device Configuration
DEVICE_NAME="$DEVICE_NAME"
SCREEN_DIAGONAL=$SCREEN_DIAGONAL
DEFAULT_WIDTH=$DEFAULT_WIDTH
DEFAULT_HEIGHT=$DEFAULT_HEIGHT
DEFAULT_DENSITY=$DEFAULT_DENSITY
EOF

    dialog --title "Setup Complete" --msgbox "Device configuration saved successfully!" 6 50
}

# Function to display current resolution and density
show_current_settings() {
    wm_size=$(wm size)
    wm_density=$(wm density)
    dialog --title "Current Settings" --msgbox "Device: $DEVICE_NAME\nScreen Size: $SCREEN_DIAGONAL inches\n\nCurrent Screen Resolution: ${wm_size}\nCurrent Screen Density: ${wm_density}" 12 60
}

# Function to calculate DPI based on screen resolution
calculate_dpi() {
    WIDTH=$1
    HEIGHT=$2
    DIAGONAL=$SCREEN_DIAGONAL
    # Calculate DPI using the Pythagorean theorem
    DPI=$(awk "BEGIN {print int(sqrt($WIDTH * $WIDTH + $HEIGHT * $HEIGHT) / $DIAGONAL)}")
    echo $DPI
}

# Function to verify ADB connection
check_adb() {
    if ! command -v wm &> /dev/null; then
        dialog --title "Error" --msgbox "This script must be run through ADB shell on an Android device." 6 50
        exit 1
    fi
}

# Function to change resolution
set_resolution() {
    WIDTH=$1
    HEIGHT=$2
    DENSITY=$3

    # Verify the values are within reasonable ranges
    if [ $WIDTH -lt 320 ] || [ $WIDTH -gt 4096 ] || [ $HEIGHT -lt 320 ] || [ $HEIGHT -gt 4096 ]; then
        dialog --title "Warning" --yesno "The resolution ${WIDTH}x${HEIGHT} seems unusual. Are you sure you want to proceed?" 6 60
        if [ $? -ne 0 ]; then
            return
        fi
    fi

    echo -e "${GREEN}Changing resolution to ${WIDTH}x${HEIGHT} and DPI to $DENSITY...${NC}"
    wm size ${WIDTH}x${HEIGHT}
    wm density $DENSITY
    
    # Verify the change was successful
    CURRENT_SIZE=$(wm size | grep -oE "[0-9]+x[0-9]+")
    if [ "${WIDTH}x${HEIGHT}" = "$CURRENT_SIZE" ]; then
        dialog --msgbox "Resolution changed successfully to ${WIDTH}x${HEIGHT} and DPI to ${DENSITY}" 6 50
    else
        dialog --msgbox "Warning: Resolution change may have failed. Please verify the settings." 6 50
    fi
}

# Function to add a new custom preset
add_preset() {
    WIDTH=$(dialog --inputbox "Enter screen width (e.g., 1080):" 8 40 3>&1 1>&2 2>&3 3>&-)
    HEIGHT=$(dialog --inputbox "Enter screen height (e.g., 2400):" 8 40 3>&1 1>&2 2>&3 3>&-)
    
    if [[ $WIDTH =~ ^[0-9]+$ && $HEIGHT =~ ^[0-9]+$ ]]; then
        DENSITY=$(calculate_dpi $WIDTH $HEIGHT)
        PRESET_NAME=$(dialog --inputbox "Enter a name for this preset:" 8 40 3>&1 1>&2 2>&3 3>&-)
        if [[ -n "$PRESET_NAME" ]]; then
            echo "${PRESET_NAME},${WIDTH},${HEIGHT},${DENSITY}" >> "$PRESET_FILE"
            dialog --msgbox "Preset '${PRESET_NAME}' saved with DPI: ${DENSITY}!" 6 50
        else
            dialog --msgbox "Error: Preset name cannot be empty!" 6 50
        fi
    else
        dialog --msgbox "Error: Invalid input! Please enter numeric values." 6 50
    fi
}

# Function to apply a preset
apply_preset() {
    if [[ ! -s "$PRESET_FILE" ]]; then
        dialog --msgbox "No presets found! Please add some presets first." 6 50
        return
    fi

    # Create a temporary file for the menu options
    TEMP_MENU=$(mktemp)
    
    # Generate menu options from presets
    while IFS=',' read -r name width height density; do
        echo "$name" >> "$TEMP_MENU"
        echo "$name ($width x $height, ${density}dpi)" >> "$TEMP_MENU"
    done < "$PRESET_FILE"

    # Create the menu dialog
    PRESET_NAME=$(dialog --menu "Select a preset to apply:" 15 60 8 --file "$TEMP_MENU" 3>&1 1>&2 2>&3)
    
    # Remove temporary file
    rm "$TEMP_MENU"

    if [[ -n "$PRESET_NAME" ]]; then
        # Find and apply the selected preset
        while IFS=',' read -r name width height density; do
            if [[ "$name" == "$PRESET_NAME" ]]; then
                dialog --title "Confirm" --yesno "Apply preset '$name'?\n\nResolution: ${width}x${height}\nDensity: $density" 8 50
                if [[ $? -eq 0 ]]; then
                    set_resolution "$width" "$height" "$density"
                fi
                break
            fi
        done < "$PRESET_FILE"
    fi
}

# Function to delete a preset
delete_preset() {
    if [[ ! -s "$PRESET_FILE" ]]; then
        dialog --msgbox "No presets found! Please add some presets first." 6 50
        return
    fi

    # Create a temporary file for the menu options
    TEMP_MENU=$(mktemp)
    
    # Generate menu options from presets
    while IFS=',' read -r name width height density; do
        echo "$name" >> "$TEMP_MENU"
        echo "$name ($width x $height, ${density}dpi)" >> "$TEMP_MENU"
    done < "$PRESET_FILE"

    # Create the menu dialog
    PRESET_NAME=$(dialog --menu "Select a preset to delete:" 15 60 8 --file "$TEMP_MENU" 3>&1 1>&2 2>&3)
    
    # Remove temporary file
    rm "$TEMP_MENU"

    if [[ -n "$PRESET_NAME" ]]; then
        dialog --title "Confirm Delete" --yesno "Are you sure you want to delete preset '$PRESET_NAME'?" 6 50
        if [[ $? -eq 0 ]]; then
            # Create a temporary file and remove the selected preset
            TEMP_FILE=$(mktemp)
            grep -v "^$PRESET_NAME," "$PRESET_FILE" > "$TEMP_FILE"
            mv "$TEMP_FILE" "$PRESET_FILE"
            dialog --msgbox "Preset '$PRESET_NAME' deleted successfully!" 6 50
        fi
    fi
}

# Function to backup current settings
backup_settings() {
    CURRENT_SIZE=$(wm size | cut -d: -f2 | tr -d ' ')
    CURRENT_DENSITY=$(wm density | cut -d: -f2 | tr -d ' ')
    
    echo "${CURRENT_SIZE},${CURRENT_DENSITY}" > "$BACKUP_FILE"
    dialog --msgbox "Current settings backed up successfully!" 6 50
}

# Function to restore backup
restore_backup() {
    if [[ -f "$BACKUP_FILE" ]]; then
        BACKUP=$(cat "$BACKUP_FILE")
        SIZE=$(echo "$BACKUP" | cut -d',' -f1)
        WIDTH=$(echo "$SIZE" | cut -d'x' -f1)
        HEIGHT=$(echo "$SIZE" | cut -d'x' -f2)
        DENSITY=$(echo "$BACKUP" | cut -d',' -f2)
        
        dialog --title "Confirm Restore" --yesno "Restore these settings?\n\nResolution: ${WIDTH}x${HEIGHT}\nDensity: $DENSITY" 8 50
        if [[ $? -eq 0 ]]; then
            set_resolution "$WIDTH" "$HEIGHT" "$DENSITY"
        fi
    else
        dialog --msgbox "No backup found!" 6 50
    fi
}

# Function for custom resolution input
custom_resolution_input() {
    WIDTH=$(dialog --inputbox "Enter desired width (e.g., 1080):" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [[ ! $WIDTH =~ ^[0-9]+$ ]]; then
        dialog --msgbox "Error: Invalid width! Please enter a numeric value." 6 50
        return
    fi

    HEIGHT=$(dialog --inputbox "Enter desired height (e.g., 2400):" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [[ ! $HEIGHT =~ ^[0-9]+$ ]]; then
        dialog --msgbox "Error: Invalid height! Please enter a numeric value." 6 50
        return
    fi

    DENSITY=$(calculate_dpi $WIDTH $HEIGHT)
    
    dialog --title "Confirm Resolution" --yesno "Apply these settings?\n\nResolution: ${WIDTH}x${HEIGHT}\nCalculated DPI: $DENSITY" 8 50
    if [[ $? -eq 0 ]]; then
        set_resolution "$WIDTH" "$HEIGHT" "$DENSITY"
    fi
}

# Function to revert to default resolution and density
revert_resolution() {
    dialog --title "Confirm Revert" --yesno "Are you sure you want to revert to default settings?\n\nDefault Resolution: ${DEFAULT_WIDTH}x${DEFAULT_HEIGHT}\nDefault DPI: ${DEFAULT_DENSITY}" 8 60
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}Reverting to default resolution and DPI...${NC}"
        wm size ${DEFAULT_WIDTH}x${DEFAULT_HEIGHT}
        wm density ${DEFAULT_DENSITY}
        dialog --msgbox "Settings reverted to defaults successfully!" 6 50
    fi
}

# Main menu UI
main_menu() {
    while true; do
        CHOICE=$(dialog --clear --backtitle "Universal Android Screen Resolution Manager" \
                        --title "Main Menu - $DEVICE_NAME" \
                        --menu "Choose an option:" 16 60 10 \
                        1 "Show Current Resolution and Density" \
                        2 "Set Custom Resolution" \
                        3 "Choose Preset Resolution" \
                        4 "Add a New Preset" \
                        5 "Delete a Preset" \
                        6 "Revert to Default Resolution" \
                        7 "Backup Current Settings" \
                        8 "Restore Backup" \
                        9 "Reconfigure Device Settings" \
                        10 "Exit" 3>&1 1>&2 2>&3)

        case $CHOICE in
            1) show_current_settings ;;
            2) custom_resolution_input ;;
            3) apply_preset ;;
            4) add_preset ;;
            5) delete_preset ;;
            6) revert_resolution ;;
            7) backup_settings ;;
            8) restore_backup ;;
            9) setup_wizard ;;
            10) clear && exit 0 ;;
        esac
    done
}

# Check if running in ADB shell
check_adb

# Load or create configuration
load_config

# Run setup wizard if first time
if [ ! -f "$CONFIG_FILE" ]; then
    setup_wizard
fi

# Start the script
main_menu

""" © anlaki - 2024 """
