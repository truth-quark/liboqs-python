#!/bin/bash

LIBOQS_MASTER_REPO="https://github.com/open-quantum-safe/liboqs.git"
LIBOQS_MASTER_BRANCH="master"
LIBOQS_NIST_BRANCH_REPO="https://github.com/open-quantum-safe/liboqs.git"
LIBOQS_NIST_BRANCH_BRANCH="nist-branch"

OKAY=1


build_liboqs_master() {
  echo "==============================" 2>&1 | tee -a $1
  echo "Building liboqs-master" 2>&1 | tee -a $1
  cd "${BASEDIR}/liboqs-master"
  git clean -d -f -x >> $1 2>&1
  git checkout -- . >> $1 2>&1
  autoreconf -i >> $1 2>&1
  ./configure --prefix="${BASEDIR}/install" --with-pic=yes --enable-openssl --with-openssl-dir="${BASEDIR}/install" >> $1 2>&1
  make clean >> $1 2>&1
  make -j >> $1 2>&1
  make install >> $1 2>&1
}

build_liboqs_nist() {
  echo "==============================" 2>&1 | tee -a $1
  echo "Building liboqs-nist" 2>&1 | tee -a $1
  cd "${BASEDIR}/liboqs-nist"
  git clean -d -f -x >> $1 2>&1
  git checkout -- . >> $1 2>&1
  make clean >> $1 2>&1
  make -j OPENSSL_INCLUDE_DIR="${BASEDIR}/install/include" OPENSSL_LIB_DIR="${BASEDIR}/install/lib" PREFIX="${BASEDIR}/install"  CC=${CC_OVERRIDE} >> $1 2>&1
  make install PREFIX="${BASEDIR}/install" >> $1 2>&1
}


# HKEX='ecdh-nistp384-bike1-L1-sha384@openquantumsafe.org ecdh-nistp384-bike1-L3-sha384@openquantumsafe.org ecdh-nistp384-bike1-L5-sha384@openquantumsafe.org ecdh-nistp384-frodo-640-aes-sha384@openquantumsafe.org ecdh-nistp384-frodo-976-aes-sha384@openquantumsafe.org ecdh-nistp384-sike-503-sha384@openquantumsafe.org ecdh-nistp384-sike-751-sha384@openquantumsafe.org ecdh-nistp384-oqsdefault-sha384@openquantumsafe.org'

# PQKEX='bike1-L1-sha384@openquantumsafe.org bike1-L3-sha384@openquantumsafe.org bike1-L5-sha384@openquantumsafe.org frodo-640-aes-sha384@openquantumsafe.org frodo-976-aes-sha384@openquantumsafe.org sike-503-sha384@openquantumsafe.org sike-751-sha384@openquantumsafe.org oqsdefault-sha384@openquantumsafe.org'

mkdir -p tmp
cd tmp
BASEDIR=`pwd`
DATE=`date '+%Y-%m-%d-%H%M%S'`
LOGS="${BASEDIR}/log-${DATE}.txt"
HOST=`hostname`
CC_OVERRIDE=`which clang`

if [ $? -eq 1 ] ; then
  CC_OVERRIDE=`which gcc-7`
  if [ $? -eq 1 ] ; then
    CC_OVERRIDE=`which gcc-6`
    if [ $? -eq 1 ] ; then
      CC_OVERRIDE=`which gcc-5`
      if [ $? -eq 1 ] ; then
        A=`gcc -dumpversion | cut -b 1`
        if [ $A -ge 5 ];then
          CC_OVERRIDE=`which gcc`
          echo "Found gcc >= 5 to build liboqs-nist" 2>&1 | tee -a $LOGS
        else
          echo "Need gcc >= 5 to build liboqs-nist"  2>&1 | tee -a $LOGS
          exit 1
        fi
      fi
    fi
  fi
fi


echo "To follow along with the testing process:" 2>&1 | tee -a $LOGS
echo "   tail -f ${LOGS}" 2>&1 | tee -a $LOGS
echo ""

#echo "==============================" 2>&1 | tee -a $LOGS
#echo "Cloning liboqs-master" 2>&1 | tee -a $LOGS
#if [ ! -d "${BASEDIR}/liboqs-master" ] ; then
    #git clone --branch ${LIBOQS_MASTER_BRANCH} --single-branch ${LIBOQS_MASTER_REPO} "${BASEDIR}/liboqs-master" >> $LOGS 2>&1
#fi

echo "==============================" 2>&1 | tee -a $LOGS
echo "Cloning liboqs-nist" 2>&1 | tee -a $LOGS
if [ ! -d "${BASEDIR}/liboqs-nist" ] ; then
    git clone --branch ${LIBOQS_NIST_BRANCH_BRANCH} --single-branch ${LIBOQS_NIST_BRANCH_REPO} "${BASEDIR}/liboqs-nist" >> $LOGS 2>&1
fi


# rm -rf ${BASEDIR}/install
#build_liboqs_master $LOGS
build_liboqs_nist $LOGS


echo ""
echo "=============================="
if [ ${OKAY} -eq 1 ] ; then
    echo "All tests completed successfully."
else
    echo "SOME TESTS FAILED."
fi
echo ""
echo "    DATE: ${DATE}"
echo "    OSTYPE: ${OSTYPE}"
echo -n "    Compiler: ${CC_OVERRIDE} "
${CC_OVERRIDE} --version | head -n 1
#echo -n "    liboqs-master (${LIBOQS_MASTER_REPO} ${LIBOQS_MASTER_BRANCH}) "
#cd "${BASEDIR}/liboqs-master"
#git log | head -n 1
echo -n "    liboqs-nist (${LIBOQS_NIST_BRANCH_REPO} ${LIBOQS_NIST_BRANCH_BRANCH}) "
cd "${BASEDIR}/liboqs-nist"
git log | head -n 1

ln -s "${BASEDIR}/liboqs-nist/liboqs.so" ~/liboqs.so
#export LIBOQS_INSTALL_PATH="${BASEDIR}/liboqs-nist/liboqs.so"
