#!/bin/bash

input=$1
PKG_SUBSTR="running imgpkg copy"
SUBPKG_SUBSTR="will export"
TKG_IMAGE_REPO=projects.registry.vmware.com/tkg/
TKG_CUSTOM_IMAGE_REPOSITORY_PKG_BASE=$2

while IFS= read -r line
do

  if grep -q "$PKG_SUBSTR" <<< "$line"; then
    BASE_PKG_NAME_TAG=$(echo $line | awk '{print $5}')
    #echo $BASE_PKG_NAME_TAG
    BASE_PKG=$(echo $BASE_PKG_NAME_TAG | awk -F':' '{print $1}')
    BASE_TAG=$(echo $BASE_PKG_NAME_TAG | awk -F':' '{print $2}')
    PKG_NAME=$(printf '%s' "${BASE_PKG//$TKG_IMAGE_REPO/}")
    echo "${TKG_CUSTOM_IMAGE_REPOSITORY_PKG_BASE}/${PKG_NAME}/${BASE_TAG}"
  fi

  if grep -q "$SUBPKG_SUBSTR" <<< "$line"; then

    PKG_SHA256=$(echo $line | awk -F':' '{print $2}')
    echo "${TKG_CUSTOM_IMAGE_REPOSITORY_PKG_BASE}/${PKG_NAME}/sha256-${PKG_SHA256}.imgpkg"
  fi
  
done < "$input"

