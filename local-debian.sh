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

chmod 777 "$temp"
#debootstrap --variant=minbase --include=apt-utils,tzdata,less,gnupg,vim,locales,lsb-release,libterm-readline-gnu-perl,apt-transport-https,ca-certificates,curl,software-properties-common buster "$temp" http://repo.huaweicloud.com/debian/
#debootstrap  --no-check-gpg --variant=minbase --include=apt-utils,tzdata,locales,libterm-readline-gnu-perl,gnupg,apt-transport-https,ca-certificates --components=main,restricted,universe,multiverse --merged-usr  10.1 "$temp" https://archive.kylinos.cn/kylin/KYLIN-ALL/
debootstrap --no-check-gpg --include=apt-utils,tzdata,locales,libterm-readline-gnu-perl,gnupg,apt-transport-https,ca-certificates --components=main,restricted,universe,multiverse --merged-usr  10.1 "$temp" https://archive.kylinos.cn/kylin/KYLIN-ALL/
#echo "deb http://archive.kylinos.cn/kylin/KYLIN-ALL 10.1-2303-updates main universe multiverse restricted" > "$temp/etc/apt/sources.list.d/update.list"
#echo "deb http://archive.kylinos.cn/kylin/KYLIN-ALL 10.1 main restricted universe multiverse" > "$temp/etc/apt/sources.list.d/update.list"
#echo "deb http://archive2.kylinos.cn/deb/kylin/production/PART-V10-SP1/custom/partner/V10-SP1 default all" > "$temp/etc/apt/sources.list.d/update.list"
echo "Upgrading"
cp /etc/apt/sources.list $temp/etc/apt/
cp /usr/share/keyrings/* $temp/usr/share/keyrings/
chroot "$temp" apt-key add /usr/share/keyrings/kylin-archive-keyring.gpg
chroot "$temp" apt-key add /usr/share/keyrings/kylin-thirdparty-archive-keyring.gpg
echo "update"
#chroot "$temp" apt-get update
echo "dist-upgrade"
#chroot "$temp" apt-get -y dist-upgrade
# Make all servers America/New_York
echo "Asia/Shanghai" > "$temp/etc/timezone"
chroot "$temp" /usr/sbin/dpkg-reconfigure --frontend noninteractive tzdata
chroot "$temp" rm -Rf /var/lib/apt/lists/
#cp /etc/os-release $temp/etc/
#cp /etc/lsb-release $temp/etc/
cp -rf /etc/ssl/certs/* $temp/etc/ssl/certs/
echo "Importing into docker"
cd "$temp" && tar -c . | docker import - local-$release
cd /tmp
echo "Removing temp directory"
date -I &>"$OUTPUT_SEMAPHORE"
du -sh "$temp" &>>"$OUTPUT_SEMAPHORE"
rm -rf "$temp"
