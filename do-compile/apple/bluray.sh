#! /usr/bin/env bash
#
# Copyright (C) 2021 Matt Reach<qianlongxu@gmail.com>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

THIS_DIR=$(DIRNAME=$(dirname "$0"); cd "$DIRNAME"; pwd)
cd "$THIS_DIR"

# bluray 1.5.0 switched from autotools to meson build system
# Use meson-compatible.sh for building

# iOS/tvOS 不支持 DiskArbitration（HAVE_MOUNT=0），也不使用 BDJ（USING_BDJAVA_BUILD_JAR=0）
# 这些宏定义通过 CFLAGS 传递给编译器，用于条件编译 patch 3 的代码
export CFLAGS="$MR_INIT_CFLAGS -DUSING_BDJAVA_BUILD_JAR=0 -DHAVE_MOUNT=0"

MESON_OTHER_FLAGS="-Denable_examples=false -Denable_tools=false -Denable_devtools=false -Denable_docs=false -Dbdj_jar=disabled -Dfontconfig=disabled -Dfreetype=disabled"

source ./meson-compatible.sh "$MESON_OTHER_FLAGS"
