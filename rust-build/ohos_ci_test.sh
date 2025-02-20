#!/bin/bash
set -e

readonly shell_path=$(cd $(dirname $0); pwd)
readonly root_build_dir="${shell_path}/../../../.."
readonly rust_source_dir="${shell_path}/.."
readonly rust_tools="${root_build_dir}/prebuilts"
readonly rust_static_dir="${root_build_dir}/rust_download"
readonly oh_tools="${rust_tools}/ohos-sdk/linux/12/native/llvm/bin"
readonly mingw_tools="${rust_tools}/mingw-w64/ohos/linux-x86_64/clang-mingw/bin"
readonly musl_head_file_path="${root_build_dir}/third_party/musl/include/linux"
exclude_file=""
all_test_suite=""

source ${shell_path}/function.sh

main() {
    detect_platform
    rm -rf ${rust_source_dir}/build/*
    download_rust_at_net
    copy_config
    update_config_clang ${oh_tools} ${mingw_tools} ${musl_head_file_path}
    sed -i "s/target = .*/target = [\"x86_64-unknown-linux-gnu\"]/g" ${rust_source_dir}/config.toml
    move_static_rust_source ${rust_static_dir} ${rust_source_dir}
    rm -rf ${rust_source_dir}/src/llvm-project/*
    cp -r ${root_build_dir}/third_party/llvm-project/* ${rust_source_dir}/src/llvm-project/
    echo "Copy the llvm source code completely"

    pushd ${rust_source_dir}
    export_ohos_path
    get_test_suite
    get_exclude_file "ohos"
    echo "Test the rust toolchain begin"
    python3 ./x.py test --stage=2 ${all_test_suite} $exclude_file --no-fail-fast
    popd

    echo "Test the rust toolchain Completed"
}

main
