rm -f extcall_aix_64.*

tar -cf extcall_aix_64.tar Makefile asc2c3.c asc2ebc.c atmutils.c devutils.c ebc2asc.c elfhash.c extcall.a extcall.exp extcall.h extcall.mk extcall.xc gtmxc_types.h scatype.h mathutils.c md5.h md5c.c pidutils.c readport.c remote.c rtb.c rtbar.c rules.mk scamd5.c scamd5.h shlib.o slibrule.mk string.c sysutils.c unpack.c unpack2.c utils.c xor.c extcallversion version.c version.mk extcall_tar.sh

gzip -9 *.tar
