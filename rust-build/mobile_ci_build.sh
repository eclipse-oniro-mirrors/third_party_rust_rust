#!/bin/bash
set -e

readonly shell_path=$(cd $(dirname $0); pwd)
readonly root_build_dir="${shell_path}/../.."
readonly rust_source_dir="${shell_path}/.."
readonly ci_shell_dir="${root_build_dir}/build/rustbuild/"
readonly install_path="${rust_source_dir}/build/dist"
readonly output_install="${root_build_dir}/output/"
readonly oh_tools="/opt/buildtools/mobile_cpu/BiSheng/bin"
readonly mingw_tools="/opt/buildtools/llvm-mingw-20220906/bin"
readonly bep_home="/opt/buildtools/secBepkit-2.2.0.2"
readonly old_version="xxxxx"
new_version="xxxxx"
bep_build=false
bep_time="2024-09-29 12:00:00"
source ${shell_path}/function.sh
export PATH=$rust_source_dir:/usr/local/bin:$PATH

show_help() {
    echo "Usage: $0 [OPTIONS] [ARGUMENTS]"
    echo "Options:"
    echo "  -h  Display this help message"
    echo "  -v  Set build version"
    echo "  -b  Bep build, warning: will delete git information"
    echo "  -t  Set bep build time"
    echo "Arguments:"
    echo "  ARGUMENTS are additional values passed to the script"
}

parse_options() {
    local OPTIND=1
    while getopts "hv:b:t:" opt; do
        case $opt in
            h) show_help; exit 0 ;;
            v) new_version="$OPTARG" ;;
            b) bep_build="$OPTARG" ;;
            t) bep_time="$OPTARG" ;;
            \?) echo "unsupport arguments -$OPTARG" >&2
                exit 1 ;;
        esac
    done
    shift $((OPTIND - 1))
    return 0
}

bep_prepare() {
    # bep patch
    if [ -n "$(grep -rn "HashMap" $root_build_dir/rust/vendor/compiler_builtins/build.rs)" ];then
        pushd ${rust_source_dir}/vendor/compiler_builtins/ 
        patch < ${ci_shell_dir}/vendor.patch
        popd
    fi
    if [ -n "$(grep -rn "3f2f9589f896c5dc7e7ce39f5809f4f63d1199e5f80ae23b343a7f1d889d0206" $root_build_dir/rust/vendor/compiler_builtins/.cargo-checksum.json)" ];then
        cp ${ci_shell_dir}/.cargo-checksum.json ${rust_source_dir}/vendor/compiler_builtins/
    fi

    # remove .git .gitlab .gitattributes for bep
    pushd ${rust_source_dir}
    (find . -name ".git" -print && find . -name ".gitlab" -print && find . -name ".gitattributes" -print) | xargs rm -rf
    (find . -name ".gitignore" -print && find . -name ".github" -print && find . -name ".gitkeep" -print) | xargs rm -rf
    popd
}

lock_bep_time() {
    if [ "${host_platform}" = "linux" ] && [ ${host_cpu} = "x86_64" ]; then
        sed -i "2s/.*/bep_timestamp=${bep_time}/" ${ci_shell_dir}/bep_env.conf
        sed -i "3s/.*/second=${bep_time}/" ${ci_shell_dir}/bep_env.conf
        sed -i "4s/.*/third=${bep_time}/" ${ci_shell_dir}/bep_env.conf
        source ${bep_home}/bep_env.sh -s ${ci_shell_dir}/bep_env.conf
    fi
}

unlock_bep_time() {
    if [ "${host_platform}" = "linux" ] && [ ${host_cpu} = "x86_64" ]; then
        source ${bep_home}/bep_env.sh -u
    fi 
}

collect_linux_build_result() {
    # $1:file name
    pushd ${install_path}
    tar -xf ${1}.tar.gz
    rm ${1}.tar.gz
    chmod 750 $install_path/${1} -R
    tar --format=gnu -czf ${1}.tar.gz ${1}
    cp $install_path/${1}.tar.gz ${output_install}
    popd
}

collect_mac_build_result() {
    # $1:file name
    pushd ${install_path}
    tar -xf ${1}.tar.gz
    rm ${1}.tar.gz
    find ${1}/* -exec touch -h -m -d "$bep_time" {} \;
    touch -h -m -d "$bep_time" ${1}
    chmod -R 750 ${1}
    tar -cf ${1}.tar ${1}
    gzip -n ${1}.tar
    rm -rf ${1}
    cp ${install_path}/${1}.tar.gz ${output_install}
    popd
}

collect_build_result() {
    mkdir -p ${output_install}

    if [ "${host_platform}" = "linux" ] && [ ${host_cpu} = "x86_64" ]; then
        collect_linux_build_result rust-nightly-x86_64-unknown-linux-gnu
        collect_linux_build_result rust-std-nightly-x86_64-pc-windows-gnullvm
        collect_linux_build_result rust-std-nightly-aarch64-unknown-linux-ohos
        collect_linux_build_result rust-std-nightly-armv7-unknown-linux-ohos
        collect_linux_build_result rust-std-nightly-x86_64-unknown-linux-ohos
    elif [ "${host_platform}" = "darwin" ] && [ ${host_cpu} = "x86_64" ]; then
        collect_mac_build_result rust-nightly-x86_64-apple-darwin
    elif [ "${host_platform}" = "darwin" ] && [ ${host_cpu} = "arm64" ]; then
        collect_mac_build_result rust-nightly-aarch64-apple-darwin
    fi
}

main() {
    parse_options "$@"
    detect_platform
    download_rust
    copy_config
    update_config_clang ${oh_tools} ${mingw_tools}
    update_version
    move_static_rust_source "${root_build_dir}/opensource/Rust/1.72.0/" ${rust_source_dir}

    rm -rf ${rust_source_dir}/src/llvm-project/*
    cp -r ${root_build_dir}/llvm/* ${rust_source_dir}/src/llvm-project

    if [ ${bep_build} = true ]; then
        bep_prepare
        lock_bep_time
    fi

    pushd ${rust_source_dir}
    python3 ./x.py dist
    popd

    if [ ${bep_build} = true ]; then
        collect_build_result
        unlock_bep_time
    fi
    
    if [ "${host_platform}" = "linux" ]; then
        check_build_result aarch64-unknown-linux-ohos
    fi

    echo "Building the rust toolchain Completed"
}

main "$@"
