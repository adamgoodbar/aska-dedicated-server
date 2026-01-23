#!/bin/bash

APP_FILE="$savegame_files/my_server_properties.txt"

variables=(
    "SESSION_NAME" "display name"
    "SERVER_NAME" "server name"
    "PASSWORD" "password"
    "SERVER_PORT" "steam game port"
    "SERVER_QUERY_PORT" "steam query port"
    "AUTHENTICATION_TOKEN" "authentication token"
    "REGION" "region"
    "KEEP_WORLD_ALIVE" "keep server world alive"
    "AUTOSAVE_STYLE" "autosave style"
    "SAVE_ID" "save id"
)

# Escape special characters for sed replacement
escape_sed() {
    printf '%s' "$1" | sed 's/[&/\]/\\&/g'
}

for ((i=0; i<${#variables[@]}; i+=2)); do
    var_name=${variables[$i]}
    config_name=${variables[$i+1]}

    if [ -n "${!var_name}" ]; then
        echo "${config_name} set to: ${!var_name}"
        escaped_value=$(escape_sed "${!var_name}")
        if grep -q "^$config_name" "$APP_FILE"; then
            sed -i "s|^$config_name =.*|$config_name = $escaped_value|" "$APP_FILE"
        else
            echo -e "\n$config_name = ${!var_name}" >> "$APP_FILE"
        fi
    fi
done

