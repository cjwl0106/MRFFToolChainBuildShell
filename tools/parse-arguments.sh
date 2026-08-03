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
# 命令行参数解析脚本
# 解析 ./main.sh 的命令行参数，提取操作类型、平台、架构、库列表等，
# 并导出为全局环境变量供后续脚本使用。
# ============================================================

set -e

# ---------------------------
# 帮助信息
# ---------------------------

# 主帮助信息
function main_usage()
{
cat << EOF
usage: ./main.sh [options]

compile fsplayer using libs for iOS、macOS、tvOS、Android platform, such as ass、ffmpeg...

Commands:
   +help         Show help banner of specified command
   +init         Clone vendor library git repository,Checkout specify commit,Apply patches
   +compile      Compile vendor library,more parameter see ./main.sh compile -h
   +install      Download and Install Pre-compile library to product dir
EOF
}

# init 子命令帮助信息
function init_usage()
{
cat << EOF
usage: ./main.sh init [options]

Clone vendor library git repository,Checkout specify commit,Apply patches

OPTIONS:
    -p                   Specify platform (ios,macos,tvos,android), can't be nil
    -a                   Specify archs (x86_64,arm64,x86_64_simulator,arm64_simulator,all) all="x86_64,arm64,x86_64_simulator,arm64_simulator"
    -l                   Specify which libs need init (libyuv|openssl|openssl3|opus|bluray|dav1d|dvdread|freetype|fribidi|harfbuzz|unibreak|ass|ijkffmpeg|fftutorial|ffmpeg4|ffmpeg5|ffmpeg6|ffmpeg7), can't be nil
    -s                   Specify workspace dir
    --help               Show help banner of init command
    --skip-pull-base     Skip pull base repo
    --smart-apply        Apply patches with git apply --reject instead of git am
    -lib-config          Read library config from specified path,eg: -lib-path ~/matt/lib/ffmpeg.sh
EOF
}

# compile 子命令帮助信息
function compile_usage()
{
cat << EOF
usage: ./main.sh compile [options]

Compile libs, such as ass、ffmpeg...

OPTIONS:
    -c                  Specify sub command (build,clean,rebuild) rebuild=clean+build, default is build
    -a                  Specify archs (x86_64,arm64,x86_64_simulator,arm64_simulator,all) all="x86_64,arm64,x86_64_simulator,arm64_simulator"
    -l                  Specify which libs need 'cmd' (openssl|opus|bluray|dav1d|dvdread|freetype|fribidi|harfbuzz|unibreak|ass|ffmpeg), can't be nil
    -s                  Specify workspace dir
    -j                  Force number of cores to be used
    -lib-config         Read library config from specified path,eg: -lib-path ~/matt/lib/ffmpeg.sh
    --help              Show help banner of compile command
    --debug             Enable debug mode (disable by default)
    --fmwk              Make xcframework(apple platform only)
EOF
}

# install 子命令帮助信息
function install_usage()
{
cat << EOF
usage: ./main.sh install [options]

Download and Install Pre-compile library to product dir

OPTIONS:
   -p            Specify platform (ios,macos,tvos), can't be nil
   -l            Specify which libs need 'cmd' (libyuv|openssl|opus|bluray|dav1d|dvdread|freetype|fribidi|harfbuzz|unibreak|ass|ffmpeg), can't be nil
   -s            Specify workspace dir
   --help        Show intall help
   --fmwk        Install xcframework bundle instead of .a
   -lib-config   Read library config from specified path,eg: -lib-path ~/matt/lib/ffmpeg.sh
   -correct-pc   Specify a path for correct the pc file prefix recursion
EOF
}

# ---------------------------
# 工具函数
# ---------------------------

