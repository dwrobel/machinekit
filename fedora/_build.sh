#!/bin/bash -e

if ! dnf repolist | grep copr:copr.fedorainfracloud.org:dwrobel:python-Yapps2; then
    rpm -qv dnf-plugins-core 2>/dev/null || sudo dnf install dnf-plugins-core
    sudo dnf copr enable -y dwrobel/python-Yapps2
    sudo dnf builddep -y linuxcnc.spec
fi

pv=${1-3}

pushd ../src

export CFLAGS="-Dcflags -O0 -ggdb3"
export CXXFLAGS="-Dcxxflags -O0 -ggdb3"
export CPPFLAGS="-Dcppflags -I/usr/include/readline5 $(pkg-config --cflags python${pv}) -O0 -ggdb3"
#export CPPFLAGS="-Dcppflags -I/usr/include/readline5 $(pkg-config --cflags python${pv}) -O0 -ggdb3 -fsanitize=address -fPIE -fno-omit-frame-pointer"
#ASAN_OPTIONS=halt_on_error=false LD_PRELOAD=/usr/lib64/libasan.so.5 linuxcnc
export LDFLAGS="-L/usr/lib64/readline5"

autoreconf -fi .

export ac_cv_path_CHECKLINK=/usr/bin/true

./configure \
    --with-python=/usr/bin/python${pv} \
    --enable-non-distributable=no \
    --with-realtime=uspace \

#    --enable-build-documentation=pdf
#    --enable-non-distributable=yes \

make -j$(getconf _NPROCESSORS_ONLN) -O V=1 2>&1 | tee ../fedora/build.log

#echo "(cd ../src && sudo make setuid -n)"
sudo setcap cap_net_admin,cap_sys_rawio,cap_sys_nice+ep  ../bin/rtapi_app
