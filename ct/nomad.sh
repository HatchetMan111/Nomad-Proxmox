#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: HatchetMan111
# License: MIT | https://github.com/HatchetMan111/Nomad-Proxmox/raw/main/LICENSE
#
# App source (Apache-2.0):   https://github.com/Crosstalk-Solutions/project-nomad
# App website:                https://www.projectnomad.us
# Packaging inspired by:      https://github.com/scripts-underground/proxmox (MIT)
#                              https://scripts-underground.org/lxc/nomad/

APP="Nomad"
var_tags="${var_tags:-offline;knowledge;education;ai}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_nesting="${var_nesting:-1}"
var_keyctl="${var_keyctl:-1}"
var_arm64="${var_arm64:-no}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/project-nomad/compose.yml ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating $APP"
  cd /opt/project-nomad || exit
  $STD docker compose -p project-nomad -f compose.yml pull
  $STD docker compose -p project-nomad -f compose.yml up -d --force-recreate
  msg_ok "Updated $APP"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW} Nomad has no built-in authentication - restrict access at the network level.${CL}"
