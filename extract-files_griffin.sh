#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

DEVICE=griffin
VENDOR=motorola

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

LINEAGE_ROOT="$MY_DIR"/../../..

HELPER="$LINEAGE_ROOT"/vendor/lineage/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

while [ "$1" != "" ]; do
    case $1 in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC=$1
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$LINEAGE_ROOT" false "$CLEAN_VENDOR"

extract "$MY_DIR"/proprietary-files_griffin.txt "$SRC" "$SECTION"

BLOB_ROOT="$LINEAGE_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary

# Load wrapped shim
patchelf --add-needed libjustshoot_shim.so $BLOB_ROOT/vendor/lib/libjustshoot.so

# Load camera configs from vendor
CAMERA2_SENSOR_MODULES="$BLOB_ROOT"/vendor/lib/libmmcamera2_sensor_modules.so
sed -i "s|/system/etc/camera/|/vendor/etc/camera/|g" "$CAMERA2_SENSOR_MODULES"

# Load normal P libbinder and cutils
CAMERAHAL="$BLOB_ROOT"/vendor/lib/hw/camera.msm8996.so
CAMERAMODHAL="$BLOB_ROOT"/vendor/lib/hw/libcamera_mods_legacy_hal.so
CAMERADAEMON="$BLOB_ROOT"/vendor/bin/mm-qcamera-daemon
sed -i "s|libbinder.so|libPinder.so|g" "$CAMERAHAL"
sed -i "s|libcutils.so|libPutils.so|g" "$CAMERAHAL"
sed -i "s|libbinder.so|libPinder.so|g" "$CAMERAMODHAL"
sed -i "s|libcutils.so|libPutils.so|g" "$CAMERAMODHAL"
sed -i "s|libbinder.so|libPinder.so|g" "$CAMERADAEMON"
sed -i "s|libcutils.so|libPutils.so|g" "$CAMERADAEMON"

"$MY_DIR"/setup-makefiles.sh