# 将相对路径转为绝对路径（相对于 FFToolChain 根目录）
function parse_path()
{
    local p="$1"
    if [[ $p == /* ]]; then
        echo $(cd "$p"; pwd)
    else
        local dir="$MR_SHELL_ROOT_DIR/$p"
        echo $(mkdir -p "$dir";cd "$dir";pwd)
    fi
}

# 断言环境变量不为空，为空则报错退出
function env_assert()
{
    name="$1"
    value=$(eval echo "\$$name")
    if [[ "x$value" == "x" ]]; then
        echo "$name is nil,eg: export $name=xx" >&2
        exit 1
    else
        echo "$name : [${value}]" >&2
    fi
}

# 打印环境变量值（不强制要求非空）
function echo_env()
{
    name="$1"
    value=$(eval echo "\$$name")
    if [[ -n "$value" ]]; then
        echo "$name : [${value}]" >&2
    fi
}

# 将相对路径转为绝对路径（保留文件名部分），用于库配置文件路径
function make_absolute_path()
{
    local p="$1"
    if [[ $p == /* ]]; then
        echo "$(cd "$(dirname "$p")" && pwd)/$(basename "$p")"
    else
        echo "$(cd "$(dirname "$MR_SHELL_ROOT_DIR/$p")" && pwd)/$(basename "$p")"
    fi
}

# 导出工具函数，使其在子 shell 中可用
export -f env_assert
export -f echo_env
export -f make_absolute_path

# 根据操作类型显示对应的帮助信息
function help()
{
    eval ${MR_ACTION}_usage
}

# ---------------------------
# 解析命令行参数
# ---------------------------

# 初始化变量
action=
cmd=
platform=
arch=
libs=
workspace=
debug=
has_lib_config=
MR_UNKNOWN_OPTIONS=()

# 第一个参数为操作类型：init / install / compile
# compile 默认子命令为 build
case $1 in
    init | install)
        action=$1
        shift 1
    ;;
    compile)
        action=$1
        shift 1
        cmd=build
    ;;
    *)
        main_usage
        exit 0
    ;;
esac

# 导出操作类型
export MR_ACTION=$action

# 解析后续参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -p)                     # 指定平台 (ios/macos/tvos/android)
            shift
            platform="$1"
        ;;
        -c)                     # 指定子命令 (build/clean/rebuild)
            shift
            cmd="$1"
        ;;
        -a)                     # 指定架构 (arm64/x86_64 等)
            shift
            arch="$1"
        ;;
        -l)                     # 指定要操作的库列表
            shift
            libs="$1"
        ;;
        -s)                     # 指定工作区目录
            shift
            workspace=$(parse_path "$1")
        ;;
        -j)                     # 指定编译使用的核心数
            shift
            nproc="$1"
        ;;
        --help)                 # 显示帮助
            help
            exit 0
        ;;
        --debug)                # 启用调试模式
            export MR_DEBUG='debug'
        ;;
        --fmwk)                 # 生成 xcframework（仅 Apple 平台）
            export MR_MAKE_XCFRAMEWORK=1
        ;;
        -lib-config)            # 指定自定义库配置文件路径
            MR_UNKNOWN_OPTIONS+=("$1")
            has_lib_config=1
        ;;
        -correct-pc)            # 修正 pkgconfig 文件前缀
            MR_UNKNOWN_OPTIONS+=("$1")
            has_correct_pc=1
        ;;
        *)                      # 其他未知参数，透传给子脚本
            MR_UNKNOWN_OPTIONS+=("$1")
        ;;
    esac
    shift
done

# ---------------------------
# 参数校验
# ---------------------------

# 平台不能为空
if [[ -z "$platform" ]];then
    echo "platform can't empty"
    help
    exit 1
fi

# 平台必须是支持的值
if [[ "$platform" != 'ios' && "$platform" != 'macos' && "$platform" != 'tvos' && "$platform" != 'android' ]]; then
    echo "platform must be: [ios|macos|tvos|android]"
    exit 1
fi

# 库列表不能为空（除非指定了 -lib-config 或 -correct-pc）
if [[ -z "$libs" && "$has_lib_config" != "1" && "$has_correct_pc" != "1" ]];then
    echo "libs can't be nil, use -l specify libs"
    exit 1
fi

# 覆盖编译核心数
if [[ -n "$nproc" ]];then
    echo "override thread count:$nproc"
    export MR_HOST_NPROC=$nproc
fi

# ---------------------------
# 设置编译 CFLAGS
# ---------------------------

# 通用警告抑制选项（兼容旧 C 语法）
cflags="-Wno-incompatible-function-pointer-types -Wno-int-conversion -Wno-declaration-after-statement -Wno-unused-function"

if [[ "$MR_DEBUG" == "debug" ]];then
    export MR_INIT_CFLAGS="-g -O0 -D_DEBUG $cflags"
else
    export MR_INIT_CFLAGS="-O3 -DNDEBUG $cflags"
fi

# ---------------------------
# 导出全局环境变量
# ---------------------------

export MR_PLAT="$platform"              # 目标平台
export MR_CMD="$cmd"                    # 子命令 (build/clean/rebuild)
export MR_VENDOR_LIBS="$libs"           # 要操作的库列表
export MR_ACTIVE_ARCHS="$arch"          # 目标架构

# 覆盖工作区目录
if [[ "$workspace" ]];then
    export MR_WORKSPACE="$workspace"
    echo "MR_WORKSPACE:$MR_WORKSPACE"
fi

# ---------------------------
# 加载平台相关的环境变量
# ---------------------------

case $MR_PLAT in
    ios | macos | tvos)
        source $MR_SHELL_TOOLS_DIR/export-apple-host-env.sh
    ;;
    android)
        source $MR_SHELL_TOOLS_DIR/export-android-host-env.sh
    ;;
    *)
        echo "wrong platform $MR_PLAT"
        exit 1
    ;;
esac

# ---------------------------
# 校验架构参数
# ---------------------------

# 如果未指定架构，使用平台默认架构
if [[ -z "$MR_ACTIVE_ARCHS" ]];then
    export MR_ACTIVE_ARCHS=$MR_DEFAULT_ARCHS
else
    # 校验指定的架构是否在平台支持的架构列表中
    for arch in $MR_ACTIVE_ARCHS
    do
        validate=0
        for arch2 in $MR_DEFAULT_ARCHS
        do
            if [[ $arch == $arch2 ]];then
                validate=1
            fi
        done
        if [[ $validate -eq 0 ]];then
            echo "the $arch is not validate on ${MR_PLAT},you can use [$MR_DEFAULT_ARCHS]"
            exit 1
        fi
    done
fi

# ---------------------------
# 打印解析结果
# ---------------------------

echo "MR_ACTION       : [$MR_ACTION]"
echo "MR_PLAT         : [$MR_PLAT]"
echo "MR_CMD          : [$MR_CMD]"
echo "MR_VENDOR_LIBS  : [$MR_VENDOR_LIBS]"
echo "MR_ACTIVE_ARCHS : [$MR_ACTIVE_ARCHS]"
echo "MR_HOST_NPROC   : [$MR_HOST_NPROC]"
echo "MR_DEBUG        : [$MR_DEBUG]"
echo "MR_INIT_CFLAGS  : [$MR_INIT_CFLAGS]"
echo "MR_MAKE_XCFRAMEWORK" : [$MR_MAKE_XCFRAMEWORK]
[[ ${#MR_UNKNOWN_OPTIONS[@]} -gt 0 ]] && echo "MR_UNKNOWN_OPTIONS : [${MR_UNKNOWN_OPTIONS[*]}]"

# 清理局部变量，避免污染环境
unset platform cmd arch libs workspace debug action cflags
