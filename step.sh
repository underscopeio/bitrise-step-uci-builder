#!/bin/bash
set -e

# shellcheck disable=SC2154
if [[ ${debug} == "yes" ]] ; then
    set -x
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

STEP_VERSION=0.0.1

MACOS_BIN_FILE="uci-macos"
LINUX_BIN_FILE="uci-linux"

BIN_FILE=$([[ "$(uname)" == "Darwin" ]] && echo "$MACOS_BIN_FILE" || echo "$LINUX_BIN_FILE")
BIN_FILE_PATH="$SCRIPT_DIR/$BIN_FILE"

# Download cli release
wget -q "https://github.com/underscopeio/bitrise-step-uci-builder/releases/download/$STEP_VERSION/$BIN_FILE" -O "$BIN_FILE_PATH"
chmod +x "$BIN_FILE_PATH"

# Obtain vm boot time 
ps_command=$([[ "$(uname)" == "Darwin" ]] && echo "ps -eo lstart,command" || echo "ps -eo lstart,cmd")
date_command=$([[ "$(uname)" == "Darwin" ]] && echo "gdate" || echo "date")

bitrise_process_started_at=$($ps_command | grep "bitrise run" | grep -v grep | sed -e 's/^\(.\{24\}\).*/\1/' | head -1)
bitrise_process_started_at_ms=$($date_command -d "${bitrise_process_started_at:=$(date)}" "+%s%3N")

envman add --key "UCI_BOOTED_AT_TIMESTAMP" --value "${bitrise_process_started_at_ms}"

# Build command arguments
args=("build" "$platform" "$BITRISE_SOURCE_DIR")

# Global args
if [[ ${debug} == "yes" ]] ; then
    args+=("--verbose")
fi
# shellcheck disable=SC2154
if [[ ${disable_cache} == "yes" ]] ; then
    args+=("--disable-cache")
fi
if [[ -n ${build_id} ]] ; then
    args+=("--build-id=""${build_id}""")
fi
if [[ -n ${project_id} ]] ; then
    args+=("--project-id=""${project_id}""")
fi
if [[ -n ${custom_ssh_key_url} ]] ; then
    args+=("--custom-ssh-key-url=""${custom_ssh_key_url}""")
fi
if [[ -n ${root_directory} ]] ; then
    args+=("--root-directory=""${root_directory}""")
fi
if [[ -n ${app_label} ]] ; then
    args+=("--app-label=""${app_label}""")
fi
if [[ -n ${cache_provider} ]] ; then
    args+=("--cache-provider=""${cache_provider}""")
fi
if [[ -n ${log_provider} ]] ; then
    args+=("--log-provider=""${log_provider}""")
fi
if [[ -n ${tracking_provider} ]] ; then
    args+=("--tracking-provider=""${tracking_provider}""")
fi
if [[ -n ${app_envfile_path} ]] ; then
    args+=("--app-envfile-path=""${app_envfile_path}""")
fi
# shellcheck disable=SC2154
if [[ ${exclude_modified_files} == "yes" ]] ; then
    args+=("--exclude-modified-files")
fi

# IOS args
if [[ -n ${ios_certificate_url} ]] ; then
    args+=("--ios-certificate-url=""$ios_certificate_url""")
fi
if [[ -n ${ios_certificate_passphrase} ]] ; then
    args+=("--ios-certificate-passphrase=""$ios_certificate_passphrase""")
fi
if [[ -n ${ios_provisioning_profile_urls} ]] ; then
    # replace | for spaces
    urls="$( echo "${ios_provisioning_profile_urls}" | sed 's/|/ /;s// /' )"
    args+=("--ios-provisioning-profile-urls=""$urls""")
fi
if [[ -n ${ios_provisioning_profile_url_map} ]] ; then
    args+=("--ios-provisioning-profile-url-map=""$ios_provisioning_profile_url_map""")
fi
if [[ -n ${ios_provisioning_profile_specifier} ]] ; then
    args+=("--ios-provisioning-profile-specifier=""$ios_provisioning_profile_specifier""")
fi
if [[ -n ${ios_xcconfig_path} ]] ; then
    args+=("--ios-xcconfig-path=""${ios_xcconfig_path}""")
fi
if [[ -n ${ios_team_id} ]] ; then
    args+=("--ios-team-id=""$ios_team_id""")
fi

# Android args
if [[ -n ${android_flavor} ]] ; then
    args+=("--android-flavor=""$android_flavor""")
fi
if [[ -n ${android_app_identifier} ]] ; then
    args+=("--android-app-identifier=""$android_app_identifier""")
fi
if [[ -n ${android_keystore_url} ]] ; then
    args+=("--android-keystore-url=""$android_keystore_url""")
fi
if [[ -n ${android_keystore_password} ]] ; then
    args+=("--android-keystore-password=""$android_keystore_password""")
fi
if [[ -n ${android_keystore_key_alias} ]] ; then
    args+=("--android-keystore-key-alias=""$android_keystore_key_alias""")
fi
if [[ -n ${android_keystore_key_password} ]] ; then
    args+=("--android-keystore-key-password=""$android_keystore_key_password""")
fi

# AWS Storage
if [[ -n ${aws_s3_access_key_id} ]] ; then
    args+=("--aws-s3-access-key-id=""$aws_s3_access_key_id""")
fi
if [[ -n ${aws_s3_secret_access_key} ]] ; then
    args+=("--aws-s3-secret-access-key=""$aws_s3_secret_access_key""")
fi
if [[ -n ${aws_s3_region} ]] ; then
    args+=("--aws-s3-region=""$aws_s3_region""")
fi
if [[ -n ${aws_s3_bucket} ]] ; then
    args+=("--aws-s3-bucket=""$aws_s3_bucket""")
fi

# Script execution
$BIN_FILE_PATH "${args[@]}"