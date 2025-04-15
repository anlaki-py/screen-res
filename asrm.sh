#!/bin/bash

# --- DISCLAIMER ---
#
# This script is provided "AS IS" without warranty of any kind, either express or implied,
# including, but not limited to, the implied warranties of merchantability and fitness
# for a particular purpose. The entire risk as to the quality and performance of the script
# is with you.
#
# The author provides this script for utility purposes only and assumes no responsibility
# for any errors or omissions, or for damages resulting from the use of this script.
#
# Modifying screen resolution and density settings using tools like 'wm' can potentially
# lead to unexpected behavior, display issues, make the device unusable (requiring a reset
# or ADB intervention), or in rare cases, cause conflicts with the system or other applications.
# There is also a possibility, although unlikely, that using such tools could be detected
# by manufacturers and potentially affect your device's warranty status.
#
# By using this script, you acknowledge that you understand the potential risks involved
# and agree that the author shall not be held liable for any direct, indirect, consequential,
# incidental, or special damages arising out of the use or inability to use the script,
# including but not limited to loss of data, device malfunction, or other losses, even if
# the author has been advised of the possibility of such damages.
#
# Use this script at your own risk. It is recommended to back up your important data
# before making system modifications.
#
# --- END DISCLAIMER ---

# 1. This script is 99% AI generated using the model gemini-2.5-pro, Claude 3.5 Sonnet, gemini-1.5-pro
# 2. This script is tested and should work on any android device with ROOT
# 3. Needs Termux with the following packages: dialog, tsu

#    pkg update && pkg install -y dialog tsu

# How to run: sudo bash script.sh

# Configuration directory: /data/data/com.termux/files/home/.suroot/.config/android-screen-manager/

CONFIG_DIR="$HOME/.config/android-screen-manager"
CONFIG_FILE="$CONFIG_DIR/config.conf"
PRESET_FILE="$CONFIG_DIR/screen_presets.txt"
BACKUP_FILE="$CONFIG_DIR/screen_backup.txt"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_essentials() {
    local missing_pkg=""
    if ! command -v wm &> /dev/null; then
        echo "Error: 'wm' command not found. This script must be run through ADB shell on an Android device." >&2
        exit 1
    fi
    if ! command -v dialog &> /dev/null; then
        missing_pkg="dialog"
    fi
    if ! command -v awk &> /dev/null; then
        missing_pkg="${missing_pkg} awk"
    fi

    if [[ -n "$missing_pkg" ]]; then
       echo "Error: Required command(s) not found: ${missing_pkg}." >&2
       echo "Please install them (e.g., 'pkg update && pkg install ${missing_pkg}' in Termux)." >&2
       exit 1
    fi
}

get_physical_defaults() {
    local physical_size_line=$(wm size 2>/dev/null | grep 'Physical size:')
    local physical_density_line=$(wm density 2>/dev/null | grep 'Physical density:')

    PHYSICAL_WIDTH=$(echo "$physical_size_line" | cut -d: -f2 | cut -dx -f1 | tr -d ' ')
    PHYSICAL_HEIGHT=$(echo "$physical_size_line" | cut -d: -f2 | cut -dx -f2 | tr -d ' ')
    PHYSICAL_DENSITY=$(echo "$physical_density_line" | cut -d: -f2 | tr -d ' ')

    if [[ ! "$PHYSICAL_WIDTH" =~ ^[0-9]+$ || ! "$PHYSICAL_HEIGHT" =~ ^[0-9]+$ || ! "$PHYSICAL_DENSITY" =~ ^[0-9]+$ ]]; then
         dialog --title "Warning" --msgbox "Could not reliably determine physical screen settings.\nAttempting to use current settings as fallback defaults." 8 70
         local current_size_line=$(wm size 2>/dev/null | grep -oE '[0-9]+x[0-9]+' | head -n 1)
         local current_density_line=$(wm density 2>/dev/null | grep -oE '[0-9]+' | head -n 1)
         PHYSICAL_WIDTH=$(echo "$current_size_line" | cut -dx -f1)
         PHYSICAL_HEIGHT=$(echo "$current_size_line" | cut -dx -f2)
         PHYSICAL_DENSITY=$current_density_line

         if [[ ! "$PHYSICAL_WIDTH" =~ ^[0-9]+$ || ! "$PHYSICAL_HEIGHT" =~ ^[0-9]+$ || ! "$PHYSICAL_DENSITY" =~ ^[0-9]+$ ]]; then
            dialog --title "Fatal Error" --msgbox "Failed to determine screen dimensions. Exiting." 6 50
            exit 1
         fi
    fi
}


