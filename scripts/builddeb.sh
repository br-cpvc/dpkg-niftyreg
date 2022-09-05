#!/bin/bash
# postbuild script for debian package build. Must be called from the
# git base directory (not the scripts subfolder).

# terminate script if a command failes with error code other than 0
set -e

BUILD_NUMBER=$1

script_dir=$(dirname "$0")
cd ${script_dir}/..
sh ${script_dir}/compile.sh

deb_root="tmp/debian"
rm -rf ${deb_root}
mkdir -p ${deb_root}/usr/bin
cp tmp/install/bin/* ${deb_root}/usr/bin

version="1.3.9"

package="niftyreg"
maintainer="KCL-BMEIS/niftyreg <https://github.com/KCL-BMEIS/niftyreg/issues>"
arch="amd64"
depends="libstdc++6, libgomp1"

#date=`date -u +%Y%m%d`
#echo "date=$date"

#gitrev=`git rev-parse HEAD | cut -b 1-8`
gitrevfull=`git rev-parse HEAD`
gitrevnum=`git log --oneline | wc -l | tr -d ' '`
#echo "gitrev=$gitrev"

buildtimestamp=`date -u +%Y%m%d-%H%M%S`
hostname=`hostname`
echo "build machine=${hostname}"
echo "build time=${buildtimestamp}"
echo "gitrevfull=$gitrevfull"
echo "gitrevnum=$gitrevnum"

debian_revision="${gitrevnum}"
upstream_version="${version}"
echo "upstream_version=$upstream_version"
echo "debian_revision=$debian_revision"

packageversion="${upstream_version}-github${debian_revision}"
packagename="${package}_${packageversion}_${arch}"
echo "packagename=$packagename"
packagefile="${packagename}.deb"
echo "packagefile=$packagefile"

description="build machine=${hostname}, build time=${buildtimestamp}, git revision=${gitrevfull}"
if [ ! -z ${BUILD_NUMBER} ]; then
    echo "build number=${BUILD_NUMBER}"
    description="$description, build number=${BUILD_NUMBER}"
fi

installedsize=`du -s ${deb_root}/ | awk '{print $1}'`

mkdir -p ${deb_root}/DEBIAN/
#for format see: https://www.debian.org/doc/debian-policy/ch-controlfields.html
cat > ${deb_root}/DEBIAN/control << EOF |
Section: science
Priority: extra
Maintainer: $maintainer
Version: $packageversion
Package: $package
Architecture: $arch
Depends: $depends
Installed-Size: $installedsize
Description: $description
EOF

echo "Creating .deb file: $packagefile"
rm -f ${package}_*.deb
fakeroot dpkg-deb --build ${deb_root} $packagefile

echo "Package info"
dpkg -I $packagefile
