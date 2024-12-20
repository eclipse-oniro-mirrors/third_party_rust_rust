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
        cp ${shell_path}/tools/* ${rust_source_dir}/build/
        chmod 750 ${rust_source_dir}/build/*clang*
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
    cp -r library/{backtrace,stdarch} ${2}/library/
    cp -r src/doc/{book,edition-guide,embedded-book,nomicon} ${2}/src/doc/
    cp -r src/doc/{reference,rust-by-example,rustc-dev-guide} ${2}/src/doc/
    cp -r src/tools/cargo/* ${2}/src/tools/cargo/
    popd
    popd
}

download_rust_static_source() {
    local pre_rust_date="2023-07-13"
    mkdir -p ${rust_static_dir} ${rust_source_dir}/build/cache/${pre_rust_date}
    local rust_down_net="https://mirrors.ustc.edu.cn/rust-static/dist"
    pushd ${rust_static_dir}
    local platform=$1
    local cpu=$2
    local files=("rust-std-1.71.0-${cpu}-${platform}.tar.xz" "rustc-1.71.0-${cpu}-${platform}.tar.xz" \
                 "cargo-1.71.0-${cpu}-${platform}.tar.xz")

    for file in "${files[@]}"; do
        if [ ! -e "${file}" ]; then
            curl -O -k -m 300 ${rust_down_net}/${pre_rust_date}/${file} &
        fi
    done
    if [ ! -e "rustc-1.72.0-src.tar.gz" ]; then
            curl -O -k -m 300 ${rust_down_net}/rustc-1.72.0-src.tar.gz &
    fi
    wait
    popd
    cp ${rust_static_dir}/*.tar.xz ${rust_source_dir}/build/cache/${pre_rust_date}/
    cp ${rust_static_dir}/rustc-1.72.0-src.tar.gz ${root_build_dir}
}

download_rust_at_net() {
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

check_build_result() {
    pushd ${install_path}
    local target_name=${1}
    tar -xf rust-std-nightly-${1}.tar.gz
    local file_name="./rust-std-nightly-${1}/rust-std-${1}/lib/rustlib/${1}/lib/libstd.dylib.so"
    llvm-strip ${file_name}
    local file_size=$(stat -c%s ${file_name})
    # so size should not exceed 1.2M
    rm -rf rust-std-nightly-${1}
    if [ $file_size -ge 1228000 ]; then
        echo "${file_name} size exceed 1.2M, size is ${file_size}"
        exit 1;
    fi
    echo "so size is ${file_size}"
    popd
}

export_ohos_path() {
    if [ "${host_platform}" = "linux" ]; then
        export PATH=${rust_tools}/clang/ohos/linux-x86_64/llvm/bin:$PATH
        export PATH=${rust_tools}/cmake/linux-x86/bin:$PATH
    fi
}

download_rust() {
    local pre_rust_date="2023-07-13"
    mkdir -p ${rust_source_dir}/build/cache/${pre_rust_date}
    if [ "${host_platform}" = "linux" ] && [ ${host_cpu} = "x86_64" ]; then
        if [ ! -d "${root_build_dir}/opensource" ]; then
            artget pull -ap "${root_build_dir}/opensource" -os "${ci_shell_dir}/rust1.72.0.xml" -at opensource
            artget pull -ap "${root_build_dir}/opensource" -os "${ci_shell_dir}/rust1.71.0_linux.xml" -at opensource
        fi
    elif [ "${host_platform}" = "darwin" ]; then
        artget pull -ap "${root_build_dir}/opensource" -os "${ci_shell_dir}/rust1.72.0.xml" -at opensource
        if [ ${host_cpu} = "x86_64" ]; then
            artget pull -ap "${root_build_dir}/opensource" -os "${ci_shell_dir}/rust1.71.0_mac_x86.xml" -at opensource
        elif [ ${host_cpu} = "arm64" ]; then
            artget pull -ap "${root_build_dir}/opensource" -os "${ci_shell_dir}/rust1.71.0_mac_arm.xml" -at opensource
        fi
    fi
    cp ${root_build_dir}/opensource/Rust/1.71.0/* ${rust_source_dir}/build/cache/${pre_rust_date}
}

get_exclude_file() {
    while read line; do
        if [ -z "$line" ]; then
                break
        fi
        # get fail repository
        tag=$(echo $line | cut -d ']' -f 1 | tr -d '[')
        # get fail test case
        content=$(echo $line | cut -d ']' -f 2-)
        case $tag in
            "all")
                exclude_file="$exclude_file --exclude $content"
                ;;
            "mobile")
                if [ "${1}" = "mobile" ]; then
                    exclude_file="$exclude_file --exclude $content"
                fi
                ;;
            "ohos")
                if [ "${1}" = "ohos" ]; then
                    exclude_file="$exclude_file --exclude $content"
                fi
                ;;
            *)
                echo "Unknown tag: $tag"
                ;;
        esac
    done < ${shell_path}/exclude_test.txt
}

get_test_suite() {
    test_suite_dir=("assembly" "codegen" "codegen-units" "incremental" "mir-opt"
                    "pretty" "run-coverage" "run-coverage-rustdoc" "run-make" "run-make-fulldeps"
                    "run-pass-valgrind" "rustdoc" "rustdoc-js" "rustdoc-js-std"
                    "rustdoc-json" "rustdoc-ui" "ui" "ui-fulldeps")
    for element in "${test_suite_dir[@]}"
    do
        all_test_suite="${all_test_suite} tests/${element}"
    done
}
