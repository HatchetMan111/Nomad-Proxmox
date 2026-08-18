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

  if [[ ! -d /opt/project-nomad ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "nomad" "Crosstalk-Solutions/project-nomad"; then
    msg_info "Updating $APP"
    cd /opt/project-nomad || exit

    APP_KEY=$(grep 'APP_KEY=' compose.yml | head -1 | sed 's/.*APP_KEY=//')
    DB_PASS=$(grep 'DB_PASSWORD=' compose.yml | head -1 | sed 's/.*DB_PASSWORD=//')
    DB_ROOT_PASS=$(grep 'MYSQL_ROOT_PASSWORD=' compose.yml | head -1 | sed 's/.*MYSQL_ROOT_PASSWORD=//')
    DB_USER_PASS=$(grep 'MYSQL_PASSWORD=' compose.yml | head -1 | sed 's/.*MYSQL_PASSWORD=//')
    NOMAD_URL=$(grep 'URL=' compose.yml | head -1 | sed 's/.*URL=//')

    fetch_and_deploy_gh_release "nomad" "Crosstalk-Solutions/project-nomad" "tarball"

    cp /opt/nomad/install/management_compose.yaml compose.yml
    cp /opt/nomad/install/start_nomad.sh start_nomad.sh
    cp /opt/nomad/install/stop_nomad.sh stop_nomad.sh
    cp /opt/nomad/install/update_nomad.sh update_nomad.sh
    chmod +x ./*.sh

    sed -i "s|URL=replaceme|URL=${NOMAD_URL}|g" compose.yml
    [[ -n "$APP_KEY" ]] && sed -i "s|APP_KEY=replaceme|APP_KEY=${APP_KEY}|g" compose.yml
    [[ -n "$DB_PASS" ]] && sed -i "s|DB_PASSWORD=replaceme|DB_PASSWORD=${DB_PASS}|g" compose.yml
    [[ -n "$DB_ROOT_PASS" ]] && sed -i "s|MYSQL_ROOT_PASSWORD=replaceme|MYSQL_ROOT_PASSWORD=${DB_ROOT_PASS}|g" compose.yml
    [[ -n "$DB_USER_PASS" ]] && sed -i "s|MYSQL_PASSWORD=replaceme|MYSQL_PASSWORD=${DB_USER_PASS}|g" compose.yml
    sed -i 's|"8080:8080"|"80:8080"|g' compose.yml

    $STD docker compose pull
    $STD docker compose up -d --force-recreate
    msg_ok "Updated $APP"
  else
    msg_ok "No update required"
  fi
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
