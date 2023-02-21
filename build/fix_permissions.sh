#!/bin/bash
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

usage() {
    echo "Usage: fix_permissions.sh -p <permissions_file> -t <rootfs_dir>"
    exit 1
}

apply_permissions() {
    local dentry
    local flags
    local flag
    local opts
    local user
    local group
    local file_mode

    cd $ROOTFS

    while read dentry flags user group file_mode; do
        if [[ $dentry =~ ^# ]] || [[ -z $dentry ]]; then
            continue
        fi

        opts=""

        set -- $(echo $flags |sed 's/,/ /g') --
        for flag; do
            case "$flag" in
                recurse)
                    opts="$opts -R"
                    shift
                    ;;
                -)
                    opts=""
                    shift
                    ;;
                --)
                    shift
                    break
                    ;;
            esac
        done

        if [[ -L $dentry ]]; then
            echo skipping symlink $dentry
            continue
        fi

        echo chmod $opts $file_mode $dentry
        chmod $opts $file_mode $dentry
        echo chown $opts $user:$group $dentry
        chown $opts $user:$group $dentry
    done
}

PERMISSIONS=""
ROOTFS=""
ARGS=$(getopt hp:t: $*)
set -- $ARGS

for i; do
    case "$1" in
        -p)  # permissions_file
            PERMISSIONS="$2"
            shift 2
            ;;
        -t)  # rootfs_dir
            ROOTFS="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -h|*)
            usage
            ;;
    esac
done

if [[ -z $PERMISSIONS ]] || [[ -z $ROOTFS ]]; then
    usage
fi

apply_permissions < $PERMISSIONS
