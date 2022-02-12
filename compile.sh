#!/bin/bash

function echoc {
    echo -e "\033[1;30m$1\033[0m"
}

COMPILE_DIR=./build/compile


echoc "Start to compile App..."
rm -rf $COMPILE_DIR
everdev sol compile src/main/solidity/App.sol -o $COMPILE_DIR
echoc "Done."

