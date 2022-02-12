#!/bin/bash

function echoc {
    echo -e "\033[1;30m$1\033[0m"
}

NETWORK=https://net.ton.dev
APP_NAME=App
GIVER_ADDR=0:841288ed3b55d9cdafa806807f02a0ae0c169aa5edfe88a789a6482429756a94

COMPILE_DIR=./build/compile
DEPLOY_DIR=./build/deploy

set -e

rm -rf $DEPLOY_DIR
mkdir $DEPLOY_DIR

echoc "Start to generate $APP_NAME address"
tonos-cli genaddr "$COMPILE_DIR/$APP_NAME.tvc" "$COMPILE_DIR/$APP_NAME.abi.json" --genkey "$DEPLOY_DIR/$APP_NAME.keys.json" > "$DEPLOY_DIR/genaddr.log"
# shellcheck disable=SC2002
APP_ADDR=$(cat "$DEPLOY_DIR/genaddr.log" | grep "Raw address:" | cut -d ' ' -f 3)
echoc "address: $APP_ADDR"
echoc "Done."


echoc "Ask Giver to send grams"
tonos-cli --url $NETWORK call --abi ./conf/giver.abi.json $GIVER_ADDR sendGrams "{\"dest\":\"$APP_ADDR\",\"amount\":10000000000}"
echoc "Done."

echoc "Start to deploy $APP_NAME"
tonos-cli --url $NETWORK deploy "$COMPILE_DIR/$APP_NAME.tvc" "{}" --sign "$DEPLOY_DIR/$APP_NAME.keys.json" --abi "$COMPILE_DIR/$APP_NAME.abi.json"
echoc "setup ABI"
# shellcheck disable=SC2002
APP_ABI=$(cat "$COMPILE_DIR/$APP_NAME.abi.json" | xxd -ps -c 20000)
tonos-cli --url $NETWORK call "$APP_ADDR" setABI "{\"dabi\":\"$APP_ABI\"}" --sign "$DEPLOY_DIR/$APP_NAME.keys.json" --abi "$COMPILE_DIR/$APP_NAME.abi.json"
echoc "Done."
