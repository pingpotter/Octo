;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;								;
; Copyright (c) 1987-2018 Fidelity National Information		;
; Services, Inc. and/or its subsidiaries. All rights reserved.	;
;								;
; Copyright (c) 2018 YottaDB LLC and/or its subsidiaries.	;
; All rights reserved.						;
;								;
;	This source code contains the intellectual property	;
;	of its copyright holder(s), and is made available	;
;	under a license.  If you do not know the terms of	;
;	the license, please stop and do not read further.	;
;								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%OH	;GT.M %OH utility - octal to hexadecimal conversion program
	;invoke at INT with %OH in octal to return %OH in hexadecimal
	;invoke at FUNC as an extrinsic function
	;if you make heavy use of this routine, consider $ZCALL
	;
	s %OH=$$FUNC(%OH)
	q
INT	r !,"Octal: ",%OH s %OH=$$FUNC(%OH)
	i %OH="" w !,"Input must be an octal number"
	q
FUNCFM(o)
	n d,dg,h
	s d=0,h="",o=+o
	f dg=1:1:$l(o) s d=d*8+$e(o,dg)
	f  q:'d  s h=$e("0123456789ABCDEF",d#16+1)_h,d=d\16
	q h
FUNC(o)
	q:o=0 0
	q:"-"=$ze(o,1) ""
	q:o'?1.N ""
	q:o[8!(o[9) ""
	q:$l(o)<19 $$FUNCFM(o)
	q $$CONVERTBASE^%CONVBASEUTIL(o,8,16)
