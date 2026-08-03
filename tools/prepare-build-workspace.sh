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

# ============================================================
# 构建工作区准备脚本
# 检测构建工具路径，设置构建目录结构（源码、产物、xcframework 等）。
# ============================================================

# ---------------------------
# 检测构建工具路径
# ---------------------------

# CMake：用于 meson/cmake 构建系统的库（如 freetype、harfbuzz）
export MR_CMAKE_EXECUTABLE=$(which cmake)
# Ninja：用于 dav1d 等库的构建后端
export MR_NINJA_EXECUTABLE=$(which ninja)
# Meson：用于 dav1d、harfbuzz、bluray 等库的构建系统
export MR_MESON_EXECUTABLE=$(which meson)
# Nasm：用于 dav1d 和 x264 等库的汇编编译器
export MR_NASM_EXECUTABLE=$(which nasm)
# pkg-config：用于 FFmpeg configure 检测第三方库
export MR_PKG_CONFIG_EXECUTABLE=$(which pkg-config)
# 在 Intel Mac 交叉编译 arm64 的 harfbuzz 时，pkg-config 可能找不到，显式指定路径
export PKG_CONFIG=$(which pkg-config)

# ---------------------------
# 设置构建目录结构
# ---------------------------

# 默认工作区目录为 FFToolChain/build
if [[ -z "$MR_WORKSPACE" ]];then
    THIS_DIR=$(DIRNAME=$(dirname "${BASH_SOURCE[0]}"); cd "${DIRNAME}/../"; pwd)
    export MR_WORKSPACE="${THIS_DIR}/build"
fi

# 源码根目录：存放克隆下来的库源码（如 build/src/ios/ffmpeg8-arm64/）
export MR_SRC_ROOT="${MR_WORKSPACE}/src/${MR_PLAT}"
# 产物根目录：存放编译产物（如 build/product/ios/ffmpeg-arm64/）
export MR_PRODUCT_ROOT="${MR_WORKSPACE}/product/${MR_PLAT}"
# xcframework 输出目录
export MR_XCFRMK_DIR="${MR_WORKSPACE}/product/xcframework"
# 各平台产物根目录（用于 lipo 合并时引用其他平台的产物）
export MR_IOS_PRODUCT_ROOT="${MR_WORKSPACE}/product/ios"
export MR_MACOS_PRODUCT_ROOT="${MR_WORKSPACE}/product/macos"
export MR_TVOS_PRODUCT_ROOT="${MR_WORKSPACE}/product/tvos"
# 真机 universal 产物目录（lipo 合并后的产物）
export MR_UNI_PROD_DIR="${MR_PRODUCT_ROOT}/universal"
# 模拟器 universal 产物目录
export MR_UNI_SIM_PROD_DIR="${MR_PRODUCT_ROOT}/universal-simulator"

# 打印关键目录路径
echo "MR_SRC_ROOT    : [$MR_SRC_ROOT]"
echo "MR_PRODUCT_ROOT: [$MR_PRODUCT_ROOT]"
echo "MR_UNI_PROD_DIR: [$MR_UNI_PROD_DIR]"
echo "MR_UNI_SIM_PROD_DIR: [$MR_UNI_SIM_PROD_DIR]"
