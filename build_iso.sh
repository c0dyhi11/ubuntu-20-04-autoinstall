#!/bin/bash
BASE_DIR='iso'
SUB_DIR='nocloud'
REPO_DIR="$BASE_DIR/$SUB_DIR"
UBUNTU_MIRROR="https://mirror.pit.teraswitch.com/ubuntu-releases/"
UBUNTU_VERSION="20.04.1"
ISO_NAME="ubuntu-20.04.1-live-server-amd64.iso"


function show_help() {
    echo "Usage:"
    echo "  ./build_iso.sh [options]"
    echo "  Options:"
    echo "    -h [-?]                   Show this help text"
    echo "    -U <username>             Use this username at install time"
    echo "    -P                        Prompt for password to use at install time"
    echo "    -F </path/to/usb>         Flash ISO to USB"
}


function install_packages() {
    if [ ! -f ./.apt_updated ]; then
        sudo apt update -y && \
        sudo apt install syslinux-utils genisoimage p7zip-full xorriso wget isolinux -y && \
        touch ./.apt_updated
    fi
}


function download_iso() {
    if [ ! -f $ISO_NAME ]; then
        wget $UBUNTU_MIRROR/$UBUNTU_VERSION/$ISO_NAME
    fi
}


function inject_keys() {
    ssh_keys=$'\\n'
    while read key; do
        ssh_keys="$ssh_keys      - '$key'"$'\\n'
    done <pub_keys
    sed -i "s|__REPLACE_ME__|$ssh_keys|g" $REPO_DIR/user-data
}


function build_iso() {
    rm -rf $BASE_DIR
    mkdir -p $REPO_DIR
    7z x $ISO_NAME -x'![BOOT]' -o$BASE_DIR
    cp meta-data user-data $REPO_DIR
    md5sum $BASE_DIR/README.diskdefines > $BASE_DIR/md5sum.txt
    sed -i "s|---|autoinstall ds=nocloud;s=/cdrom/$SUB_DIR/ ---|g" $BASE_DIR/isolinux/txt.cfg
    sed -i "s|---|autoinstall ds=nocloud\\\;s=/cdrom/$SUB_DIR/ ---|g" $BASE_DIR/boot/grub/grub.cfg
    if [ -f pub_keys ]; then
        inject_keys
    else
        sed -i '/authorized-keys: __REPLACE_ME__/d' $REPO_DIR/user-data
    fi
    sed -i "s|__USER_NAME__|$1|g" $REPO_DIR/user-data
    sed -i "s|__PASSWORD__|$2|g" $REPO_DIR/user-data
    xorriso -as mkisofs -r \
        -V Ubuntu\ custom\ amd64 \
        -o ubuntu-20.04.1-live-server-amd64-autoinstall.iso \
        -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
        -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
        -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin  \
        $BASE_DIR/boot $BASE_DIR
    rm -rf $BASE_DIR
}


function flash_to_usb() {
    sudo dd if=ubuntu-20.04.1-live-server-amd64-autoinstall.iso of=$1 bs=1M status=progress
}


function ask_pass() {
    echo -n Enter Password: 
    read -s password
    echo -n Retype Password:
    read -s re_password
    if [ "$password" == "$re_password" ]; then
        PASSWORD=`echo -n $password | openssl passwd -6`
    else
        ehco "Passwords did not match! Exiting..."
        exit 1
    fi
}


OPTIND=1 
USER="ubuntu"
PASSWORD='$6$mRQxrAB6Y3bwOdwZ$MPbMoqpw1RnbgnTb0yXq.K9aQEeBVdw1.i6WN5MLKRVkc0Fv.0bIYsd/HtdTgfEJosDcro1JZ2Xgo.tbIsorY/'
USB_DEV=""

while getopts "h?uPF:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    u)  USER=$OPTARG
        ;;
    P)  
        ask_pass
        ;;
    F)  USB_DEV=$OPTARG
        ;;
    esac
done

install_packages
download_iso
build_iso $USER $PASSWORD
if [ ! -z $USB_DEV ]; then
    flash_to_usb $USB_DEV
fi
