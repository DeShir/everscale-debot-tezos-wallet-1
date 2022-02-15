#!/bin/bash

function echoc {
    echo -e "\033[1;30m$1\033[0m"
}

set -e

NETWORK=https://net.ton.dev
DEPLOY_DIR=./build/deploy

echoc "Run App"
# shellcheck disable=SC2002
APP_ADDR=$(cat "$DEPLOY_DIR/genaddr.log" | grep "Raw address:" | cut -d ' ' -f 3)
tonos-cli --url "$NETWORK" debot --debug fetch "$APP_ADDR"
echoc "Done."
