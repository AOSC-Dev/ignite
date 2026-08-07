#!/bin/bash -e

# Assemble the distribution package (floppy disk images) from the build artifacts.

# Only used if using mtools to copy files to the floppy disk image instead of mounting it.
PRIME_DIR=""

# $1: floppy disk image file path
# $2: floppy disk image size in bytes
create_blank_floppy_image() {
    local img_file="$1"
    local img_size="$2"
    local img_size_blocks=$((img_size / 1024))

    iconv -t CP437 "${CURDIR}"/assets/non-bootable-msg.txt > "${CURDIR}"/build/non-bootable-msg.bin
    unix2dos "${CURDIR}"/build/non-bootable-msg.bin
    mkfs.vfat -F12 --mbr=n -m "${CURDIR}/build/non-bootable-msg.bin" -n 'AG-BOOT' -C "$img_file" "$img_size_blocks"
}

# $1: floppy disk image file path
# $2: boot section image file path
insert_boot_section_image() {
    local img_file="$1"
    local boot_img_file="$2"

    # skip the partition table and copy the boot sector code
    dd if="$boot_img_file" of="$img_file" conv=notrunc bs=1 seek=62 skip=62 count=450
}

mount_floppy_image() {
    local img_file="$1"
    local mount_point="$2"
    local sudo_command="sudo"

    if [[ "$EUID" -eq 0 ]]; then
        sudo_command=""
    fi

    mkdir -p "$mount_point"
    if ! ${sudo_command} mount "$img_file" "$mount_point"; then
        # stage files to a temporary directory and then copy them to the image
        # if mount fails, we can use mtools to copy files directly to the image
        abinfo "mount not available, using mtools to copy files to the floppy image."
        if ! command -v mcopy &> /dev/null; then
            abdie "Neither mount nor mtools is available. Cannot mount floppy image."
        fi
        PRIME_DIR="${mount_point}"
    fi
}

# $1: package stage path
# $2: floppy disk image mount path
# $3: [bool, 0/1] is boot floppy
install_files_to_floppy() {
    local package_stage_path="$1"
    local mount_path="$2"
    local is_boot_floppy="$3"
    local path_prefix

    if [[ "$is_boot_floppy" -eq 1 ]]; then
        path_prefix="/FREEDOS/BIN"
    else
        path_prefix="/"
    fi

    mkdir -pv "${mount_path}/${path_prefix}"
    cp -rv "$package_stage_path"/* "${mount_path}/${path_prefix}"

    if [[ "$is_boot_floppy" -eq 1 ]]; then
        if [[ "${package_stage_path}" =~ /fd-aaa ]]; then
            # Move fdauto.bat and fdconfig.sys to the root of the floppy image
            mv -v "${mount_path}/${path_prefix}/fdauto.bat" "${mount_path}/fdauto.bat"
            mv -v "${mount_path}/${path_prefix}/fdconfig.sys" "${mount_path}/fdconfig.sys"
            mv -v "${mount_path}/${path_prefix}/linld.cmd" "${mount_path}/linld.cmd"
        elif [[ "${package_stage_path}" =~ /freedos-kernel ]]; then
            mv -v "${mount_path}/${path_prefix}/KERNEL.SYS" "${mount_path}/KERNEL.SYS"
        elif [[ "${package_stage_path}" =~ /freedos-boot ]]; then
            rm -fv "${mount_path}/${path_prefix}/boot.bin"
        fi
    fi
}

# $0: mount point path
# $1: (optional) image file for mtools
unmount_floppy_image() {
    local mount_point="$1"
    local img_file="${2:-}"
    local sudo_command="sudo"

    if [[ "$EUID" -eq 0 ]]; then
        sudo_command=""
    fi

    if [[ -n "$PRIME_DIR" ]]; then
        # Copy files from the temporary directory to the image using mtools
        mcopy -sbQp -i "$img_file" "${mount_point}"/* ::
        sync
        rm -rf "$mount_point"
        PRIME_DIR=""
    else
        ${sudo_command} umount "$mount_point"
    fi
}
