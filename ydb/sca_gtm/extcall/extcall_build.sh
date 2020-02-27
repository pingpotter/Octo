#!/bin/sh
#
#	Copyright (C) 2012 - Fidelity Information Services
#
#	$Id$
#	$Log:	security_build.sh,v $
#	Revision 1.1  2012/09/04 
#	Initial revision
#	Build Script for creating extcall Library.
#	This Script will run against the Aix(32,64) Platforms,Linux(32,64)
#	$Revision: 1.1 $
#
#	For Aix 32 and 64 bit Library will generate in the same folder
os=`uname`
case $os in
	"Linux")
		os_bit=`uname -m`
		echo $os_bit	
		if [ "$os_bit" = "x86_64" ]
		then
		rm -f *.o *.sl *.a  
		make -f extcall.mk "CC=/usr/bin/gcc" "CFLAGS = -c -g -fpic" "LD=/usr/bin/gcc" "LFLAGS= -lm -lc" "SHARED_LIBRARY=extcall.sl" "LIBNAME= -shared -o"
 		rm -f extcallversion
 		make -f version.mk "SHARED_LIBRARY=extcall.sl"
		rm -f extcall_linux_64.*
		echo Library Name is :  `pwd | cut -d '/' -f4` > versionInfo.txt
		echo Platform : $os >> versionInfo.txt
		echo Version of the OS: `uname -r` >> versionInfo.txt
		echo 32 Or 64 Bit: $os_bit  >> versionInfo.txt
		echo Name and Version of the Compiler : `gcc --version` >> versionInfo.txt
        tar -cf extcall_linux_64.tar *.c *.o *.xc *.mk *.h *.sh *.txt extcallversion extcall.sl
        gzip -9 extcall_linux_64.tar
		else
		rm -f *.o *.sl *.a
		make -f extcall.mk "CC=/usr/bin/gcc" "CFLAGS = -c -g" "LD=gcc" "LFLAGS=-lm" "SHARED_LIBRARY=extcall.sl" "LIBNAME= -shared -o"
 		rm -f extcallversion
 		make -f version.mk "SHARED_LIBRARY=extcall.sl" 
		rm -f extcall_linux_32.*
		echo Library Name is :  `pwd | cut -d '/' -f4` > versionInfo.txt
		echo Platform : $os >> versionInfo.txt
		echo Version of the OS: `uname -r` >> versionInfo.txt
		echo 32 Or 64 Bit: $os_bit  >> versionInfo.txt
		echo Name and Version of the Compiler : `gcc --version` >> versionInfo.txt
        tar -cf extcall_linux_32.tar *.c *.o *.xc *.mk *.h *.sh *.txt extcallversion extcall.sl
       	gzip -9 extcall_linux_32.tar
		fi
		;;
	"AIX")
		os_bit=`getconf KERNEL_BITMODE`
		echo $os_bit	
		if [ "$os_bit" = 64 ]
		then	
		rm -f *.o *.sl *.a  
		make -f extcall.mk "CC=/usr/vac/bin/cc" "CFLAGS = -c -q64" "LD=/usr/bin/ld" "LFLAGS=-b64 -bE:extcall.exp -H512 -T512 -bM:SRE -lc -bh:4 -lm -eclxfr" "SHARED_LIBRARY=extcall.a" "LIBNAME= -o" 
        rm -f extcallversion
        cc -o extcallversion -q64 version.c extcall.a
		rm -f extcall_aix_64.*
		echo Library Name is :  `pwd | cut -d '/' -f4` > versionInfo.txt
		echo Platform : $os >> versionInfo.txt
		echo Version of the OS: `oslevel -r` >> versionInfo.txt
		echo 32 Or 64 Bit: $os_bit  >> versionInfo.txt
		echo Name and Version of the Compiler : `gcc --version` >> versionInfo.txt
        tar -cf extcall_aix_64.tar *.c *.o *.xc *.exp *.mk *.h *.sh *.txt extcallversion extcall.a
        gzip -9 extcall_aix_64.tar
		rm -f *.o *.sl *.a  
		rm -f extcallversion
 		make -f extcall.mk "CC=/usr/vac/bin/cc" "CFLAGS = -c -g" "LD=/usr/bin/ld" "LFLAGS=-bE:./extcall.exp -H512 -T512 -bM:SRE -lc -bh:4 -lm -eclxfr" "SHARED_LIBRARY=extcall.a" "LIBNAME= -o" 
		cc -o extcallversion version.c extcall.a
		rm -f extcall_aix_32.*
		echo Library Name is :  `pwd | cut -d '/' -f4` > versionInfo.txt
		echo Platform : $os >> versionInfo.txt
		echo Version of the OS: `oslevel -r` >> versionInfo.txt
		echo 32 Or 64 Bit: $os_bit  >> versionInfo.txt
		echo Name and Version of the Compiler : `gcc --version` >> versionInfo.txt
        tar -cf extcall_aix_32.tar *.c *.o *.xc *.exp *.mk *.h *.sh *.txt extcallversion extcall.a
        gzip -9 extcall_aix_32.tar
		fi
		;;
        *)
        ;;
esac

