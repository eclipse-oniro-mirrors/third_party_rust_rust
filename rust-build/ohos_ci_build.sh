#!/bin/bash
set -e

readonly shell_path=$(cd $(dirname $0); pwd)
readonly root_build_dir="${shell_path}/../../../.."
readonly rust_source_dir="${shell_path}/.."
readonly rust_tools="${root_build_dir}/prebuilts"
readonly output_install="${root_build_dir}/output/"
readonly rust_static_dir="${root_build_dir}/rust_download"
readonly oh_tools="${rust_tools}/ohos-sdk/linux/12/native/llvm/bin"
readonly mingw_tools="${rust_tools}/mingw-w64/ohos/linux-x86_64/clang-mingw/bin"
readonly old_version="xxxxx"
new_version="xxxxx"

source ${shell_path}/function.sh

download_rust_static_source() {
    local pre_rust_date="2023-07-13"
    mkdir -p ${rust_static_dir} ${rust_source_dir}/build/cache/${pre_rust_date}
    local rust_down_net="https://mirrors.ustc.edu.cn/rust-static/dist"
    pushd ${rust_static_dir}
    local platform=$1
    local cpu=$2
    local files=("rust-std-1.71.0-${cpu}-${platform}.tar.xz" "rustc-1.71.0-${cpu}-${platform}.tar.xz" "cargo-1.71.0-${cpu}-${platform}.tar.xz")

    for file in "${files[@]}"; do
        curl -O -k -m 300 ${rust_down_net}/${pre_rust_date}/${file} &
    done
    curl -O -k -m 300 ${rust_down_net}/rustc-1.72.0-src.tar.gz &
    wait
    popd
    cp ${rust_static_dir}/*.tar.xz ${rust_source_dir}/build/cache/${pre_rust_date}/
    cp ${rust_static_dir}/rustc-1.72.0-src.tar.gz ${root_build_dir}
}

download_rust() {
    if [ "${host_platform}" = "linux" ] && [ "${host_cpu}" = "x86_64" ]; then
        download_rust_static_source "unknown-linux-gnu" "x86_64"
    elif [ "${host_platform}" = "darwin" ]; then
        if [ "${host_cpu}" = "x86_64" ]; then
            download_rust_static_source "apple-darwin" "x86_64"
        else
            download_rust_static_source "apple-darwin" "aarch64"
        fi
    else
        echo "Unsupported platform: $(uname -s) $(uname -m)"
        exit 1
    fi
}

get_new_version() {
    pushd ${root_build_dir}/../harmony/llvm/
    local commit_id_full=$(git rev-parse HEAD)
    local commit_id_short=${commit_id_full:1:10}
    new_version="OHOS llvm-preject $commit_id_short"
    popd
}

collect_build_result() {
    mkdir -p ${output_install}
    if [ "${host_platform}" = "linux" ] && [ ${host_cpu} = "x86_64" ]; then
        cp ${rust_source_dir}/build/dist/rust-nightly-x86_64-unknown-linux-gnu.tar.gz ${output_install}/
        cp ${rust_source_dir}/build/dist/rust-std-nightly-x86_64-pc-windows-gnullvm.tar.gz ${output_install}/
        cp ${rust_source_dir}/build/dist/rust-std-nightly-aarch64-unknown-linux-ohos.tar.gz ${output_install}/
        cp ${rust_source_dir}/build/dist/rust-std-nightly-armv7-unknown-linux-ohos.tar.gz ${output_install}/
        cp ${rust_source_dir}/build/dist/rust-std-nightly-x86_64-unknown-linux-ohos.tar.gz ${output_install}/
    elif [ "${host_platform}" = "darwin" ] && [ ${host_cpu} = "x86_64" ]; then
        cp ${rust_source_dir}/build/dist/rust-nightly-x86_64-apple-darwin.tar.gz ${output_install}/
    elif [ "${host_platform}" = "darwin" ] && [ ${host_cpu} = "arm64" ]; then
        cp ${rust_source_dir}/build/dist/rust-nightly-aarch64-apple-darwin.tar.gz ${output_install}/
    fi
}

main() {
    detect_platform
    download_rust
    copy_config
    update_config_clang ${oh_tools} ${mingw_tools}
    get_new_version
    update_version
    move_static_rust_source ${rust_static_dir} ${rust_source_dir}

    rm -rf ${rust_source_dir}/src/llvm-project/*
    cp -r ${root_build_dir}/../harmony/llvm/* ${rust_source_dir}/src/llvm-project/

    pushd ${rust_source_dir}
    if [ "${host_platform}" = "linux" ]; then
        export PATH=${rust_tools}/cmake/linux-x86/bin:${rust_tools}/clang/ohos/linux-x86_64/llvm/bin:$PATH
    fi
    python3 ./x.py dist
    popd

    collect_build_result

    echo "Building the rust toolchain Completed"
}

main
