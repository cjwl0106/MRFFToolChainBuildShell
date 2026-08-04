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
#

# ============================================================
# install 子命令入口脚本
# 下载预编译包并安装到产物目录。
#
# ⚠️ 注意：LGPL 构建流程中不要使用此命令！
# install 会下载预编译包，覆盖本地编译的 LGPLv3 产物。
# LGPL 构建应使用手动 lipo 方式（见 BUILD_GUIDE.md Step 5）。
# ============================================================

set -e

# 当前脚本所在目录
THIS_DIR=$(DIRNAME=$(dirname "$0"); cd "$DIRNAME"; pwd)
cd "$THIS_DIR"

# 解析库配置文件中的预编译 tag 信息
# 从 PRE_COMPILE_TAG 中提取版本号，用于拼接下载 URL
function parse_lib_config() {
    local lib_config="$1"
    local config_file_name=$(basename "$lib_config")
    while [[ -L "$lib_config" ]]; do
        local target=$(readlink "$lib_config")
        if [[ "$target" == /* ]]; then
            lib_config="$target"
        else
            local dir=$(dirname "$lib_config")
            lib_config="$dir/$target"
        fi
        config_file_name=$(basename "$lib_config")
    done
    local config_name=${config_file_name%.sh}

    # 获取当前平台对应的 PRE_COMPILE_TAG（如 PRE_COMPILE_TAG_IOS）
    local t=$(echo "PRE_COMPILE_TAG_$MR_PLAT" | tr '[:lower:]' '[:upper:]')
    local vt=$(eval echo "\$$t")

    if test -z $vt ;then
        echo "$t can't be nil"
        exit
    fi

    # PRE_COMPILE_TAG 格式示例：opus-1.3.1-231124151836
    # TAG = 完整 tag，VER = 版本号部分
    export TAG=$vt

    local prefix="${config_name}-"
    local suffix=$(echo $TAG | awk -F - '{printf "-%s", $NF}')
    # 去掉前缀（库名）
    local temp=${TAG#$prefix}
    # 去掉后缀（时间戳），得到版本号
    export VER=${temp%$suffix}
    # 库名字取配置文件名（与 onestep.sh 保持一致）
    export LIB_NAME="$config_name"
}

# 安装单个库的预编译包
function do_install_a_lib()
{
    local lib_config="$1"
    lib_config=$(make_absolute_path "$lib_config")
    [[ ! -f "$lib_config" ]] && (echo "❌$lib_config config not exist,install will stop."; exit 1;)

    echo "===[install $lib_config]===================="
    # 加载库配置文件，获取 PRE_COMPILE_TAG 等变量
    source "$lib_config"
    # 解析预编译 tag，提取版本号
    parse_lib_config "$lib_config"
    # 根据是否指定 --fmwk 选择安装方式
    if [[ $FORCE_XCFRAMEWORK ]];then
        # 安装预编译 xcframework
        ./install-pre-xcf.sh
    else
        # 安装预编译 .a 库文件
        ./install-pre-lib.sh
    fi
    echo "===================================="
}

function install_libs()
{
    # 循环安装 -l 指定的所有库
    for lib in $MR_VENDOR_LIBS
    do
        do_install_a_lib "configs/libs/${lib}.sh"
    done

    # 如果指定了自定义库配置文件，也安装它
    if [[ -n "$LIB_CONFIG_PATH" ]];then
        echo
        echo "install specific lib config : [$LIB_CONFIG_PATH]"
        do_install_a_lib "$LIB_CONFIG_PATH"
    fi
}

# 解析子命令参数
function parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -lib-config)
                shift
                # 指定自定义库配置文件路径
                LIB_CONFIG_PATH="$1"
            ;;
            -correct-pc)
                shift
                # 修正 pkgconfig 文件中的 prefix 路径
                CORRECT_PC="$1"
            ;;
            *)
                echo "unknown option: $1"
                sleep 2
                ;;
        esac
        shift
    done
}

parse_args "$@"

# 如果指定了 -correct-pc，只修正 pkgconfig 文件，不执行安装
if [[ -n "$CORRECT_PC" ]];then
    echo "correct pc file : [$CORRECT_PC]"
    ./correct-pc.sh "$CORRECT_PC"
else
    install_libs
fi
