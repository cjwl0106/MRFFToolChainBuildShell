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
# compile 子命令入口脚本（Apple 平台：iOS / macOS / tvOS）
# 遍历指定的库列表，逐个加载库配置文件并执行 any.sh：
#   1. 配置（configure / meson setup 等）
#   2. 编译（make / ninja）
#   3. 安装到产物目录
#   4. lipo 合并多架构产物（如果需要）
# ============================================================

set -e

# 当前脚本所在目录
THIS_DIR=$(DIRNAME=$(dirname "$0"); cd "$DIRNAME"; pwd)
cd "$THIS_DIR"

# 编译单个库：加载配置文件，执行 any.sh
function do_compile_a_lib()
{
    local lib_config="$1"
    lib_config=$(make_absolute_path "$lib_config")
    [[ ! -f "$lib_config" ]] && (echo "❌$lib_config config not exist, compile will stop."; exit 1;)

    echo "===[$MR_CMD $lib]===================="
    # 加载库配置文件，设置 LIB_NAME、GIT_COMMIT、LIPO_LIBS、GIT_UPSTREAM 等变量
    source "$lib_config"

    echo "LIB_NAME        : [$LIB_NAME]"
    echo "GIT_COMMIT      : [$GIT_COMMIT]"
    echo "LIPO_LIBS       : [$LIPO_LIBS]"
    echo "GIT_UPSTREAM    : [$GIT_UPSTREAM]"

    # 执行编译流程：any.sh 会根据 MR_CMD（build/clean/rebuild）执行对应操作
    ./any.sh
    if [[ $? -eq 0 ]];then
        echo "🎉  Congrats"
        echo "🚀  ${LIB_NAME} ${GIT_COMMIT} successfully $MR_CMD."
        echo
    fi
    echo "===================================="
}

function compile_libs()
{
    # 循环编译 -l 指定的所有库
    for lib in $MR_VENDOR_LIBS
    do
        do_compile_a_lib "configs/libs/${lib}.sh"
    done

    # 如果指定了自定义库配置文件，也编译它
    if [[ -n "$LIB_CONFIG_PATH" ]];then
        echo
        echo "install specific lib config : [$LIB_CONFIG_PATH]"
        do_compile_a_lib "$LIB_CONFIG_PATH"
    fi
}

# 解析子命令参数（compile 支持 -lib-config）
function parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -lib-config)
                shift
                # 指定自定义库配置文件路径（替代从 configs/libs/ 目录查找）
                LIB_CONFIG_PATH="$1"
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
echo "LIB_CONFIG_PATH:$LIB_CONFIG_PATH"
compile_libs
