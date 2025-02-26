#!/bin/bash
set -e

# shellcheck disable=SC2154
if [[ "${fail_safe}" == "true" || "${fail_safe}" == "yes" ]]; then
  set +e
fi

# shellcheck disable=SC2154
if [[ "${debug}" == "true" || "${debug}" == "yes" ]]; then
  set -x
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITRISE_STEP_VERSION=$(cat < "$SCRIPT_DIR/package.json" | jq -r '.version')

# Binary initialization
if [[ -n ${nitro_bin_file_path} ]]; then
  BIN_FILE_PATH="$nitro_bin_file_path"
else
  MACOS_BIN_FILE="nitro-macos"
  LINUX_BIN_FILE="nitro-linux"

  BIN_FILE=$([[ "$(uname)" == "Darwin" ]] && echo "$MACOS_BIN_FILE" || echo "$LINUX_BIN_FILE")
  BIN_FILE_PATH="$SCRIPT_DIR/nitro"

  # Download cli release
  wget -q "https://github.com/underscopeio/bitrise-step-nitro/releases/download/$BITRISE_STEP_VERSION/$BIN_FILE" -O "$BIN_FILE_PATH"
  chmod +x "$BIN_FILE_PATH"
fi

# Obtain vm boot time
ps_command=$([[ "$(uname)" == "Darwin" ]] && echo "ps -eo lstart,command" || echo "ps -eo lstart,cmd")
date_command=$([[ "$(uname)" == "Darwin" ]] && echo "gdate" || echo "date")

bitrise_process_started_at=$($ps_command | grep "bitrise run" | grep -v grep | sed -e 's/^\(.\{24\}\).*/\1/' | head -1)
bitrise_process_started_at_ms=$($date_command -d "${bitrise_process_started_at:=$(date)}" "+%s%3N")

# Set environment variables
export NITRO_BOOTED_AT_TIMESTAMP="$bitrise_process_started_at_ms"

if [[ -n ${entry_file} ]]; then
  export ENTRY_FILE="$entry_file"
fi

# Build command arguments
args=("$platform")
args+=("--repo-path" "$BITRISE_SOURCE_DIR")
args+=("--tracking-provider" "nitro-on-premise")

# Global args
if [[ "${debug}" == "true" || "${debug}" == "yes" ]]; then
  args+=("--verbose")
fi

# shellcheck disable=SC2154
if [[ "${disable_cache}" == "true" || "${disable_cache}" == "yes" ]]; then
  args+=("--disable-cache")
fi

# shellcheck disable=SC2154
if [[ "${disable_auto_versioning}" == "true" || "${disable_auto_versioning}" == "yes" ]]; then
  args+=("--disable-auto-versioning")
fi

if [[ -n ${build_id} ]]; then
  args+=("--build-id" "$build_id")
fi

if [[ -n ${project_id} ]]; then
  args+=("--project-id" "$project_id")
fi

if [[ -n ${custom_ssh_key_url} ]]; then
  args+=("--custom-ssh-key-url" "$custom_ssh_key_url")
fi

if [[ -n ${output_directory} ]]; then
  args+=("--output-directory" "$output_directory")
fi

if [[ -n ${root_directory} ]]; then
  args+=("--root-directory" "$root_directory")
fi

if [[ -n ${version_name} ]]; then
  args+=("--version-name" "$version_name")
fi

if [[ -n ${version_code} ]]; then
  args+=("--version-code" "$version_code")
fi

if [[ -n ${app_label} ]]; then
  args+=("--app-label" "$app_label")
fi

if [[ -n ${cache_provider} ]]; then
  args+=("--cache-provider" "$cache_provider")
fi

# shellcheck disable=SC2154
if [[ "${exclude_modified_files}" == "true" || "${exclude_modified_files}" == "yes" ]]; then
  args+=("--exclude-modified-files")
fi

# deprecated: fallback to cache_env_var_lookup_keys
cache_env_var_lookup_keys=${cache_env_var_lookup_keys:-$env_var_lookup_keys}
if [[ -n ${cache_env_var_lookup_keys} ]]; then
  IFS='|' cache_env_var_lookup_keys_value=("$cache_env_var_lookup_keys")
  # shellcheck disable=SC2206
  args+=("--cache-env-var-lookup-keys" ${cache_env_var_lookup_keys_value[@]})
fi

