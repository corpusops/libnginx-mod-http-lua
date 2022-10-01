#!/usr/bin/env bash
set -e
declare -A DHVERSIONS
DHVERSIONS[xenial]=9
DHVERSIONS[bionic]=11
DHVERSIONS[focal]=12
DHVERSIONS[jammy]=13
DHVERSIONS[kinetic]=13
cd "$(dirname "$(readlink -f "$0")")/.."
VERSION_CODENAME=$(. /etc/os-release && echo $VERSION_CODENAME)
RELEASE=${RELEASE:-${1:-$VERSION_CODENAME}}
DHRELEASE="${DHVERSIONS[$RELEASE]}"
sed -i -re "s/debhelper-compat ?( ?\(= [^)]+\))?,?/debhelper,/g" debian/control
echo "$DHRELEASE">debian/compat
# if (echo $RELEASE|grep -Eq "xenial|bionic|focal|jammy");then
#     rm -fv debian/lua5.4.dh-lua.conf || true
# fi
# vim:set et sts=4 ts=4 tw=80:
