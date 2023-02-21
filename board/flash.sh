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

ROOTDIR=$(dirname $0)/..
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FASTBOOT_CMD="$(which fastboot)"

function partition_table_image {
    if [[ $1 -gt 7000000000 ]] && [[ $1 -lt 8000000000 ]]; then
        echo "partition-table-8gb.img"
    elif [[ $1 -gt 14000000000 ]] && [[ $1 -lt 17000000000 ]]; then
        echo "partition-table-16gb.img"
    elif [[ $1 -gt 60000000000 ]]; then
        echo "partition-table-64gb.img"
    fi
}

function die {
    echo "$@" >/dev/stderr
    exit 1
}

function try {
    $@ || die "Failed to execute '$@'"
}

function ensure_flash_files_present
{
    local found_all_files=true
    local files_dir="$1"; shift
    local arch="$1"; shift
    local files=(
        "u-boot.imx"
        "home.img"
        "partition-table-8gb.img"
        "partition-table-16gb.img"
        "partition-table-64gb.img"
        "boot_${arch}.img"
        "rootfs_${arch}.img"
    )

    for file in "${files[@]}"; do
        if [[ ! -f "${files_dir}/${file}" ]]; then
            echo "${file} is missing"
            found_all_files=""
        fi
    done

    if [[ -z "${found_all_files}" ]]; then
        die "Required image files are missing. Cannot continue."
    fi
}

function flash
{
    local partition="$1"; shift
    local file="$1"; shift

    try ${FASTBOOT_CMD} flash "${partition}" "${file}"
}

function erase
{
    local partition="$1"; shift
    try ${FASTBOOT_CMD} erase "${partition}"
}

function reboot_bootloader
{
    try ${FASTBOOT_CMD} reboot-bootloader
}

function get_emmc_size
{
    local output=$(${FASTBOOT_CMD} getvar mmc_size 2>&1)
    if [[ "$?" != "0" ]]; then
        die "Couldn't get emmc size (nonzero exit, output was [${output}])"
    fi

    local emmc_size=$(echo $output |awk '/mmc_size:/ { print $2 }')

    if [[ -z "${emmc_size}" ]]; then
        die "Can't get emmc size (output was [${emmc_size}])"
    fi

    echo "${emmc_size}"
}

function partition_present
{
    local partition="$1"; shift
    local output=$(${FASTBOOT_CMD} getvar "partition-type:${partition}" 2>&1)
    if [[ "$?" != "0" ]]; then
        die "Couldn't communicate with fastboot (nonzero exit, output was [${output}])"
    fi

    if [[ "${output}" =~ "FAILED" ]]; then
        return 1
    else
        return 0
    fi
}

function flash_partitions
{
    local files_dir="$1"; shift
    local arch="$1"; shift
    local overwrite_home="$1"; shift
    local will_flash_home=true
    local mmc_size=$(get_emmc_size)
    local part_image=$(partition_table_image "${mmc_size}")

    if [[ ! -f "${files_dir}/${part_image}" ]]; then
        die "Can't find partition image ${part_image} to flash"
    fi

    if partition_present home && [[ -z "${overwrite_home}" ]]; then
        will_flash_home=""
        echo "Existing home partition detected, will not flash home (override with -H)"
    fi

    flash bootloader0 "${files_dir}/u-boot.imx"
    reboot_bootloader
    sleep 3

    flash gpt "${files_dir}/${part_image}"
    reboot_bootloader
    sleep 3

    erase misc

    if [[ ! -z "${will_flash_home}" ]]; then
        flash home "${files_dir}/home.img"
    fi

    flash boot "${files_dir}/boot_${arch}.img"
    flash rootfs "${files_dir}/rootfs_${arch}.img"
}

function main {
    local usage=$(cat <<EOF
Usage: flash.sh [-n] [-H] [-d <files_dir>] [-s <serial>] [-r <detect_retries>]

  -n                  prevents the automatic reboot of the connected board
  -H                  overwrites the home partition if one is detected
  -d <files_dir>      flashes files from <files_dir> (defaults to current dir)
  -s <serial>         only flashes the board with the given fastboot serial number
  -r <detect_retries> number of times to retry waiting for a device (defaults to 0)
  -u <userspace_arch> sets the name of the userspace to flash (defaults to arm64)
EOF
)

    local dont_reboot                # -n
    local overwrite_home             # -H
    local serial_number              # -s <serial>
    local arch="arm64"               # -a <userspace_arch>
    local files_dir                  # -d <files_dir>
    local detect_retries=0           # -r <detect_retries>
    local args=$(getopt hnHs:d:r: $*)

    set -- $args

    for i; do
        case "$1" in
            -n)  # don't rebooot
                dont_reboot=true
                shift 1
                ;;

            -H)  # overwrite home if it exists
                overwrite_home=true
                shift 1
                ;;

            -s)  # serial <serial_no>
                serial_number="$2"
                shift 2
                ;;

            -a)  # userspace architecture <arch>
                arch="$2"
                shift 2
                ;;

            -d)  # files dir <files_dir>
                files_dir="$2"
                shift 2
                ;;

            -r)  # detection retries <detect_retries>
                detect_retries="$2"
                if ! [[ "${detect_retries}" -gt "0" ]]; then
                    die "Retry count \"${detect_retries}\" is not a positive integer"
                    return 1
                fi
                shift 2
                ;;

            --)  # end of args
                shift
                break
                ;;

            *)   # help
                die "${usage}"
                ;;
        esac
    done

    if [[ ! -x "${FASTBOOT_CMD}" ]]; then
        die "Couldn't find fastboot on your PATH -- did you install it?"
    fi

    if [[ -n "${serial_number}" ]]; then
        FASTBOOT_CMD="fastboot -s ${serial_number}"
    fi

    if [[ -z "${files_dir}" ]]; then
        if [[ -n "${PRODUCT_OUT}" ]]; then
            files_dir="${PRODUCT_OUT}"
        else
            files_dir="."
        fi
    fi

    # Start the flashing process

    if [[ -n "${serial_number}" ]]; then
        detect_device_or_die "${detect_retries}" "${serial_number}"
    fi

    ensure_flash_files_present "${files_dir}" "${arch}"
    flash_partitions "${files_dir}" "${arch}" "${overwrite_home}"

    if [[ -z "${dont_reboot}" ]]; then
        try ${FASTBOOT_CMD} reboot
    else
        echo "Skipping reboot as requested -- manual reboot will be required"
    fi

    echo "Flash completed."
}

function detect_device_or_die
{
    local retries="$1"; shift
    local serial="$1"; shift
    local count=0
    local output
    local found

    echo -n "Waiting up to ${retries} seconds for device ${serial}"
    for ((count=0; count<"${retries}"; count++)); do
        output=$(${FASTBOOT_CMD} devices)
        if [[ "$?" != "0" ]]; then
            die "Unable to communicate with fastboot (nonzero exit, output was [${output}])"
        fi

        if [[ "${output}" =~ "${serial}" ]]; then
            found=true
            break
        fi

        echo -n '.'
        sleep 1
    done
    echo

    if [[ -z "${found}" ]]; then
        die "Couldn't find device with serial ${serial} in fastboot output"
    else
        echo "Found device ${serial}"
    fi
}

main "$@"
