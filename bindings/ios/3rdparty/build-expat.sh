#!/bin/sh

EXPAT_VERSION="2.1.1"
SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`

##############################################
CURRENTPATH=`pwd`
OPENSSL_PREFIX="${CURRENTPATH}"
ARCHS="i386 x86_64 armv7 armv7s arm64"
DEVELOPER=`xcode-select -print-path`

if [ ! -d "$DEVELOPER" ]; then
  echo "xcode path is not set correctly $DEVELOPER does not exist (most likely because of xcode > 4.3)"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

case $DEVELOPER in
     *\ * )
           echo "Your Xcode path contains whitespaces, which is not supported."
           exit 1
          ;;
esac

case $CURRENTPATH in
     *\ * )
           echo "Your path contains whitespaces, which is not supported by 'make install'."
           exit 1
          ;;
esac

set -e

if [ ! -e "expat-${EXPAT_VERSION}.tar.bz2" ]
then
wget "http://downloads.sourceforge.net/project/expat/expat/2.1.1/expat-${EXPAT_VERSION}.tar.bz2"
fi

for ARCH in ${ARCHS}
do
if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
then
PLATFORM="iPhoneSimulator"
else
PLATFORM="iPhoneOS"
fi

rm -rf expat-${EXPAT_VERSION}
tar zxf expat-${EXPAT_VERSION}.tar.bz2
pushd "expat-${EXPAT_VERSION}"

export BUILD_TOOLS="${DEVELOPER}"
export BUILD_DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export BUILD_SDKROOT="${BUILD_DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"

export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

# Build
export LDFLAGS="-Os -arch ${ARCH} -Wl,-dead_strip -miphoneos-version-min=7.0 -L${BUILD_SDKROOT}/usr/lib"
export CFLAGS="-Os -arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${BUILD_SDKROOT} -miphoneos-version-min=7.0 -Wno-implicit-function-declaration"
export CPPFLAGS="${CFLAGS} -I${BUILD_SDKROOT}/usr/include"
export CXXFLAGS="${CPPFLAGS}"

if [ "${ARCH}" == "arm64" ]; then
./configure --host=aarch64-apple-darwin --enable-static --disable-shared
else
./configure --host=${ARCH}-apple-darwin --enable-static --disable-shared
fi

make -j8
cp -f .libs/libexpat.a ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/
#make clean

popd

done


mkdir lib || true
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/libexpat.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/libexpat.a  ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/libexpat.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/libexpat.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/libexpat.a -output ${CURRENTPATH}/lib/libexpat.a

mkdir -p include/expat || true
cp -f expat-${EXPAT_VERSION}/lib/*.h include/expat/

rm -rf bin
rm -rf expat-${EXPAT_VERSION}
rm -rf expat-${EXPAT_VERSION}.tar.bz2


echo "Done."
