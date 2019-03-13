#!/usr/bin/env bash
#
# Copyright 2015-2019 OpenIndex.de
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# -----------------------------------------------------------------------
#
# Build a runtime environment for Linux 32-bit x86 (i686).
#
# OpenJDK for this target platform is taken from
# https://www.azul.com/downloads/zulu/
#
# -----------------------------------------------------------------------

TARGET="linux32"
TARGET_JDK="https://cdn.azul.com/zulu/bin/zulu10.3+5-jdk10.0.2-linux_i686.tar.gz"
#TARGET_JDK="https://github.com/OpenIndex/openjdk-linux-x86/releases/download/jdk-11.0.2%2B9/jdk-11.0.2+9-jre-linux-x86.tar.gz"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOWNLOADS_DIR="$DIR/downloads"
LOCAL_DIR="$DIR/local"
TEMP_DIR="$DIR/temp"


#
# initialization
#

set -e
source "$DIR/init.sh"
rm -Rf "$DIR/jmods/$TARGET"
mkdir -p "$DIR/jmods"
mkdir -p "$LOCAL_DIR"


#
# download OpenJDK binaries
#

mkdir -p "$DOWNLOADS_DIR"
cd "$DOWNLOADS_DIR"

if [ ! -f "$DOWNLOADS_DIR/$(basename ${TARGET_JDK})" ]; then
    echo "Downloading OpenJDK for $TARGET..."
    #wget -nc "$TARGET_JDK"
    curl -L \
      -o "$(basename ${TARGET_JDK})" \
      "$TARGET_JDK"
fi

if [ ! -f "$DOWNLOADS_DIR/$(basename ${SYSTEM_JDK})" ]; then
    echo "Downloading OpenJDK for jlink..."
    #wget -nc "$SYSTEM_JDK"
    curl -L \
      -o "$(basename ${SYSTEM_JDK})" \
      "$SYSTEM_JDK"
fi


#
# extract OpenJDK modules
#

echo "Extracting OpenJDK modules for $TARGET..."
rm -Rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
tar xfz "$DOWNLOADS_DIR/$(basename "$TARGET_JDK")"
mv "$(ls -1)/jmods" "$DIR/jmods/$TARGET"


#
# extract OpenJDK for jlink
#

echo "Extracting OpenJDK for jlink..."
SYSTEM_JDK_DIR="$LOCAL_DIR/$(basename "$SYSTEM_JDK")"
if [ ! -d "$SYSTEM_JDK_DIR" ]; then
    mkdir -p "$SYSTEM_JDK_DIR"
    cd "$SYSTEM_JDK_DIR"
    tar xfz "$DOWNLOADS_DIR/$(basename "$SYSTEM_JDK")"
fi
cd "$SYSTEM_JDK_DIR"
JLINK="$SYSTEM_JDK_DIR/$(ls -1)/bin/jlink"


#
# build OpenJDK runtime
#

rm -Rf "$DIR/runtime/$TARGET"
mkdir -p "$DIR/runtime"

echo "Building runtime environment for $TARGET..."
"$JLINK" \
    -p "$DIR/jmods/$TARGET" \
    --add-modules "java.desktop,java.naming" \
    --output "$DIR/runtime/$TARGET" \
    --compress=2 \
    --strip-debug \
    --no-header-files \
    --no-man-pages


#
# cleanup
#

cd "$DIR"
rm -Rf "$TEMP_DIR"
