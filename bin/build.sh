#!/bin/bash

set -eu

# Get OS environment parameters.
set_platform_info() {
    if [ "$(uname -s)" = 'Darwin' ]; then
        # Mac OSX
        readonly ID='macos'
        readonly ARCH='x86_64'
        readonly IS_LINUX='false'

    elif [ -e /etc/os-release ]; then
        . /etc/os-release
        readonly ARCH=`uname -p`
        readonly IS_LINUX='true'

    else
        echo "Thank you for useing. But sorry, this platform is not supported yet."
        exit 1
    fi
}

# Set local environment path.
set_env_info() {
    readonly ROOT_PATH=$(cd $(dirname $0)/.. && pwd)
    if [ "${TARGET}" = 'web' ]; then
        readonly BUILD_PATH=${ROOT_PATH}/build/webassembly
    else
        readonly BUILD_PATH=${ROOT_PATH}/build/${ID}_${ARCH}
        if [ "${IS_LINUX}" = 'true' ]; then
            export CC=cc
            export CXX=c++
        fi
    fi

    export COLONIO_GIT_PATH=${ROOT_PATH}

    if [ -z "${LOCAL_ENV_PATH+x}" ] ; then
        export LOCAL_ENV_PATH=${ROOT_PATH}/local
    fi
    mkdir -p ${LOCAL_ENV_PATH}/include
    mkdir -p ${LOCAL_ENV_PATH}/opt
    mkdir -p ${LOCAL_ENV_PATH}/src
    mkdir -p ${LOCAL_ENV_PATH}/wa
    export PKG_CONFIG_PATH=${LOCAL_ENV_PATH}/lib/pkgconfig/
}

# Install requirement packages for building native program.
setup_native() {
    if [ "${ID}" = 'macos' ]; then
        req_pkg=''
        has_pkg=$(brew list)
        for p in \
            asio\
            cmake\
            glog\
            libuv\
            pybind11
        do
            if echo "${has_pkg}" | grep ${p}; then
                :
            else
                req_pkg="${p} ${req_pkg}"
            fi
        done

        if [ "${req_pkg}" != '' ] ; then
            brew install ${req_pkg}
        fi

    elif type apt-get > /dev/null 2>&1; then
        if ! [ -v TRAVIS ]; then
            sudo apt-get install -y pkg-config automake cmake build-essential curl libcurl4-nss-dev libtool libx11-dev libgoogle-glog-dev
        fi

        setup_asio

    else
        echo "Thank you for useing. But sorry, this platform is not supported yet."
        exit 1
    fi

    setup_libuv
    setup_picojson
    setup_websocketpp
    setup_protoc_native
    setup_webrtc
    if [ "${WITH_TEST}" = 'true' ]; then
        setup_gtest
    fi
}

setup_web() {
    setup_picojson
    setup_emscripten
    setup_protoc_web
}

# Setup Emscripten
setup_emscripten() {
    cd ${LOCAL_ENV_PATH}/src
    if ! [ -e emsdk-portable.tar.gz ]; then
        curl -OL https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz
    fi
    cd ${LOCAL_ENV_PATH}/opt
    if ! [ -e emsdk-portable ]; then
        tar vzxf ${LOCAL_ENV_PATH}/src/emsdk-portable.tar.gz
    fi
    cd ${LOCAL_ENV_PATH}/opt/emsdk-portable
    ./emsdk update
    ./emsdk install latest
    ./emsdk activate latest
    if [ "${ID}" = 'macos' ]; then
        source ./emsdk_env.sh
    else
        . ./emsdk_env.sh
    fi
}

# Compile libuv.
setup_libuv() {
    if [ "${ID}" != 'macos' ]; then
        if pkg-config --modversion libuv | grep -o 1.12.0 >/dev/null
        then
            echo libuv 1.12.0 installed
        else
            cd ${LOCAL_ENV_PATH}/src
            if ! [ -e libuv-v1.12.0.tar.gz ]; then
                wget http://dist.libuv.org/dist/v1.12.0/libuv-v1.12.0.tar.gz
            fi
            if ! [ -e libuv-v1.12.0 ]; then
                tar zxf libuv-v1.12.0.tar.gz
            fi
            cd libuv-v1.12.0
            sh autogen.sh
            ./configure --prefix=${LOCAL_ENV_PATH}
            make
            make install
        fi
    fi
}

# Download picojson.
setup_picojson() {
    if [ -e ${LOCAL_ENV_PATH}/src/picojson ]; then
        cd ${LOCAL_ENV_PATH}/src/picojson
        git checkout master
        git pull
    else
        cd ${LOCAL_ENV_PATH}/src
        git clone https://github.com/kazuho/picojson.git
    fi
    cd ${LOCAL_ENV_PATH}/src/picojson
    git checkout refs/tags/v1.3.0
    cp ${LOCAL_ENV_PATH}/src/picojson/picojson.h ${LOCAL_ENV_PATH}/include/
}