if [[ -n ${cache_file_lookup_paths} ]]; then
  IFS='|' cache_file_lookup_paths_value=("$cache_file_lookup_paths")
  # shellcheck disable=SC2206
  args+=("--cache-file-lookup-paths" ${cache_file_lookup_paths_value[@]})
fi

# shellcheck disable=SC2154
if [[ "${experimental_metro_cache_enabled}" == "true" || "${experimental_metro_cache_enabled}" == "yes" ]]; then
  args+=("--experimental-metro-cache-enabled")
fi

if [[ -n ${pre_install_command} ]]; then
  args+=("--pre-install-command" "$pre_install_command")
fi

if [[ -n ${pre_build_command} ]]; then
  args+=("--pre-build-command" "$pre_build_command")
fi

if [[ -n ${post_build_command} ]]; then
  args+=("--post-build-command" "$post_build_command")
fi

# IOS args
if [[ "${platform}" == "ios" ]]; then
  if [[ -n ${ios_scheme} ]]; then
    args+=("--ios-scheme" "$ios_scheme")
  fi

  if [[ -n ${ios_certificate_url} ]]; then
    args+=("--ios-certificate-url" "$ios_certificate_url")
  fi

  if [[ -n ${ios_certificate_passphrase} ]]; then
    args+=("--ios-certificate-passphrase" "$ios_certificate_passphrase")
  fi

  if [[ -n ${ios_codesigning_identity} ]]; then
    args+=("--ios-codesigning-identity" "$ios_codesigning_identity")
  fi

  if [[ -n ${ios_provisioning_profile_urls} ]]; then
    IFS='|' ios_provisioning_profile_urls_value=("$ios_provisioning_profile_urls")
    # shellcheck disable=SC2206
    args+=("--ios-provisioning-profile-urls" ${ios_provisioning_profile_urls_value[@]})
  fi

  if [[ -n ${ios_provisioning_profile_specifier} ]]; then
    args+=("--ios-provisioning-profile-specifier" "$ios_provisioning_profile_specifier")
  fi

  if [[ -n ${ios_xcconfig_path} ]]; then
    args+=("--ios-xcconfig-path" "$ios_xcconfig_path")
  fi

  if [[ -n ${ios_team_id} ]]; then
    args+=("--ios-team-id" "$ios_team_id")
  fi

  if [[ -n ${ios_export_method} ]]; then
    args+=("--ios-export-method" "$ios_export_method")
  fi
fi

# Android args
if [[ "${platform}" == "android" ]]; then
  if [[ -n ${android_flavor} ]]; then
    args+=("--android-flavor" "$android_flavor")
  fi

  if [[ -n ${android_keystore_url} ]]; then
    args+=("--android-keystore-url" "$android_keystore_url")
  fi

  if [[ -n ${android_keystore_password} ]]; then
    args+=("--android-keystore-password" "$android_keystore_password")
  fi

  if [[ -n ${android_keystore_key_alias} ]]; then
    args+=("--android-keystore-key-alias" "$android_keystore_key_alias")
  fi

  if [[ -n ${android_keystore_key_password} ]]; then
    args+=("--android-keystore-key-password" "$android_keystore_key_password")
  fi
fi

# AWS Storage
if [[ -n ${aws_s3_access_key_id} ]]; then
  args+=("--aws-s3-access-key-id" "$aws_s3_access_key_id")
fi

if [[ -n ${aws_s3_secret_access_key} ]]; then
  args+=("--aws-s3-secret-access-key" "$aws_s3_secret_access_key")
fi

if [[ -n ${aws_s3_region} ]]; then
  args+=("--aws-s3-region" "$aws_s3_region")
fi

if [[ -n ${aws_s3_bucket} ]]; then
  args+=("--aws-s3-bucket" "$aws_s3_bucket")
fi

# Script execution
$BIN_FILE_PATH "${args[@]}"

exit_code=$?

if [[ exit_code -ne 0 ]]; then
  echo "⚠️ Nitro has thrown a '${exit_code}' error code while running on fail-safe mode. You can check 'NITRO_BUILD_FAILED' value in further steps."
  envman add --key "NITRO_BUILD_FAILED" --value "true"
  envman add --key "NITRO_BUILD_STATUS" --value "failed"
else  
  envman add --key "NITRO_BUILD_FAILED" --value "false"
  envman add --key "NITRO_BUILD_STATUS" --value "success"
fi
