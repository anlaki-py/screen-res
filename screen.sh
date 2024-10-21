#!/bin/bash

# File to store presets
PRESET_FILE="$HOME/screen_presets.txt"
DEFAULT_WIDTH=1080
DEFAULT_HEIGHT=2400
DEFAULT_DENSITY=440
SCREEN_DIAGONAL=6.43 # in inches (Redmi Note 10s)

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create preset file if it doesn't exist
if [[ ! -f $PRESET_FILE ]]; then
    touch $PRESET_FILE
fi

# Function to display current resolution and density
show_current_settings() {
    wm_size=$(wm size)
    wm_density=$(wm density)
    dialog --msgbox "Current Screen Resolution: ${wm_size}\nCurrent Screen Density: ${wm_density}" 10 50
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

# Function to change resolution
set_resolution() {
    WIDTH=$1
    HEIGHT=$2
    DENSITY=$3

    echo -e "${GREEN}Changing resolution to ${WIDTH}x${HEIGHT} and DPI to $DENSITY...${NC}"
    wm size ${WIDTH}x${HEIGHT}
    wm density $DENSITY
    dialog --msgbox "Resolution changed to ${WIDTH}x${HEIGHT} and DPI to ${DENSITY}" 6 50
}

# Function to revert to default resolution and density
revert_resolution() {
    echo -e "${RED}Reverting to default resolution and DPI...${NC}"
    wm size ${DEFAULT_WIDTH}x${DEFAULT_HEIGHT}
    wm density ${DEFAULT_DENSITY}
    dialog --msgbox "Resolution reverted to ${DEFAULT_WIDTH}x${DEFAULT_HEIGHT} and DPI to ${DEFAULT_DENSITY}" 6 50
}

# Function to add a new custom preset
add_preset() {
    WIDTH=$(dialog --inputbox "Enter screen width (e.g., 1080):" 8 40 3>&1 1>&2 2>&3 3>&-)
    HEIGHT=$(dialog --inputbox "Enter screen height (e.g., 2400):" 8 40 3>&1 1>&2 2>&3 3>&-)
    
    if [[ $WIDTH =~ ^[0-9]+$ && $HEIGHT =~ ^[0-9]+$ ]]; then
        DENSITY=$(calculate_dpi $WIDTH $HEIGHT)
        PRESET_NAME=$(dialog --inputbox "Enter a name for this preset:" 8 40 3>&1 1>&2 2>&3 3>&-)
        echo "${PRESET_NAME},${WIDTH},${HEIGHT},${DENSITY}" >> "$PRESET_FILE"
        dialog --msgbox "Preset '${PRESET_NAME}' saved with DPI: ${DENSITY}!" 6 50
    else
        dialog --msgbox "Error: Invalid input! Please enter numeric values." 6 50
    fi
}

# Function to choose and apply a preset
apply_preset() {
    PRESETS=$(cat "$PRESET_FILE" | awk -F, '{print NR " " $1}' | tr '\n' ' ')
    
    if [[ -z "$PRESETS" ]]; then
        dialog --msgbox "No presets found! Please add some." 6 50
        return
    fi

    CHOICE=$(dialog --menu "Select a preset to apply:" 15 50 10 $PRESETS 3>&1 1>&2 2>&3)
    
    if [[ $? -eq 0 ]]; then
        SELECTED_PRESET=$(sed -n "${CHOICE}p" "$PRESET_FILE")
        NAME=$(echo "$SELECTED_PRESET" | cut -d, -f1)
        WIDTH=$(echo "$SELECTED_PRESET" | cut -d, -f2)
        HEIGHT=$(echo "$SELECTED_PRESET" | cut -d, -f3)
        DENSITY=$(echo "$SELECTED_PRESET" | cut -d, -f4)

        dialog --msgbox "Applying preset: ${NAME}\nResolution: ${WIDTH}x${HEIGHT}\nDensity: ${DENSITY}" 8 50
        set_resolution $WIDTH $HEIGHT $DENSITY
    fi
}

# Function to delete a preset
delete_preset() {
    PRESETS=$(cat "$PRESET_FILE" | awk -F, '{print NR " " $1}' | tr '\n' ' ')
    
    if [[ -z "$PRESETS" ]]; then
        dialog --msgbox "No presets found! Please add some." 6 50
        return
    fi

    CHOICE=$(dialog --menu "Select a preset to delete:" 15 50 10 $PRESETS 3>&1 1>&2 2>&3)
    
    if [[ $? -eq 0 ]]; then
        sed -i "${CHOICE}d" "$PRESET_FILE"
        dialog --msgbox "Preset deleted successfully!" 6 50
    fi
}

# Function to backup current settings
backup_settings() {
    CURRENT_SIZE=$(wm size | cut -d: -f2 | tr -d ' ')
    CURRENT_DENSITY=$(wm density | cut -d: -f2 | tr -d ' ')
    
    echo "${CURRENT_SIZE},${CURRENT_DENSITY}" > "$HOME/screen_backup.txt"
    dialog --msgbox "Backup created for current settings." 6 50
}

# Function to restore from backup
restore_backup() {
    if [[ -f "$HOME/screen_backup.txt" ]]; then
        BACKUP=$(cat "$HOME/screen_backup.txt")
        WIDTH=$(echo "$BACKUP" | cut -d, -f1 | cut -d'x' -f1)
        HEIGHT=$(echo "$BACKUP" | cut -d, -f1 | cut -d'x' -f2)
        DENSITY=$(echo "$BACKUP" | cut -d, -f2)
        
        set_resolution $WIDTH $HEIGHT $DENSITY
        dialog --msgbox "Backup restored: ${WIDTH}x${HEIGHT}, ${DENSITY} DPI" 6 50
    else
        dialog --msgbox "No backup found!" 6 50
    fi
}

# Main menu UI
main_menu() {
    while true; do
        CHOICE=$(dialog --clear --backtitle "Android Screen Resolution Manager by Anlaki." \
                        --title "Main Menu" \
                        --menu "Choose an option:" 15 50 8 \
                        1 "Show Current Resolution and Density" \
                        2 "Set Custom Resolution" \
                        3 "Choose Preset Resolution" \
                        4 "Add a New Preset" \
                        5 "Delete a Preset" \
                        6 "Revert to Default Resolution" \
                        7 "Backup Current Settings" \
                        8 "Restore Backup" \
                        9 "Exit" 3>&1 1>&2 2>&3)

        case $CHOICE in
            1) show_current_settings ;;
            2) custom_resolution_input ;;
            3) apply_preset ;;
            4) add_preset ;;
            5) delete_preset ;;
            6) revert_resolution ;;
            7) backup_settings ;;
            8) restore_backup ;;
            9) clear && exit 0 ;;
        esac
    done
}

# Start the script
main_menu

""" © anlaki - 2024 """
