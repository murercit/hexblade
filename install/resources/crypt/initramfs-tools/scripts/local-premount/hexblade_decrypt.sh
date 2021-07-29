#!/bin/sh -e

PREREQ="btrfs"

# Output pre-requisites
prereqs()
{
        echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

set -x

mkdir /secrets
mount -t btrfs -r -o subvol=@secrets /dev/mapper/MAINCRYPTED /secrets

ls /secrets/parts/id-*.id | while read k; do
        echo "...$k"
done

set +x
sh