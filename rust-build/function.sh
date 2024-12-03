#!/bin/bash

detect_platform() {
    case $(uname -s) in
        Linux) host_platform=linux ;;
        Darwin) host_platform=darwin ;;
        *) echo "Unsupported host platform: $(uname -s)"; exit 1 ;;
    esac

    case $(uname -m) in
        arm64) host_cpu=arm64 ;;
        *) host_cpu=x86_64 ;;
    esac
}

copy_config() {
    if [ "${host_platform}" = "linux" ] && [ "${host_cpu}" = "x86_64" ]; then
        cp ${shell_path}/config.toml ${rust_source_dir}
        chmod 750 ${shell_path}/tools/*
        cp ${shell_path}/tools/* ${rust_source_dir}/build/
    elif [ "${host_platform}" = "darwin" ]; then
        if [ "${host_cpu}" = "x86_64" ]; then
            cp ${shell_path}/mac_x8664_config.toml ${rust_source_dir}/config.toml
        else
            cp ${shell_path}/mac_arm64_config.toml ${rust_source_dir}/config.toml
        fi
    else
        echo "Unsupported platform: $(uname -s) $(uname -m)"
        exit 1
    fi
}

update_config_clang_path() {
    # $1:clang path, $2:clang name, $3:ar name

    # add clang absolute path to shell tools
    sys_clang_dir="$(echo ${1} | sed 's/\//\\\//g')"
    sed -i "s/exec ${2}/exec ${sys_clang_dir}\/${2}/g" ${rust_source_dir}/build/${2}
    sed -i "s/exec ${2}++/exec ${sys_clang_dir}\/${2}++/g" ${rust_source_dir}/build/${2}++
    # add clang absolute path to config.toml
    rust_clang_dir="$(echo ${rust_source_dir}/build | sed 's/\//\\\//g')"
    sed -i "s/cc = \"${2}\"/cc = \"${rust_clang_dir}\/${2}\"/g" ${rust_source_dir}/config.toml
    sed -i "s/cxx = \"${2}++\"/cxx = \"${rust_clang_dir}\/${2}++\"/g" ${rust_source_dir}/config.toml
    sed -i "s/linker = \"${2}\"/linker = \"${sys_clang_dir}\/${2}\"/g" ${rust_source_dir}/config.toml
    sed -i "s/ar = \"${3}\"/ar = \"${sys_clang_dir}\/${3}\"/g" ${rust_source_dir}/config.toml
}

update_config_clang() {
    # $1:OH clang path $2:mingw clang path
    if [ "${host_platform}" = "linux" ] && [ ${host_cpu} = "x86_64" ]; then
        update_config_clang_path ${1} clang llvm-ar
        update_config_clang_path ${1} aarch64-unknown-linux-ohos-clang llvm-ar
        update_config_clang_path ${1} armv7-unknown-linux-ohos-clang llvm-ar
        update_config_clang_path ${1} x86_64-unknown-linux-ohos-clang llvm-ar
        update_config_clang_path ${2} x86_64-w64-mingw32-clang x86_64-w64-mingw32-ar
    fi
}

update_version() {
    if [ "${host_platform}" = "linux" ] && [ ${host_cpu} = "x86_64" ]; then
        sed -i "s/$old_version/$new_version/g" ${rust_source_dir}/config.toml
    elif [ "${host_platform}" = "darwin" ] && [ ${host_cpu} = "x86_64" ]; then
        sed -i "" "s/$old_version/$new_version/g" ${rust_source_dir}/config.toml
    elif [ "${host_platform}" = "darwin" ] && [ ${host_cpu} = "arm64" ]; then
        sed -i "" "s/$old_version/$new_version/g" ${rust_source_dir}/config.toml
    else
        echo "Unsupported platform: $(uname -s) $(uname -m)"
    fi
}

move_static_rust_source() {
    # $1:static rust code path. $2:rust code path
    pushd ${1}
    tar xf rustc-1.72.0-src.tar.gz
    pushd ${1}/rustc-1.72.0-src
    cp -r {.cargo,vendor} ${2}
    cp -r library/backtrace/* ${2}/library/backtrace/
    cp -r library/stdarch/* ${2}/library/stdarch/
    cp -r src/doc/* ${2}/src/doc/
    cp -r src/tools/cargo/* ${2}/src/tools/cargo/
    popd
    popd
}