# Download libwebrtc
setup_webrtc() {
    cd ${LOCAL_ENV_PATH}/src
    readonly WEBRTC_VER="m78"
    if [ "${ID}" = 'macos' ]; then
        readonly WEBRTC_FILE="libwebrtc-78.0.3904.108-macosx-10.15.1.zip"

    else
        readonly WEBRTC_FILE="libwebrtc-78.0.3904.108-ubuntu-18.04-x64.tar.gz"
    fi

    if ! [ -e "${WEBRTC_FILE}" ]; then
        if [ "${ID}" = 'macos' ]; then
            curl -OL https://github.com/llamerada-jp/libwebrtc/releases/download/${WEBRTC_VER}/${WEBRTC_FILE}
            cd ${LOCAL_ENV_PATH}
            rm -rf include/webrtc
            unzip -o src/${WEBRTC_FILE}
        else
            wget https://github.com/llamerada-jp/libwebrtc/releases/download/${WEBRTC_VER}/${WEBRTC_FILE}
            cd ${LOCAL_ENV_PATH}
            rm -rf include/webrtc
            tar zxf src/${WEBRTC_FILE}
        fi
    fi
}

setup_asio() {
    if [ -e ${LOCAL_ENV_PATH}/src/asio ]; then
        cd ${LOCAL_ENV_PATH}/src/asio
        git checkout master
        git pull
    else
        cd ${LOCAL_ENV_PATH}/src/
        git clone https://github.com/chriskohlhoff/asio.git
    fi
    cd ${LOCAL_ENV_PATH}/src/asio
    git checkout refs/tags/asio-1-12-2
    cd asio
    ./autogen.sh
    ./configure --prefix=${LOCAL_ENV_PATH} --without-boost
    make
    make install
}

# Download WebSocket++
setup_websocketpp() {
    if [ -e ${LOCAL_ENV_PATH}/src/websocketpp ]; then
        cd ${LOCAL_ENV_PATH}/src/websocketpp
        git checkout master
        git pull
    else
        cd ${LOCAL_ENV_PATH}/src
        git clone https://github.com/zaphoyd/websocketpp.git
    fi
    cd ${LOCAL_ENV_PATH}/src/websocketpp
    git checkout refs/tags/0.8.1
    mkdir -p /tmp
    cmake -DCMAKE_INSTALL_PREFIX=${LOCAL_ENV_PATH} ${LOCAL_ENV_PATH}/src/websocketpp
    make install
}

