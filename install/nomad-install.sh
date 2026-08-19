#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: HatchetMan111
# License: MIT | https://github.com/HatchetMan111/Nomad-Proxmox/raw/main/LICENSE
#
# App source (Apache-2.0): https://github.com/Crosstalk-Solutions/project-nomad
# Config/helper files are downloaded directly from the upstream repo's main
# branch (Nomad does not publish these as GitHub release assets). Docker is
# installed via Docker's own official convenience script rather than a
# framework helper, since that behaves identically across every Debian/Ubuntu
# release instead of depending on unverified helper functions.

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl sudo mc gnupg openssl ca-certificates
msg_ok "Installed Dependencies"

echo ""
echo "License Agreement & Terms of Use"
echo "__________________________________"
echo ""
echo "Project N.O.M.A.D. is licensed under the Apache License 2.0."
echo "Full license: https://www.apache.org/licenses/LICENSE-2.0"
echo ""
read -rp "I have read and accept the License Agreement & Terms of Use (y/N)? " NOMAD_LICENSE_CHOICE
case "$NOMAD_LICENSE_CHOICE" in
  y | Y) msg_ok "License accepted" ;;
  *)
    msg_error "License not accepted. Installation cannot continue."
    exit 1
    ;;
esac

msg_info "Installing Docker"
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  $STD sh /tmp/get-docker.sh
  rm -f /tmp/get-docker.sh
fi
systemctl enable --now docker &>/dev/null || true
if ! command -v docker &>/dev/null; then
  msg_error "Docker installation failed - aborting"
  exit 1
fi
if ! docker compose version &>/dev/null; then
  msg_error "Docker Compose plugin is missing - aborting"
  exit 1
fi
msg_ok "Installed Docker"

NOMAD_DIR="/opt/project-nomad"
MANAGEMENT_COMPOSE_FILE_URL="https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/management_compose.yaml"
START_SCRIPT_URL="https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/start_nomad.sh"
STOP_SCRIPT_URL="https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/stop_nomad.sh"
UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/update_nomad.sh"

# --- Optional GPU detection (best-effort, never blocks the install) ---
NOMAD_GPU_TYPE=""
if command -v nvidia-smi &>/dev/null || lspci 2>/dev/null | grep -qi nvidia; then
  if ! command -v nvidia-ctk &>/dev/null; then
    msg_info "Installing NVIDIA Container Toolkit"
    (
      curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey 2>/dev/null | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg 2>/dev/null
      curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list 2>/dev/null |
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null 2>&1
      apt-get update -qq
      apt-get install -y nvidia-container-toolkit -qq
      if command -v nvidia-ctk &>/dev/null; then
        nvidia-ctk runtime configure --runtime=docker
        systemctl restart docker
      fi
    ) &>/dev/null || true
    msg_ok "Installed NVIDIA Container Toolkit"
  fi
  command -v nvidia-smi &>/dev/null && NOMAD_GPU_TYPE="nvidia"
elif lspci 2>/dev/null | grep -iE "VGA|3D controller|Display" | grep -iEq "amd|radeon"; then
  NOMAD_GPU_TYPE="amd"
fi

msg_info "Downloading Nomad configuration"
mkdir -p "${NOMAD_DIR}/storage/logs"
touch "${NOMAD_DIR}/storage/logs/admin.log"

download_or_fail() {
  local url="$1" dest="$2"
  if ! curl -fsSL "$url" -o "$dest"; then
    msg_error "Download failed: $url"
    exit 1
  fi
}

download_or_fail "$START_SCRIPT_URL" "${NOMAD_DIR}/start_nomad.sh"
download_or_fail "$STOP_SCRIPT_URL" "${NOMAD_DIR}/stop_nomad.sh"
download_or_fail "$UPDATE_SCRIPT_URL" "${NOMAD_DIR}/update_nomad.sh"
download_or_fail "$MANAGEMENT_COMPOSE_FILE_URL" "${NOMAD_DIR}/compose.yml"
chmod +x "${NOMAD_DIR}"/*.sh

if [[ ! -s "${NOMAD_DIR}/compose.yml" ]]; then
  msg_error "compose.yml is empty after download - aborting"
  exit 1
fi
[[ -n "$NOMAD_GPU_TYPE" ]] && echo "$NOMAD_GPU_TYPE" >"${NOMAD_DIR}/storage/.nomad-gpu-type"
msg_ok "Downloaded Nomad configuration"

# Clear a stale MySQL data dir from a previous failed attempt - otherwise
# MySQL keeps old credentials and ignores the freshly generated ones below.
[[ -d "${NOMAD_DIR}/mysql" ]] && rm -rf "${NOMAD_DIR}/mysql"

msg_info "Configuring Nomad"
LOCAL_IP=$(hostname -I | awk '{print $1}')
APP_KEY=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c32)
DB_ROOT_PASSWORD=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c13)
DB_USER_PASSWORD=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c13)

sed -i "s|URL=replaceme|URL=http://${LOCAL_IP}|g" "${NOMAD_DIR}/compose.yml"
sed -i "s|APP_KEY=replaceme|APP_KEY=${APP_KEY}|g" "${NOMAD_DIR}/compose.yml"
sed -i "s|DB_PASSWORD=replaceme|DB_PASSWORD=${DB_USER_PASSWORD}|g" "${NOMAD_DIR}/compose.yml"
sed -i "s|MYSQL_ROOT_PASSWORD=replaceme|MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}|g" "${NOMAD_DIR}/compose.yml"
sed -i "s|MYSQL_PASSWORD=replaceme|MYSQL_PASSWORD=${DB_USER_PASSWORD}|g" "${NOMAD_DIR}/compose.yml"
# Expose Nomad on the default HTTP port (80) instead of upstream's default :8080
sed -i 's|"8080:8080"|"80:8080"|g' "${NOMAD_DIR}/compose.yml"

{
  echo "Nomad Credentials"
  echo "APP_KEY: ${APP_KEY}"
  echo "MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}"
  echo "MYSQL_PASSWORD: ${DB_USER_PASSWORD}"
} >>~/nomad.creds
msg_ok "Configured Nomad"

msg_info "Starting Nomad"
cd "${NOMAD_DIR}" || exit
$STD docker compose -p project-nomad -f compose.yml up -d
sleep 8
RUNNING_COUNT=$(docker compose -p project-nomad -f compose.yml ps --status=running -q 2>/dev/null | wc -l)
if [[ "$RUNNING_COUNT" -eq 0 ]]; then
  msg_error "No Nomad containers are running. Check: docker compose -p project-nomad -f ${NOMAD_DIR}/compose.yml logs"
else
  msg_ok "Started Nomad ($RUNNING_COUNT container(s) running)"
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
cleanup_lxc
