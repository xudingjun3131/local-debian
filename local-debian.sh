#!/usr/bin/env bash
set -e

localDebian="$(basename "$0")"

optTemp=$(getopt -o 'r::h' --long 'release::,help' --name "$localDebian" -- "$@")
eval set -- "$optTemp"
unset optTemp

release=kylin
help=0
compression="auto"
while true; do
        case "$1" in
        -r|--release)
            case "$2" in
                "") release='kylin' ; shift 2 ;;
                *) release=$2 ; shift 2 ;;
            esac ;;
                -h|--help) usage ;;
                --) shift ; break ;;
        esac
done

rm -Rf ./tmp
mkdir -p ./tmp/local-kylin
temp=$(mktemp -d --tmpdir=./tmp local-kylinXXX)
#temp='/root/local-debian/tmp/local-kylin'
OUTPUT_SEMAPHORE=`pwd`/local-$release
apt-get install -yqq debootstrap

#mkdir -p $temp/usr/lib/x86_64-linux-gnu
#mkdir -p $temp/usr/lib32
#mkdir -p $temp/usr/lib64
#mkdir -p $temp/usr/libx32
#mkdir -p $temp/usr/sbin
#cp /usr/lib32/libc.so.6 $temp/usr/lib32/
#cp /usr/lib/x86_64-linux-gnu/libc.so.6 $temp/usr/lib/x86_64-linux-gnu/
#cp /lib64/ld-linux-x86-64.so.2 $temp/usr/lib64/
#cp /lib/x86_64-linux-gnu/ld-2.31.so $temp/usr/lib/
#cp /usr/sbin/ldconfig $temp/usr/sbin/
#cp /usr/sbin/ldconfig.real $temp/usr/sbin/
#cp /usr/lib/x86_64-linux-gnu/libzstd.so.1 $temp/usr/lib/x86_64-linux-gnu/
#cp /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0 $temp/usr/lib/x86_64-linux-gnu/
#cp /usr/lib32/libdl.so.2 $temp/usr/lib32/
#cp /usr/lib/x86_64-linux-gnu/libkysec.so.0 $temp/usr/lib/x86_64-linux-gnu/
#cp /usr/lib/x86_64-linux-gnu/libdl.so.2 $temp/usr/lib/x86_64-linux-gnu/
#cp /usr/lib32/libpthread.so.0 $temp/usr/lib32/
#cp /usr/lib/x86_64-linux-gnu/libpthread.so.0 $temp/usr/lib/x86_64-linux-gnu/
#cp /usr/lib/x86_64-linux-gnu/libkysec_log.so.0 $temp/usr/lib/x86_64-linux-gnu/
#cp /usr/lib32/libm.so.6 $temp/usr/lib32/
#cp /usr/lib/x86_64-linux-gnu/libm.so.6 $temp/usr/lib/x86_64-linux-gnu/
#cp /usr/lib/x86_64-linux-gnu/libcrypt.so.1 $temp/usr/lib/x86_64-linux-gnu/
#cp /usr/lib/x86_64-linux-gnu/libdebconfclient.so.0 $temp/usr/lib/x86_64-linux-gnu/

chmod 777 "$temp"
debootstrap --variant=minbase --include=apt-utils,tzdata,less,gnupg,vim,locales,lsb-release,libterm-readline-gnu-perl buster "$temp" http://repo.huaweicloud.com/debian/
#debootstrap --variant=minbase --include=apt-utils 10.1 "$temp" https://archive.kylinos.cn/kylin/KYLIN-ALL/
#echo "deb http://archive.kylinos.cn/kylin/KYLIN-ALL 10.1-2303-updates main universe multiverse restricted" > "$temp/etc/apt/sources.list.d/update.list"
#echo "deb http://archive.kylinos.cn/kylin/KYLIN-ALL 10.1 main restricted universe multiverse" > "$temp/etc/apt/sources.list.d/update.list"
#echo "deb http://archive2.kylinos.cn/deb/kylin/production/PART-V10-SP1/custom/partner/V10-SP1 default all" > "$temp/etc/apt/sources.list.d/update.list"
echo "Upgrading"
cp /etc/apt/sources.list $temp/etc/apt/
cp /usr/share/keyrings/* $temp/usr/share/keyrings/
chroot "$temp" apt-key add /usr/share/keyrings/kylin-archive-keyring.gpg
chroot "$temp" apt-key add /usr/share/keyrings/kylin-thirdparty-archive-keyring.gpg
chroot "$temp" apt-get update
chroot "$temp" apt-get -y dist-upgrade
# Make all servers America/New_York
echo "Asia/Shanghai" > "$temp/etc/timezone"
chroot "$temp" /usr/sbin/dpkg-reconfigure --frontend noninteractive tzdata
chroot "$temp" rm -Rf /var/lib/apt/lists/
cp /etc/os-release $temp/etc/
cp /etc/lsb-release $temp/etc/
echo "Importing into docker"
cd "$temp" && tar -c . | docker import - local-$release
cd /tmp
echo "Removing temp directory"
date -I &>"$OUTPUT_SEMAPHORE"
du -sh "$temp" &>>"$OUTPUT_SEMAPHORE"
rm -rf "$temp"
