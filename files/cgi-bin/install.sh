#!/bin/sh -e

if ! command -v jq &> /dev/null; then
   echo "jq is required but not installed. Please install jq and try again."
   exit 1
fi

if ! command -v base64 &> /dev/null
then
    echo "Error: base64 is not installed. Please install it using 'opkg install coreutils-base64'."
    exit 1
fi

