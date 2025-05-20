#!/usr/bin/env bash
set -ex
cd "$(dirname $0)/.."
export W="${PWD}"
export ONLY_REUPLOAD=${ONLY_REUPLOAD-}
export GPG_AGENT_INFO=${GPG_AGENT_INFO:-${HOME}/.gnupg/S.gpg-agent:0:1}
export PACKAGE="libnginx-mod-http-lua"
export PPA="${PACKAGE}"
export PPA="nginx"
export PPASUFFIX="ppa-${PPA}-"
export REPO="https://salsa.debian.org/nginx-team/libnginx-mod-http-lua.git"
export DEBEMAIL=${DEBEMAIL:-freesoftware@makina-corpus.com}
export KEY="${KEY:-0x2B8CDBC4533B8C52}"
export UPSTREAM_W="${W}/../${PACKAGE}-upstream"
export FLAVORS="bionic focal jammy"
export RELEASES="${RELEASES:-"experimental|(un)?stable|precise|trusty|utopic|vivid|oneric|wily|xenial|artful|bionic|disco|focal|jammy|impish|hirsute|groovy|kinetic|UNRELEASED"}"
export VERSION_PARSER="\\(([0-9]+([.-][0-9]+)+)(${PPASUFFIX}[0-9]+|[^)]+)?\\)"
export VER=${VER:-"$(head -n1 debian/changelog|awk '{print$2}'|sed -re "s/$VERSION_PARSER/\1/g")"}
if [ "x${VER}" = "x" ];then echo unknownversion;exit -1;fi
export DEBIAN_REMOTE=origin/master

gitrco() { git reset -- $@;git checkout -- $@; }
if [[ -z $ONLY_REUPLOAD ]];then
if [[ -z ${NO_SYNC-} ]];then
if [ "x${REPO}" != "x" ];then
    if [ ! -e "${UPSTREAM_W}" ];then
        git clone "${REPO}" "${UPSTREAM_W}";
    fi
    cd "${UPSTREAM_W}" \
    && git remote rm origin \
    && git remote add origin "$REPO" \
    && rm -rf * && git fetch --all && git reset --hard $DEBIAN_REMOTE
    rsync -av --delete --exclude="*.makina.*" \
        --exclude=po/\
        --exclude=changelog\
        "${UPSTREAM_W}/debian/" "${W}/debian/"
fi
if [ -e "${W}/mc_packaging/debian/" ];then
    rsync -av "${W}/mc_packaging/debian/" "${W}/debian/"
fi
fi
#
# CUSTOM MERGE CODE HERE
# <>
cd "${W}"
cd "${W}/debian"
echo "3.0 (native)">"${W}/debian/source/format"
fi
cd "${W}"
CHANGES=""
if [ -e $HOME/.gnupg/.gpg-agent-info ];then . $HOME/.gnupg/.gpg-agent-info;fi
# make a release for each flavor
if [[ -z ${NO_UPLOAD-} ]];then
logfile=$W/../log
if [ -e "${logfile}" ];then rm -f "${logfile}";fi
if [ -e "${logfile}.pipe" ];then rm -f "${logfile}.pipe";fi
mkfifo "${logfile}.pipe"
tee < "${logfile}.pipe" "$logfile" &
exec 1> "${logfile}.pipe" 2> "${logfile}.pipe"
for i in $FLAVORS;do
    sed -i -r \
        -e "1 s/$PACKAGE $VERSION_PARSER (${RELEASES});/$PACKAGE (\1\3) $i;/g" \
        -e "1 s/${PPASUFFIX}\)/${PPASUFFIX}1)/g" \
        debian/changelog
    # head -n 1 debian/changelog;exit 1
    "$W/mc_packaging/debian_compat.sh" $i
    dch --upstream -D "${i}" "packaging for ${i}" -l "$PPASUFFIX"
    debuild --no-tgz-check -k${KEY} -S -sa --lintian-opts -i
done
exec 1>&1 2>&2
rm "${logfile}.pipe"
CHANGES=$(egrep "signfile.* dsc " $logfile|awk '{print $3}'|sed -re "s/\.dsc$/_source.changes/g" )
rm -f $logfile
# upload to final PPA
    cd "${W}"
    for i in ${CHANGES};do dput "${PPA}" "../${i}";done
fi
# vim:set et sts=4 ts=4 tw=0:
