;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;								;
; Copyright (c) 1987-2018 Fidelity National Information		;
; Services, Inc. and/or its subsidiaries. All rights reserved.	;
;								;
;	This source code contains the intellectual property	;
;	of its copyright holder(s), and is made available	;
;	under a license.  If you do not know the terms of	;
;	the license, please stop and do not read further.	;
;								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%DH	;GT.M %DH utility - decimal to hexadecimal conversion program
	;invoke with %DH in decimal and %DL digits to return %DH in hexadecimal
	;invoke at INT to execute interactively
	;invoke at FUNC as an extrinsic function
	;if you make heavy use of this routine, consider $ZCALL
	;
	s %DH=$$FUNC(%DH,$G(%DL))
	q
INT	n %DL
	r !,"Decimal: ",%DH r !,"Digits:  ",%DL s %DH=$$FUNC(%DH,%DL)
	q
FUNCFM(d,l)
	q:d=0 $e("00000000",1,l)
	n h
	s h=""
	f  q:'d  s h=$e("0123456789ABCDEF",d#16+1)_h,d=d\16
	q $e("00000000",1,l-$l(h))_h
FUNC(d,l)
	n isn,i,h,apnd
	s:'$l($g(l)) l=8
	s isn=0,i=0,h="",apnd="0"
	if d["-" do
	. s isn=1,d=$extract(d,2,$length(d))
	if ($l(d)<18) do
	. s h=$$FUNCFM(d,l)
	else  do
	. s h=$$CONVERTBASE^%CONVBASEUTIL(d,10,16)
	if (isn&(h'="0")) do
	. s h=$$CONVNEG^%CONVBASEUTIL(h,16)
	. s apnd="F"
	s i=$l(h)
	f  q:i'<l  s h=apnd_h,i=i+1
	q h
