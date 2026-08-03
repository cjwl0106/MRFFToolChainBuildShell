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

set -e

# 当前脚本所在目录（FFToolChain 根目录）
THIS_DIR=$(DIRNAME=$(dirname "$0"); cd "$DIRNAME"; pwd)
cd "$THIS_DIR"

# 导出全局环境变量，供子脚本使用
export    MR_SHELL_ROOT_DIR="$THIS_DIR"                          # FFToolChain 根目录
export   MR_SHELL_TOOLS_DIR="${THIS_DIR}/tools"                 # 工具脚本目录（parse-arguments.sh 等）
export          MR_GAS_PERL=${MR_SHELL_TOOLS_DIR}/gas-preprocessor.pl  # ARM 汇编预处理器
export MR_SHELL_CONFIGS_DIR="${THIS_DIR}/configs"               # 库配置文件目录

# 计时函数：输出本次执行耗时
function elapsed()
{
    local END_STMP=$(date +%s)
    local take=$(( END_STMP - START_STMP ))
    echo "===================================="
    echo time elapsed ${take} s.
}

# 记录开始时间
START_STMP=$(date +%s)

# Step 1: 解析命令行参数（-p 平台、-a 架构、-l 库列表、-c 编译模式等）
# 解析结果存入 MR_ACTION、MR_PLAT、MR_VENDOR_LIBS 等变量
echo '---1.parse arguments---------------------------------------'
source $MR_SHELL_TOOLS_DIR/parse-arguments.sh
echo '--------------------'
echo

# Step 2: 准备构建工作区（创建目录结构、设置构建路径等）
echo '---2.prepare build workspace-------------------------------'
source $MR_SHELL_TOOLS_DIR/prepare-build-workspace.sh
echo '--------------------'
echo

# Step 3: 根据操作类型分发到对应的子脚本执行
echo "---3.do $MR_ACTION-------------------------------"

# 将平台名映射到子目录名：Apple 平台统一用 apple，Android 用 android
case $MR_PLAT in
    ios | macos | tvos)
        plat=apple
    ;;
    android)
        plat=android
    ;;
esac

# init 和 install 不区分平台，直接路由到 do-init/main.sh 或 do-install/main.sh
# compile 等操作需要区分平台，路由到 do-compile/apple/main.sh 或 do-compile/android/main.sh
if [[ "$MR_ACTION" == "init" || "$MR_ACTION" == "install" ]];then
    ./do-$MR_ACTION/main.sh "${MR_UNKNOWN_OPTIONS[@]}"
else
    ./do-$MR_ACTION/$plat/main.sh "${MR_UNKNOWN_OPTIONS[@]}"
fi

echo "---$MR_ACTION end-------------------------------"
elapsed
