#!/bin/bash
set -e

readonly shell_path=$(cd $(dirname $0); pwd)
readonly root_build_dir="${shell_path}/../../../.."
readonly rust_source_dir="${shell_path}/.."
readonly rust_tools="${root_build_dir}/prebuilts"
readonly install_path="${rust_source_dir}/build/dist"
readonly output_install="${root_build_dir}/output/"
readonly rust_static_dir="${root_build_dir}/rust_download"
readonly oh_tools="${rust_tools}/ohos-sdk/linux/12/native/llvm/bin"
readonly mingw_tools="${rust_tools}/mingw-w64/ohos/linux-x86_64/clang-mingw/bin"
readonly old_version="xxxxx"
new_version="xxxxx"

source ${shell_path}/function.sh

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
        cp ${install_path}/rust-nightly-x86_64-unknown-linux-gnu.tar.gz ${output_install}/
        cp ${install_path}/rust-std-nightly-x86_64-pc-windows-gnullvm.tar.gz ${output_install}/
        cp ${install_path}/rust-std-nightly-aarch64-unknown-linux-ohos.tar.gz ${output_install}/
        cp ${install_path}/rust-std-nightly-armv7-unknown-linux-ohos.tar.gz ${output_install}/
        cp ${install_path}/rust-std-nightly-x86_64-unknown-linux-ohos.tar.gz ${output_install}/
    elif [ "${host_platform}" = "darwin" ] && [ ${host_cpu} = "x86_64" ]; then
        cp ${install_path}/rust-nightly-x86_64-apple-darwin.tar.gz ${output_install}/
    elif [ "${host_platform}" = "darwin" ] && [ ${host_cpu} = "arm64" ]; then
        cp ${install_path}/rust-nightly-aarch64-apple-darwin.tar.gz ${output_install}/
    fi
}

main() {
    detect_platform
    rm -rf ${rust_source_dir}/build/*
    download_rust_at_net
    copy_config
    update_config_clang ${oh_tools} ${mingw_tools}
    get_new_version
    update_version
    move_static_rust_source ${rust_static_dir} ${rust_source_dir}

    rm -rf ${rust_source_dir}/src/llvm-project/*
    cp -r ${root_build_dir}/../harmony/llvm/* ${rust_source_dir}/src/llvm-project/

    pushd ${rust_source_dir}
    export_ohos_path

    python3 ./x.py dist
    collect_build_result
    if [ "${host_platform}" = "linux" ]; then
        check_build_result aarch64-unknown-linux-ohos
    fi
    popd
    echo "Building the rust toolchain Completed"
}

main