# Build Protocol Buffers on native
setup_protoc_native() {
    if ! [ -e ${LOCAL_ENV_PATH}/bin/protoc ]; then
        if [ -e ${LOCAL_ENV_PATH}/src/protobuf_native ]; then
            cd ${LOCAL_ENV_PATH}/src/protobuf_native
            git checkout master
            git pull
        else
            cd ${LOCAL_ENV_PATH}/src
            git clone https://github.com/protocolbuffers/protobuf.git protobuf_native
        fi
            cd ${LOCAL_ENV_PATH}/src/protobuf_native
        git checkout refs/tags/v3.10.1
        git submodule update --init --recursive
        ./autogen.sh
        ./configure --prefix=${LOCAL_ENV_PATH}
        make
        make install
    fi

    cd ${ROOT_PATH}
    ${LOCAL_ENV_PATH}/bin/protoc -I=src --cpp_out=src src/core/*.proto
    ${LOCAL_ENV_PATH}/bin/protoc -I=src --cpp_out=src src/core/map_paxos/*.proto
    ${LOCAL_ENV_PATH}/bin/protoc -I=src --cpp_out=src src/core/pubsub_2d/*.proto

    build_protoc
}

# Build Protocol Buffers for WebAssembly
setup_protoc_web() {
    setup_protoc_native

    if [ -e ${LOCAL_ENV_PATH}/src/protobuf_wa ]; then
        cd ${LOCAL_ENV_PATH}/src/protobuf_wa
        git checkout master
        git pull
    else
        cd ${LOCAL_ENV_PATH}/src
        git clone https://github.com/protocolbuffers/protobuf.git protobuf_wa
    fi
    cd ${LOCAL_ENV_PATH}/src/protobuf_wa
    git checkout refs/tags/v3.9.1
    git submodule update --init --recursive
    ./autogen.sh
    emconfigure ./configure --prefix=${LOCAL_ENV_PATH}/wa --disable-shared
    emmake make
    emmake make install
}

setup_gtest() {
    if [ -e ${LOCAL_ENV_PATH}/src/googletest ]; then
        cd ${LOCAL_ENV_PATH}/src/googletest
        git checkout master
        git pull
    else
        cd ${LOCAL_ENV_PATH}/src
        git clone https://github.com/google/googletest.git googletest
    fi
    cd ${LOCAL_ENV_PATH}/src/googletest
    git checkout refs/tags/release-1.10.0
    git submodule update --init --recursive
    cmake -DCMAKE_INSTALL_PREFIX=${LOCAL_ENV_PATH} .
    make
    make install
}

setup_seed() {
    # Clone or pull the repogitory of seed.
    if [ -z "${COLONIO_SEED_GIT_PATH+x}" ] ; then
        if [ -e "${LOCAL_ENV_PATH}/src/colonio-seed" ] ; then
            cd ${LOCAL_ENV_PATH}/src/colonio-seed
            git pull
        else
            cd ${LOCAL_ENV_PATH}/src
            git clone https://github.com/colonio/colonio-seed.git
        fi
        readonly COLONIO_SEED_GIT_PATH=${LOCAL_ENV_PATH}/src/colonio-seed
    fi

    # Build program of seed and export path.
    ${COLONIO_SEED_GIT_PATH}/bin/build.sh
    export COLONIO_SEED_BIN_PATH=${COLONIO_SEED_GIT_PATH}/bin/seed
}

# Compile native programs.
build_native() {
    if [ "${WITH_SAMPLE}" = 'true' ]; then
        OPT_SAMPLE='-DWITH_SAMPLE=ON'
    else
        OPT_SAMPLE=''
    fi
    if [ "${WITH_TEST}" = 'true' ]; then
        if [ "${ENABLE_COVERAGE}" = 'tru' ]; then
            OPT_TEST="-DWITH_TEST=ON -DWITH_COVERAGE=ON -DCOLONIO_SEED_BIN_PATH=${COLONIO_SEED_BIN_PATH}"
        else
            OPT_TEST="-DWITH_TEST=ON -DCOLONIO_SEED_BIN_PATH=${COLONIO_SEED_BIN_PATH}"
        fi
    else
        OPT_TEST=''
    fi
    mkdir -p ${BUILD_PATH}
    cd ${BUILD_PATH}
    cmake -DLOCAL_ENV_PATH=${LOCAL_ENV_PATH} -DCMAKE_BUILD_TYPE=${BUILD_TYPE} ${OPT_SAMPLE} ${OPT_TEST} ${ROOT_PATH}
    make
}

build_protoc() {
    cd ${ROOT_PATH}
    ./local/bin/protoc --cpp_out src -I src src/core/*.proto
    ./local/bin/protoc --cpp_out src -I src src/core/map_paxos/*.proto
    ./local/bin/protoc --cpp_out src -I src src/core/pubsub_2d/*.proto
}

build_web() {
    mkdir -p ${BUILD_PATH}
    cd ${BUILD_PATH}
    emcmake cmake -DLOCAL_ENV_PATH=${LOCAL_ENV_PATH} -DCMAKE_BUILD_TYPE=${BUILD_TYPE} ${ROOT_PATH}
    emmake make
}

show_usage() {
    echo "Usage: $1 [-dhw]" 1>&2
    echo "  -c : Build test with coverage.(Native only)" 1>&2
    echo "  -d : Set build type to debug mode." 1>&2
    echo "  -h : Show this help." 1>&2
    echo "  -w : Build webassembly module." 1>&2
    echo "  -s : Build with sample programs.(Native only)" 1>&2
    echo "  -t : Build test programs.(Native only)" 1>&2
}

# Default options.
TARGET='native'
ENABLE_DEBUG='false'
ENABLE_COVERAGE='false'
WITH_SAMPLE='false'
WITH_TEST='false'

# Decode options.
while getopts dhstw OPT
do
    case $OPT in
        c)  ENABLE_COVERAGE='true'
            ENABLE_DEBUG='true'
            ;;
        d)  ENABLE_DEBUG='true'
            ;;
        h)  show_usage $0
            exit 0
            ;;
        s)  WITH_SAMPLE='true'
            ;;
        t)  WITH_TEST='true'
            ;;
        w)  TARGET='web'
            ;;
        \?) show_usage $0
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

set -x

set_platform_info
set_env_info

if [ "${ENABLE_DEBUG}" = 'true' ]; then
    readonly BUILD_TYPE='Debug'
else
    readonly BUILD_TYPE='Release'
fi

if [ "${TARGET}" = 'native' ]; then
    setup_native
    if [ "${WITH_TEST}" = 'true' ] ; then
        setup_seed
    fi
    build_native
else # web
    setup_web
    build_web
fi
