# Build an Ubuntu 20.04 ISO/USB Stick using autoinstall easily!
I've made a pretty simple helper script to build an Ubuntu 20.04 ISO (and even write it to a USB stick if you're building the ISO on the same machine the USB stick is plugged into.) If not... Simply copy the ISO to your local system and use a tool like [balena Etcher](https://www.balena.io/etcher/) to write it to USB.

This script will automatically download the source Ubuntu Server ISO for you. All you need to do is run it! See examples below!

# !!! Booting this USB in any computer will wipe this computer's /dev/nvme0n1 device without asking first !!!
If you have a laptop with a /dev/nvme0n1 this could ruin your laptop if you boot from it... You've been warned!

## !!! This script has only been tested on Ubuntu 20.04 and I've made no attempt to make this work on any other OS !!!

## Defaults:
The default username and password (Unless changed below) are: `ubuntu`

## Example Usage:
### Build a generic ISO
```bash
./build_iso.sh
```
### Build an ISO with custom Password
You will be prompted for a password
```bash
./build_iso.sh -P
```
### Build an ISO with custom Username and Password
Again... you'll be prompted to enter the password
```bash 
./build_iso.sh -u myusername -P
```

### Build a genric ISO and write it to USB at sdc
```bash 
./build_iso.sh -F /dev/sdc
```

### Building a custom ISO and writing it to USB
Again... you'll be prompted to enter the password
```bash
./build_iso.sh -u bestuser -P -F /dev/sdc
```

## Adding SSH Keys
To add ssh keys to the iso simply create a file named `pub_keys` in the same directory as `build_iso.sh`

You may have more than one SSH key in this file, just make sure each key is on its own line.
