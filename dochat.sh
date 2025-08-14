#!/usr/bin/env bash
#
set -eo pipefail

if [ "$EUID" -eq 0 ] && [ "${ALLOWROOT:-0}" -ne "1" ]
then
  echo "Please do not run this script as root."
  echo "see https://github.com/jdeseva/docker-win-wechat"
  exit 1
fi

DEFAULT_WECHAT_VERSION=latest

#
# Get the image version tag from the env
#
DOCHAT_IMAGE_VERSION="docker-win-wechat:${DOCHAT_WECHAT_VERSION:-${DEFAULT_WECHAT_VERSION}}"

function hello () {
  cat <<'EOF'

       ____         ____ _           _
      |  _ \  ___  / ___| |__   __ _| |_
      | | | |/ _ \| |   | '_ \ / _` | __|
      | |_| | (_) | |___| | | | (_| | |_
      |____/ \___/ \____|_| |_|\__,_|\__|

      https://github.com/jdeseva/docker-win-wechat

                +--------------+
               /|             /|
              / |            / |
             *--+-----------*  |
             |  |           |  |
             |  |   盒装    |  |
             |  |   微信    |  |
             |  +-----------+--+
             | /            | /
             |/             |/
             *--------------*

      DoChat /dɑɑˈtʃæt/ (Docker-weChat) is:

      📦 a Docker image
      🤐 for running PC Windows WeChat
      💻 on your Linux desktop
      💖 by one-line of command

EOF
}

function pullUpdate () {
  if [ -n "$DOCHAT_SKIP_PULL" ]; then
    return
  fi

  echo '🚀 Pulling the docker image...'
  echo
  docker pull "$DOCHAT_IMAGE_VERSION"
  echo
  echo '🚀 Pulling the docker image done.'
}

function main () {

  hello
  pullUpdate

  DEVICE_ARG=()
  for DEVICE in /dev/video*; do
    DEVICE_ARG+=('--device' "$DEVICE")
  done
  if [[ $(lshw -C display 2> /dev/null | grep vendor) =~ NVIDIA ]]; then
    DEVICE_ARG+=('--gpus' 'all' '--env' 'NVIDIA_DRIVER_CAPABILITIES=all')
  fi

  echo '🚀 Starting DoChat /dɑɑˈtʃæt/ ...'
  echo

  # Issue #111 - https://github.com/huan/docker-wechat/issues/111
  rm -f "$HOME/DoChat/Applcation Data/Tencent/WeChat/All Users/config/configEx.ini"

  # Issue #165 - https://github.com/huan/docker-wechat/issues/165#issuecomment-1643063633
  HOST_DIR_HOME_DOCHAT_WECHAT_FILES="$HOME/DoChat/WeChat Files/"
  HOST_DIR_HOME_DOCHAT_APPLICATION_DATA="$HOME/DoChat/Applcation Data/"
  mkdir "$HOST_DIR_HOME_DOCHAT_WECHAT_FILES" -p
  mkdir "$HOST_DIR_HOME_DOCHAT_APPLICATION_DATA" -p

  #
  # --privileged: enable sound (/dev/snd/)
  # --ipc=host:   enable MIT_SHM (XWindows)
  #
  docker run \
    "${DEVICE_ARG[@]}" \
    --name DoWeChat \
    --rm \
    -i \
    \
    -v "$HOST_DIR_HOME_DOCHAT_WECHAT_FILES":'/home/user/WeChat Files/' \
    -v "$HOST_DIR_HOME_DOCHAT_APPLICATION_DATA":'/home/user/.wine/drive_c/users/user/Application Data/' \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v "/run/user/$(id -u)/pulse":"/run/pulse" \
    \
    -e DISPLAY \
    -e DOCHAT_DEBUG \
    -e DOCHAT_DPI \
    \
    -e XMODIFIERS \
    -e GTK_IM_MODULE \
    -e QT_IM_MODULE \
    \
    -e AUDIO_GID="$(getent group audio | cut -d: -f3)" \
    -e VIDEO_GID="$(getent group video | cut -d: -f3)" \
    -e GID="$(id -g)" \
    -e UID="$(id -u)" \
    \
    --ipc=host \
    --privileged \
    --add-host dldir1.qq.com:127.0.0.1 \
    \
    "$DOCHAT_IMAGE_VERSION"

    #
    # Do not put any command between
    # the above "docker run" and
    # the below "echo"
    # because we need to output error code $?
    #
    echo "📦 DoChat Exited with code [$?]"
    echo
    echo '🐞 Bug Report: 1234'
    echo

}

main
