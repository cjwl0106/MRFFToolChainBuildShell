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
# init 子命令入口脚本
# 遍历指定的库列表，逐个加载库配置文件并执行 init-repo.sh：
#   1. 克隆上游仓库（如果本地不存在）
#   2. 切换到指定的 git commit/tag
#   3. 应用 patch（如果配置了 PATCH_DIR）
# ============================================================

set -e

# 当前脚本所在目录
THIS_DIR=$(DIRNAME=$(dirname "$0"); cd "$DIRNAME"; pwd)
cd "$THIS_DIR"

# 解析子命令参数（init 支持 --skip-pull-base、--smart-apply、-lib-config）
function parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-pull-base)
                # 跳过拉取基础仓库（适用于离线或已有源码的场景）
                SKIP_PULL_BASE=1
            ;;
            --smart-apply)
                # 使用 git apply --reject 代替 git am 应用 patch
                # 当 patch 无法干净应用时，会生成 .rej 文件而非直接失败
                SMART_APPLY=1
            ;;
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

# 初始化单个库：加载配置文件，执行 init-repo.sh
function do_init_a_lib()
{
    local lib_config="$1"
    lib_config=$(make_absolute_path "$lib_config")
    [[ ! -f "$lib_config" ]] && (echo "❌$lib_config config not exist,init will stop.";exit 1;)
    echo "===[init $lib_config]===================="
    [[ ! -f "$lib_config" ]] && (echo "❌$lib_config config not exist,init will stop.";exit 1;)
    # 重置 PATCH_DIR，防止上一个库的配置残留
    unset PATCH_DIR
    # 加载库配置文件，设置 GIT_COMMIT、GIT_UPSTREAM、PATCH_DIR 等变量
    source "$lib_config"
    export MR_LIB_CONFIG_PATH="$lib_config"
    # 执行初始化：克隆仓库、切换 commit、应用 patch
    ./init-repo.sh
    echo "========================="
}

function main() {

    export SKIP_PULL_BASE=${SKIP_PULL_BASE:-0}
    export SMART_APPLY=${SMART_APPLY:-0}

    # 遍历 -l 指定的库列表，逐个初始化
    for lib in $MR_VENDOR_LIBS
    do
        do_init_a_lib "configs/libs/${lib}.sh"
    done

    # 如果指定了自定义库配置文件，也初始化它
    if [[ -n "$LIB_CONFIG_PATH" ]];then
        echo
        echo "init specific lib config : [$LIB_CONFIG_PATH]"
        do_init_a_lib "$LIB_CONFIG_PATH"
    fi
}

parse_args "$@"
main