create_config_files() {
    mkdir -p "$CONFIG_DIR"
    if [[ ! -f $CONFIG_FILE ]]; then
        echo -e "${YELLOW}Configuration file not found. Creating one...${NC}"
        get_physical_defaults

        if [[ ! "$PHYSICAL_WIDTH" =~ ^[0-9]+$ || ! "$PHYSICAL_HEIGHT" =~ ^[0-9]+$ || ! "$PHYSICAL_DENSITY" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Fatal Error: Could not determine physical screen properties to create default config. Exiting.${NC}" >&2
            exit 1
        fi

        echo "# Device Configuration" > "$CONFIG_FILE"
        echo "DEFAULT_WIDTH=$PHYSICAL_WIDTH" >> "$CONFIG_FILE"
        echo "DEFAULT_HEIGHT=$PHYSICAL_HEIGHT" >> "$CONFIG_FILE"
        echo "DEFAULT_DENSITY=$PHYSICAL_DENSITY" >> "$CONFIG_FILE"
        echo "SCREEN_DIAGONAL=6.1" >> "$CONFIG_FILE"
        echo "DEVICE_NAME=Generic Android Device" >> "$CONFIG_FILE"
        echo -e "${GREEN}Default configuration created using physical screen settings.${NC}"
    fi
    touch "$PRESET_FILE"
}

load_config() {
    create_config_files

    if [[ -f $CONFIG_FILE ]]; then
        source "$CONFIG_FILE"
        if [[ ! "$DEFAULT_WIDTH" =~ ^[0-9]+$ || ! "$DEFAULT_HEIGHT" =~ ^[0-9]+$ || ! "$DEFAULT_DENSITY" =~ ^[0-9]+$ ]]; then
            dialog --title "Config Error" --msgbox "Configuration file contains invalid numeric values.\nPlease reconfigure using option 9 or fix '$CONFIG_FILE'." 8 60
        fi
    else
         dialog --title "Fatal Error" --msgbox "Could not load or create configuration file. Exiting." 6 50
         exit 1
    fi
}

setup_wizard() {
    dialog --title "Setup / Reconfigure" --msgbox "Let's configure your device settings.\nWe'll fetch the physical defaults as suggestions." 8 60

    get_physical_defaults

    local temp_device_name=$(dialog --inputbox "Enter your device name:" 8 40 "${DEVICE_NAME:-Generic Android Device}" 3>&1 1>&2 2>&3 3>&-)
    local temp_screen_diagonal=$(dialog --inputbox "Enter your screen diagonal size (in inches):" 8 40 "${SCREEN_DIAGONAL:-6.1}" 3>&1 1>&2 2>&3 3>&-)

    local temp_default_width=$(dialog --inputbox "Confirm default width (physical: $PHYSICAL_WIDTH):" 8 50 "$PHYSICAL_WIDTH" 3>&1 1>&2 2>&3 3>&-)
    local temp_default_height=$(dialog --inputbox "Confirm default height (physical: $PHYSICAL_HEIGHT):" 8 50 "$PHYSICAL_HEIGHT" 3>&1 1>&2 2>&3 3>&-)
    local temp_default_density=$(dialog --inputbox "Confirm default density (physical: $PHYSICAL_DENSITY):" 8 50 "$PHYSICAL_DENSITY" 3>&1 1>&2 2>&3 3>&-)

    if [[ ! "$temp_default_width" =~ ^[0-9]+$ || ! "$temp_default_height" =~ ^[0-9]+$ || ! "$temp_default_density" =~ ^[0-9]+$ ]]; then
        dialog --title "Input Error" --msgbox "Invalid numeric value entered for resolution or density. Configuration not saved." 8 60
        return
    fi

    cat > "$CONFIG_FILE" << EOF
# Device Configuration
DEVICE_NAME="$temp_device_name"
SCREEN_DIAGONAL=$temp_screen_diagonal
DEFAULT_WIDTH=$temp_default_width
DEFAULT_HEIGHT=$temp_default_height
DEFAULT_DENSITY=$temp_default_density
EOF
    load_config

    dialog --title "Setup Complete" --msgbox "Device configuration saved successfully!" 6 50
}


show_current_settings() {
    local wm_size_override=$(wm size | grep 'Override size:' | cut -d: -f2 | tr -d ' ')
    local wm_density_override=$(wm density | grep 'Override density:' | cut -d: -f2 | tr -d ' ')
    local wm_size_physical=$(wm size | grep 'Physical size:' | cut -d: -f2 | tr -d ' ')
    local wm_density_physical=$(wm density | grep 'Physical density:' | cut -d: -f2 | tr -d ' ')

     if [[ -z "$wm_size_override" ]]; then
         wm_size_override="N/A (Using Physical: $wm_size_physical)"
     fi
      if [[ -z "$wm_density_override" ]]; then
         wm_density_override="N/A (Using Physical: $wm_density_physical)"
     fi


    dialog --title "Current Settings" --msgbox "Device: $DEVICE_NAME\nScreen Diagonal: $SCREEN_DIAGONAL inches\n\nPhysical Resolution: $wm_size_physical\nPhysical Density: $wm_density_physical\n\nCurrent Override Resolution: $wm_size_override\nCurrent Override Density: $wm_density_override" 14 70
}

calculate_dpi() {
    local WIDTH=$1
    local HEIGHT=$2
    local DIAGONAL=${SCREEN_DIAGONAL:-6.1}

    if [[ ! "$DIAGONAL" =~ ^[0-9]+(\.[0-9]+)?$ || $(echo "$DIAGONAL <= 0" | bc -l) -eq 1 ]]; then
        dialog --title "Warning" --msgbox "Invalid or zero screen diagonal ($DIAGONAL) in config.\nCannot calculate DPI accurately. Using default density." 8 60
        echo "${DEFAULT_DENSITY:-440}"
        return
    fi

    local DPI=$(awk -v W="$WIDTH" -v H="$HEIGHT" -v D="$DIAGONAL" 'BEGIN { printf "%d", sqrt(W*W + H*H) / D }')
    echo "$DPI"
}

set_resolution() {
    local NEW_WIDTH=$1
    local NEW_HEIGHT=$2
    local NEW_DENSITY=$3

    if [[ ! "$NEW_WIDTH" =~ ^[0-9]+$ || ! "$NEW_HEIGHT" =~ ^[0-9]+$ || ! "$NEW_DENSITY" =~ ^[0-9]+$ ]]; then
         dialog --title "Error" --msgbox "Invalid non-numeric input for resolution or density." 6 60
         return
    fi

    if [ "$NEW_WIDTH" -lt 320 ] || [ "$NEW_WIDTH" -gt 4096 ] || [ "$NEW_HEIGHT" -lt 320 ] || [ "$NEW_HEIGHT" -gt 4096 ] || [ "$NEW_DENSITY" -lt 80 ] || [ "$NEW_DENSITY" -gt 1000 ]; then
        dialog --title "Warning" --yesno "The resolution ${NEW_WIDTH}x${NEW_HEIGHT} or density ${NEW_DENSITY} seems unusual. Are you sure you want to proceed?" 7 60
        if [ $? -ne 0 ]; then
            return
        fi
    fi

    local CURRENT_SIZE_OVERRIDE=$(wm size | grep 'Override size:' | cut -d: -f2 | tr -d ' ')
    local CURRENT_DENSITY_OVERRIDE=$(wm density | grep 'Override density:' | cut -d: -f2 | tr -d ' ')
    local CURRENT_SIZE_PHYSICAL=$(wm size | grep 'Physical size:' | cut -d: -f2 | tr -d ' ')
    local CURRENT_DENSITY_PHYSICAL=$(wm density | grep 'Physical density:' | cut -d: -f2 | tr -d ' ')

    local SIZE_BEFORE=$CURRENT_SIZE_OVERRIDE
    local DENSITY_BEFORE=$CURRENT_DENSITY_OVERRIDE

    if [[ -z "$SIZE_BEFORE" ]]; then
       SIZE_BEFORE=$CURRENT_SIZE_PHYSICAL
    fi
     if [[ -z "$DENSITY_BEFORE" ]]; then
       DENSITY_BEFORE=$CURRENT_DENSITY_PHYSICAL
    fi

    echo -e "${GREEN}Changing resolution to ${NEW_WIDTH}x${NEW_HEIGHT} and density to ${NEW_DENSITY}...${NC}"
    wm size "${NEW_WIDTH}x${NEW_HEIGHT}"
    wm density "$NEW_DENSITY"
    sleep 2

    echo -e "${YELLOW}Resolution changed. Press ENTER within 15 seconds to confirm, or wait to revert automatically.${NC}"
    echo -e "${YELLOW}Starting countdown...${NC}"

    for i in $(seq 15 -1 1); do
        echo -ne "${YELLOW}$i... ${NC}\r"
        if read -t 0.1 -r </dev/tty; then
            if [[ -z "$REPLY" ]]; then
                echo -e "\n${GREEN}Confirmed! Keeping new settings.${NC}"
                local VERIFY_SIZE=$(wm size | grep 'Override size:' | cut -d: -f2 | tr -d ' ')
                local VERIFY_DENSITY=$(wm density | grep 'Override density:' | cut -d: -f2 | tr -d ' ')
                if [ "${NEW_WIDTH}x${NEW_HEIGHT}" != "$VERIFY_SIZE" ] || [ "$NEW_DENSITY" != "$VERIFY_DENSITY" ]; then
                     dialog --title "Warning" --msgbox "Settings confirmed, but verification shows:\nRequested: ${NEW_WIDTH}x${NEW_HEIGHT} @ ${NEW_DENSITY}dpi\nCurrent: $VERIFY_SIZE @ ${VERIFY_DENSITY}dpi\nPlease check visually." 10 70
                else
                     dialog --title "Success" --msgbox "Resolution set to ${NEW_WIDTH}x${NEW_HEIGHT} and Density to ${NEW_DENSITY} and confirmed." 7 60
                fi
                return 0
            else
                 echo -ne "\n${YELLOW}Ignoring input '$REPLY'. Press only ENTER to confirm.${NC}\n"
            fi
        fi
        sleep 0.9
    done

    echo -e "\n${RED}Timeout! No confirmation received. Reverting to previous settings...${NC}"
    if [[ "$SIZE_BEFORE" == "$CURRENT_SIZE_PHYSICAL" && "$DENSITY_BEFORE" == "$CURRENT_DENSITY_PHYSICAL" ]]; then
        wm size reset
        wm density reset
        echo -e "${YELLOW}Reverted to physical defaults.${NC}"
        dialog --title "Reverted" --msgbox "Timeout reached. Settings reverted to physical defaults." 6 60
    elif [[ "$SIZE_BEFORE" =~ ^[0-9]+x[0-9]+$ && "$DENSITY_BEFORE" =~ ^[0-9]+$ ]]; then
        wm size "$SIZE_BEFORE"
        wm density "$DENSITY_BEFORE"
        echo -e "${YELLOW}Reverted to previous override: ${SIZE_BEFORE} @ ${DENSITY_BEFORE}dpi.${NC}"
        dialog --title "Reverted" --msgbox "Timeout reached. Settings reverted to previous override:\n${SIZE_BEFORE} @ ${DENSITY_BEFORE}dpi" 7 60
    else
        wm size reset
        wm density reset
        echo -e "${RED}Warning: Could not determine exact previous state. Attempting reset to physical defaults.${NC}"
        dialog --title "Reverted (Fallback)" --msgbox "Timeout reached. Could not determine previous state. Attempted revert to physical defaults." 7 70
    fi
    sleep 1
    return 1
}

add_preset() {
    local WIDTH=$(dialog --inputbox "Enter screen width (e.g., 1080):" 8 40 3>&1 1>&2 2>&3 3>&-)
    [[ $? -ne 0 ]] && return

    local HEIGHT=$(dialog --inputbox "Enter screen height (e.g., 2400):" 8 40 3>&1 1>&2 2>&3 3>&-)
     [[ $? -ne 0 ]] && return

    if [[ "$WIDTH" =~ ^[0-9]+$ && "$HEIGHT" =~ ^[0-9]+$ ]]; then
        local DENSITY=$(calculate_dpi "$WIDTH" "$HEIGHT")
        local PRESET_NAME=$(dialog --inputbox "Enter a name for this preset:" 8 40 3>&1 1>&2 2>&3 3>&-)
         [[ $? -ne 0 || -z "$PRESET_NAME" ]] && { dialog --msgbox "Preset not saved (no name entered or cancelled)." 6 50; return; }

        if grep -q "^${PRESET_NAME}," "$PRESET_FILE"; then
            dialog --title "Error" --msgbox "Preset name '$PRESET_NAME' already exists!" 6 50
        else
            echo "${PRESET_NAME},${WIDTH},${HEIGHT},${DENSITY}" >> "$PRESET_FILE"
            dialog --msgbox "Preset '${PRESET_NAME}' saved!\nResolution: ${WIDTH}x${HEIGHT}\nCalculated DPI: ${DENSITY}" 8 50
        fi
    else
        dialog --msgbox "Error: Invalid input! Please enter numeric values for width and height." 6 50
    fi
}

apply_preset() {
    if [[ ! -s "$PRESET_FILE" ]]; then
        dialog --msgbox "No presets found! Please add some presets first." 6 50
        return
    fi

    local options=()
    while IFS=',' read -r name width height density; do
        if [[ -n "$name" && -n "$width" && -n "$height" && -n "$density" ]]; then
             options+=("$name" "($width x $height, ${density}dpi)")
        fi
    done < "$PRESET_FILE"

    if [ ${#options[@]} -eq 0 ]; then
         dialog --msgbox "No valid presets found in file." 6 50
         return
    fi

    local PRESET_NAME=$(dialog --menu "Select a preset to apply:" 18 70 10 "${options[@]}" 3>&1 1>&2 2>&3 3>&-)
    [[ $? -ne 0 || -z "$PRESET_NAME" ]] && return

    local found=false
    while IFS=',' read -r name width height density; do
        if [[ "$name" == "$PRESET_NAME" ]]; then
            found=true
            dialog --title "Confirm Preset" --yesno "Apply preset '$name'?\n\nResolution: ${width}x${height}\nDensity: $density" 8 50
            if [[ $? -eq 0 ]]; then
                set_resolution "$width" "$height" "$density"
            fi
            break
        fi
    done < "$PRESET_FILE"

    if ! $found; then
        dialog --msgbox "Error: Could not find selected preset '$PRESET_NAME' data." 6 50
    fi
}


delete_preset() {
    if [[ ! -s "$PRESET_FILE" ]]; then
        dialog --msgbox "No presets found!" 6 50
        return
    fi

    local options=()
     while IFS=',' read -r name width height density; do
        if [[ -n "$name" && -n "$width" && -n "$height" && -n "$density" ]]; then
             options+=("$name" "($width x $height, ${density}dpi)")
        fi
    done < "$PRESET_FILE"

     if [ ${#options[@]} -eq 0 ]; then
         dialog --msgbox "No valid presets found to delete." 6 50
         return
    fi

    local PRESET_NAME=$(dialog --menu "Select a preset to DELETE:" 18 70 10 "${options[@]}" 3>&1 1>&2 2>&3 3>&-)
     [[ $? -ne 0 || -z "$PRESET_NAME" ]] && return


    dialog --title "Confirm Delete" --yesno "Are you sure you want to delete preset '$PRESET_NAME'?" 6 50
    if [[ $? -eq 0 ]]; then
        grep -v "^${PRESET_NAME}," "$PRESET_FILE" > "${PRESET_FILE}.tmp" && mv "${PRESET_FILE}.tmp" "$PRESET_FILE"
        if [[ $? -eq 0 ]]; then
             dialog --msgbox "Preset '$PRESET_NAME' deleted successfully!" 6 50
        else
             dialog --msgbox "Error deleting preset '$PRESET_NAME'. Check file permissions." 6 60
             [[ -f "${PRESET_FILE}.tmp" ]] && rm "${PRESET_FILE}.tmp"
        fi
    fi
}


backup_settings() {
    local CURRENT_SIZE_OVERRIDE=$(wm size | grep 'Override size:' | cut -d: -f2 | tr -d ' ')
    local CURRENT_DENSITY_OVERRIDE=$(wm density | grep 'Override density:' | cut -d: -f2 | tr -d ' ')
    local CURRENT_SIZE_PHYSICAL=$(wm size | grep 'Physical size:' | cut -d: -f2 | tr -d ' ')
    local CURRENT_DENSITY_PHYSICAL=$(wm density | grep 'Physical density:' | cut -d: -f2 | tr -d ' ')

    local SIZE_TO_BACKUP=$CURRENT_SIZE_OVERRIDE
    local DENSITY_TO_BACKUP=$CURRENT_DENSITY_OVERRIDE

    if [[ -z "$SIZE_TO_BACKUP" ]]; then
       SIZE_TO_BACKUP=$CURRENT_SIZE_PHYSICAL
    fi
     if [[ -z "$DENSITY_TO_BACKUP" ]]; then
       DENSITY_TO_BACKUP=$CURRENT_DENSITY_PHYSICAL
    fi

    if [[ -z "$SIZE_TO_BACKUP" || -z "$DENSITY_TO_BACKUP" ]]; then
        dialog --msgbox "Error: Could not determine current settings to backup." 6 50
        return
    fi

    echo "${SIZE_TO_BACKUP},${DENSITY_TO_BACKUP}" > "$BACKUP_FILE"
    dialog --msgbox "Current settings backed up successfully!\nBacked up: ${SIZE_TO_BACKUP}, ${DENSITY_TO_BACKUP}" 7 60
}

restore_backup() {
    if [[ -f "$BACKUP_FILE" && -s "$BACKUP_FILE" ]]; then
        local BACKUP=$(cat "$BACKUP_FILE")
        local SIZE=$(echo "$BACKUP" | cut -d',' -f1)
        local DENSITY=$(echo "$BACKUP" | cut -d',' -f2)
        local WIDTH=$(echo "$SIZE" | cut -dx -f1)
        local HEIGHT=$(echo "$SIZE" | cut -dx -f2)

        if [[ ! "$WIDTH" =~ ^[0-9]+$ || ! "$HEIGHT" =~ ^[0-9]+$ || ! "$DENSITY" =~ ^[0-9]+$ ]]; then
             dialog --title "Backup Error" --msgbox "Backup file seems corrupted or invalid.\nContent: $BACKUP" 7 60
             return
        fi

        dialog --title "Confirm Restore" --yesno "Restore these settings from backup?\n\nResolution: ${WIDTH}x${HEIGHT}\nDensity: $DENSITY" 8 50
        if [[ $? -eq 0 ]]; then
            set_resolution "$WIDTH" "$HEIGHT" "$DENSITY"
        fi
    else
        dialog --msgbox "No backup found or backup file is empty!" 6 50
    fi
}


custom_resolution_input() {
    local WIDTH=$(dialog --inputbox "Enter desired width (e.g., 1080):" 8 40 3>&1 1>&2 2>&3 3>&-)
     [[ $? -ne 0 ]] && return
    if [[ ! $WIDTH =~ ^[0-9]+$ ]]; then
        dialog --msgbox "Error: Invalid width! Please enter a numeric value." 6 50
        return
    fi

    local HEIGHT=$(dialog --inputbox "Enter desired height (e.g., 2400):" 8 40 3>&1 1>&2 2>&3 3>&-)
     [[ $? -ne 0 ]] && return
    if [[ ! $HEIGHT =~ ^[0-9]+$ ]]; then
        dialog --msgbox "Error: Invalid height! Please enter a numeric value." 6 50
        return
    fi

    local DENSITY=$(calculate_dpi "$WIDTH" "$HEIGHT")

    dialog --title "Confirm Custom Resolution" --yesno "Apply these settings?\n\nResolution: ${WIDTH}x${HEIGHT}\nCalculated Density: $DENSITY" 8 50
    if [[ $? -eq 0 ]]; then
        set_resolution "$WIDTH" "$HEIGHT" "$DENSITY"
    fi
}

revert_resolution() {
    get_physical_defaults

    dialog --title "Confirm Revert" --yesno "Revert to device's PHYSICAL defaults?\n\nPhysical Resolution: ${PHYSICAL_WIDTH}x${PHYSICAL_HEIGHT}\nPhysical Density: ${PHYSICAL_DENSITY}" 10 70
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}Reverting to physical default resolution and density...${NC}"
        wm size reset
        wm density reset
        sleep 2
        dialog --msgbox "Settings reverted to physical defaults successfully!" 6 60
    fi
}


main_menu() {
    while true; do
        source "$CONFIG_FILE" 2>/dev/null
        local display_name="${DEVICE_NAME:-Unknown Device}"

        local CHOICE=$(dialog --clear --backtitle "ASRM (Android Screen Resolution Manager)" \
                        --title "Main Menu - $display_name" \
                        --menu "Choose an option:" 18 70 11 \
                        1 "Show Current & Physical Settings" \
                        2 "Set Custom Resolution & Density" \
                        3 "Apply Saved Preset" \
                        4 "Add New Preset" \
                        5 "Delete Saved Preset" \
                        6 "Revert to PHYSICAL Defaults" \
                        7 "Backup Current Settings" \
                        8 "Restore Backed Up Settings" \
                        9 "Reconfigure Device Settings" \
                        10 "Exit" 3>&1 1>&2 2>&3 3>&-)

        local exit_status=$?
        if [ $exit_status -ne 0 ]; then
            clear
            echo -e "${YELLOW}Exiting script.${NC}"
            exit 0
        fi


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
            10) clear && echo -e "${GREEN}Exiting normally.${NC}" && exit 0 ;;
            *) dialog --msgbox "Invalid choice. Please try again." 6 40 ;;
        esac
    done
}

check_essentials

load_config

main_menu

# © anlaki - 2025
