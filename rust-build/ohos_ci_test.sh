#!/bin/bash
set -e

readonly shell_path=$(cd $(dirname $0); pwd)
readonly root_build_dir="${shell_path}/../../../.."
readonly rust_source_dir="${shell_path}/.."
readonly rust_tools="${root_build_dir}/prebuilts"
readonly rust_static_dir="${root_build_dir}/rust_download"
readonly oh_tools="${rust_tools}/ohos-sdk/linux/12/native/llvm/bin"
readonly mingw_tools="${rust_tools}/mingw-w64/ohos/linux-x86_64/clang-mingw/bin"

source ${shell_path}/function.sh
exclude_file=""

main() {
    detect_platform
    rm -rf ${rust_source_dir}/build/*
    download_rust_at_net
    copy_config
    update_config_clang ${oh_tools} ${mingw_tools}
    sed -i "s/nightly/beta/g" ${rust_source_dir}/config.toml
    sed -i "s/target = .*/target = [\"x86_64-unknown-linux-gnu\"]/g" ${rust_source_dir}/config.toml
    move_static_rust_source ${rust_static_dir} ${rust_source_dir}

    rm -rf ${rust_source_dir}/src/llvm-project/*
    cp -r ${root_build_dir}/../harmony/llvm/* ${rust_source_dir}/src/llvm-project/

    pushd ${rust_source_dir}
    export_ohos_path
    while read line; do
        if [ -z "$line" ]; then
             break
        fi
        exclude_file="$exclude_file --exclude $line"
    done < ${shell_path}/exclude_test.txt
    # Downloading through repo does not have an origin remote, but the Rust test code uses
    # the origin remote information. Add origin remote information through this method.
    # search "refs/remotes/origin" at rust code.
    if [ -z $(git remote | grep "origin") ]; then
        local address=$(echo $(git remote -v | grep fetch) | awk '{print $2}')
        git remote add origin ${address}
        git fetch -f origin
    fi

    test_suite_dir=("assembly" "codegen" "codegen-units" "incremental" "mir-opt"
                    "pretty" "run-coverage" "run-coverage-rustdoc" "run-make" "run-make-fulldeps"
                    "run-pass-valgrind" "rustdoc" "rustdoc-js" "rustdoc-js-std"
                    "rustdoc-json" "rustdoc-ui" "ui" "ui-fulldeps")
    all_test_suite=""
    for element in "${test_suite_dir[@]}"
    do
        all_test_suite="${all_test_suite} tests/${element}"
    done
    # clear cache before test
    sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'
    python3 ./x.py test --stage=2 tidy ${all_test_suite} $exclude_file --no-fail-fast

    popd
    echo "test the rust toolchain Completed"
}

main