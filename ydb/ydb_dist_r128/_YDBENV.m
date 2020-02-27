;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;								;
; Copyright (c) 2018-2019 YottaDB LLC and/or its subsidiaries.	;
; All rights reserved.						;
;								;
;	This source code contains the intellectual property	;
;	of its copyright holder(s), and is made available	;
;	under a license.  If you do not know the terms of	;
;	the license, please stop and do not read further.	;
;								;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%YDBENV
;
; Initialize (create, recover, or leave untouched as appropriate)
; a YottaDB environment in the directory $ydb_dir (defaulting to
; values specified under the Defaults label).
; - If the environment does not exist, create it
; - If the database is currently open, or is not currently open
;   but was shut down cleanly, do nothing.
; - If the database not currently open, and was not shut down
;   cleanly, attempt to recover or rollback, depending on whether
;   the database is replicated.
; Generate on stdout a series of shell commands to set the
; environment variables necessary for YottaDB to operate. These
; commands will be incomplete in the event there is failure in
; mupip rollback / recover.
;
; Databases to be recovered or rolled back must use before-image
; journaling.
;
; This file is part of a group of five files: gdedefaults, ydb,
; ydb_env_set, ydb_env_unset, and _YDBENV.m (this program). To
; facilitate easy migration from GT.M to YottaDB, environments
; originally setup by sourcing the former's gtmprofile file and
; used with its gtm script are supported with YottaDB using the
; ydb_env_set file and ydb script, and the intent here is to make
; YottaDB completely upward compatible for GT.M applications.
;
; This program is intended to handle normal situations encountered
; in development, testing and lightweight production. Heavily
; customized high volume production instances, as well as advanced
; users are expected to create their own automation scripting and
; not use the automation scripting included with YottaDB. The program
; generates scripting to set GT.M environment variables so that
; programs written to use gtm* environment variables continue to work.
;
; Sourcing ydb_env_set or ydb_env_unset runs this program. ydb
; indirectly runs it by invoking ydb_env_set.
;
; Note:
;   * This program always runs in M mode
;   * $increment(zstmp) used in $zsearch() to avoid inadvertent reuse of search contexts
;
; One of the challenges of the ydb_env_set and ydb_env_unset pair of
; files is for the latter to distinguish between environment variables
; starting with ydb that are set before ydb_env_set is sourced
; vs. those set by ydb_env_set, especially because sourcing
; ydb_env_set must be idempotent. While the following technique is not
; foolproof, it is sufficiently robust for out-of-the box use, which
; is its intended use (advanced users and applications will likely
; have their own custom scripting). Assuming PPID is the pid of the
; parent shell from which this program is executed, ydb_unset_PPID is
; a list of environment variables whose values are set by sourcing the
; output of the set entryref, and which are unset by sourcing the
; output of the unset entryref.
;
; Top level entry not supported
	do Etrap
	set $ecode=",U255,"	; top level entry not supported
	quit			; should never get here because previous line should terminate process

set	; Intended to be the most common entry point to this routine (with unset likely not as common)
	new chset,currenv,dist,env,file,gtmgbldir,i,io,path,ppid,setcmd,setsep,tmp1,tmp2,tmp3,tmp4,unset,unsetcmd,ydbgbldir,ydbreplinst,ydbretention,zstmp
	do Etrap
	set io=$io
	use io:nowrap
	set unset=" "	; initialize list of variables to be unset
	do GetCurrEnv	; get current environment
	; Restore $ydb_routines / $gtmroutines in currenv, since ydb_env_set may have changed them to get this routine to run.
	if $data(currenv("ydb_tmp_routines")) set currenv("ydb_routines")=currenv("ydb_tmp_routines") kill currenv("ydb_tmp_routines")
	else  kill currenv("ydb_routines")
	if $data(currenv("ydb_tmp_gtmroutines")) set currenv("gtmroutines")=currenv("ydb_tmp_gtmroutines") kill currenv("ydb_tmp_gtmroutines")
	else  kill currenv("gtmroutines")
	do GetPPid	; get parent pid
	; Get the installation directory. Although $ydb_dist/$gtm_dist would normally be set and captured by GetCurrEnv,
	; if it is set by the mumps executable when run (vs. set in the shell environment), /proc/self/environ won't have the value
	; whereas $ztrnlnm() will.
	set dist=$ztrnlnm("ydb_dist")
	set:'$zlength(dist) dist=$ztrnlnm("gtm_dist")
	do FileTypeEnsure("ydb_dir")	; if $ydb_dir exists, ensure that it is a directory or a link
	do:'$data(env("ydb_dir","path"))&$data(env("ydb_dir"))&$zfind(env("ydb_dir"),"/")
	. set tmp1=$zparse(env("ydb_dir")),tmp2=$zlength(tmp1,"/")
	. set env("ydb_dir","directory")=$zpiece(tmp1,"/",1,tmp2-1)
	. set env("ydb_dir","name")=$zpiece(tmp1,"/",tmp2)
	do FileTypeEnsure("gtmdir")	; if $gtmdir exists, ensure that it is a directory or a link
	do:'$data(env("gtmdir","path"))&$data(env("gtmdir"))&$zfind(env("gtmdir"),"/")
	. set tmp1=$zparse(env("gtmdir")),tmp2=$zlength(tmp1,"/")
	. set env("gtmdir","directory")=$zpiece(tmp1,"/",1,tmp2-1)
	. set env("gtmdir","name")=$zpiece(tmp1,"/",tmp2)
	; create default environment and set ydb_dir and gtmdir
	do DirEnsure("ydb_dir","gtmdir") ; ensure a directory exists for $ydb_dir or $gtmdir
	do ExportEnv("ydb_dir",env("ydb_dir")),ExportEnv("gtmdir",env("gtmdir"))
	do DirEnsure("ydb_rel","gtmver")
	do ExportEnv("ydb_rel",env("ydb_rel")),ExportEnv("gtmver",env("gtmver"))
	; Get the character set for the exported environment, if saved by the invoking shell. Since this program always runs in M mode
	; the desired character set is saved by the shell prefixed by ydb_tmp_.
	set chset=$zconvert($select($data(currenv("ydb_tmp_ydb_chset")):currenv("ydb_tmp_ydb_chset"),$data(currenv("ydb_tmp_gtm_chset")):currenv("ydb_tmp_gtm_chset"),1:""),"u")
	do:$zlength(chset)
	. set:'("UTF-8"=chset!("M"=chset)) $ecode=",U249,"
	. ; Since ydb_chset and gtm_chset would have been saved in environment variables prefixed by ydb_tmp_ by ydb_env_set
	. ; must set currenv() nodes to the original values to ensure they are correctly restored by ydb_env_unset
	. set:$data(currenv("ydb_tmp_ydb_chset")) currenv("ydb_chset")=currenv("ydb_tmp_ydb_chset")
	. set:$data(currenv("ydb_tmp_gtm_chset")) currenv("gtm_chset")=currenv("ydb_tmp_gtm_chset")
	. do ExportEnv("ydb_chset",chset),ExportEnv("gtm_chset",chset)
	; ydb_dist is set here after setting ydb_chset since ydb_dist may need to point to
	; the utf8 subdirectory of the YottaDB installation directory if $ydb_dist is UTF-8.
	do ExportEnv("ydb_dist",dist_$select("UTF-8"=$get(chset):"/utf8",1:"")),ExportEnv("gtm_dist","$ydb_dist")
	set path=env("ydb_dir")_"/"_env("ydb_rel")
	; ydb_repl_instance is set here. Even for unreplicated environments without
	; a replication instance file, ydb_repl_instance is set, to facilitate turning
	; replication on and creating a replication instance file (the script does not
	; automatically create the file). If a replication instance file exists in
	; $ydb_dir/$ydb_rel/g, it is used, otherwise the default is yottadb.repl.
	; If a value for ydb_repl_instance or gtm_repl_instance is already defined, just use it.
	set ydbreplinst=$select($data(currenv("ydb_repl_instance")):currenv("ydb_repl_instance"),$data(currenv("gtm_repl_instance")):currenv("gtm_repl_instance"),1:"")
	do:'$zlength(ydbreplinst)
	. set ydbreplinst=path_"/g/yottadb.repl"
	. do:'$zlength($zsearch(ydbreplinst,$increment(zstmp)))
	. . set tmp1=$zsearch(path_"/g/*.repl",$increment(zstmp))
	. . set:$zlength(tmp1) ydbreplinst=tmp1
	do ExportEnv("ydb_repl_instance",ydbreplinst),ExportEnv("gtm_repl_instance",ydbreplinst)
	; set ydb_retention
	set ydbretention=$select($data(currenv("ydb_retention")):+currenv("ydb_retention"),$data(currenv("gtm_retention")):+currenv("gtm_retention"),1:0)
	set:'ydbretention ydbretention=42
	do ExportEnv("ydb_retention",ydbretention),ExportEnv("gtm_retention",ydbretention)
	; ydb_gbldir is set here after setting ydb_repl_instance and
	; ydb_retention because if an environment exists (determined
	; by the existence of a global directory), Robustify needs
	; $ydb_repl_instance to be set in case the environment is
	; replicated and ydb_retention to delete old prior generation
	; journal files.  If no environment exsists create it here.
	set ydbgbldir=$select($data(currenv("ydb_gbldir")):currenv("ydb_gbldir"),$data(currenv("gtmgbldir")):currenv("gtmgbldir"),1:"")
	if '($zlength(ydbgbldir)) do					; global directory not defined in environment
	. set ydbgbldir=path_"/g/yottadb.gld",tmp1=$zsearch(ydbgbldir,$increment(zstmp))
	. if $zlength(tmp1) set ydbgbldir=tmp1 do Robustify	; use existing in $ydb_dir/$ydb_rel/g/yottadb.gld
	. else  do
	. . set tmp1=$zsearch(path_"/g/*.gld",$increment(zstmp))	; $ydb_dir/$ydb_rel/g/yottadb.gld doesn't exist, look for ...
	. . if $zlength(tmp1) set ydbgbldir=tmp1 do Robustify		; any $ydb_dir/$ydb_rel/g/*.gld and use first one, if any exist.
	. . else  do	      	  	    		 		; no global directory - need to create default global directory & database
	. . . ; command is /bin/sh to feed lines to shell process because of YottaDB deviceparameter limit
	. . . open "dbcreate":(shell="/bin/sh":command="/bin/sh":stderr="dbcreateerr")::"pipe"
	. . . use "dbcreate"
	. . . write "export ydb_gbldir=",ydbgbldir,!,"export gtmgbldir=$ydb_gbldir",!
	. . . write "export ydb_dir=",env("ydb_dir"),!,"export gtmdir=",env("gtmdir"),!
	. . . write "export ydb_rel="_env("ydb_rel"),!,"export gtmver=",env("gtmver"),!
	. . . if $zsearch("./gdedefaults",$increment(zstmp)) write dist,"/yottadb -run GDE <gdedefaults",!
	. . . else  write dist,"/yottadb -run GDE <"_dist,"/gdedefaults",!
	. . . write dist,"/mupip create",!
	. . . write dist,"/mupip set -journal=""enable,on,before"" -region ""*""",!
	. . . write /eof
	. . . for  read tmp1 quit:$zeof			   ; read and discard stdout and stderr of "dbcreate" because we do nothing with it ...
	. . . use "dbcreateerr" for  read tmp2 quit:$zeof  ; but should read it to avoid "dbcreate" getting stalled ...
	. . . use io close "dbcreate"	       		   ; by a full pipe.
	else  do Robustify						; $ydb_gbldir and/or $gtmgbldir are set - use existing values
	do ExportEnv("ydb_gbldir",ydbgbldir),ExportEnv("gtmgbldir",ydbgbldir)
	; ydb_routines is set here. The object directory is determined by both the YottaDB release as well as
	; the character set (M/UTF-8). Shared libraries from plugins should also be included in ydb_routines,
	; after routines in $ydb_dir, to allow routines in $ydb_dir (which may be a development environment) to
	; take precedence over those in plugins.
	set path=path_"/o"_$select("UTF-8"=chset:"/utf8",1:"")_"*("_env("ydb_dir")_"/"_env("ydb_rel")_"/r "_env("ydb_dir")_"/r)"
	set tmp1=dist_"/plugin/o"_$select("UTF-8"=chset:"/utf8",1:"")_"/*.so"
	set tmp2=$zsearch(tmp1,$increment(zstmp))
	for  quit:""=tmp2  set path=path_" "_tmp2,tmp2=$zsearch(tmp1,zstmp)	; use the same search context to find all files
	set tmp1=dist_$select("UTF-8"=chset:"/utf8",1:"")
	set tmp2=$zsearch(tmp1_"/libyottadbutil.so",$increment(zstmp))	; if there is no libyottadbutil.so, check for libgtmutil.so, just ...
	set:'$zlength(tmp2) tmp2=$zsearch(tmp1_"/libgtmutil.so",$increment(zstmp))	; in case someone is trying to run this with GT.M
	set:$zlength(tmp2) path=path_" "_tmp2
	do ExportEnv("ydb_routines",path),ExportEnv("gtmroutines",path)
	; ydb_log is set here, with the directory structure created if it does not exist
	; ydb_tmp is set to the same value as ydb_log
	set tmp1=$get(currenv(("ydb_log"))),tmp2=$get(currenv(("gtm_log")))
	set (tmp3,tmp4)=$select($zlength(tmp1):tmp1,$zlength(tmp2):tmp2,1:"/tmp/yottadb/"_env("ydb_rel"))
	set tmp1=$get(currenv(("ydb_tmp_rel"))),tmp2=$get(currenv(("ydb_tmp_gtmver")))
	do:$zlength(tmp1)
	. set tmp4=$zpiece(tmp3,tmp1,1) for i=2:1:$zlength(tmp3,tmp1) set tmp4=tmp4_env("ydb_rel")_$zpiece(tmp3,tmp1,i)
	. set tmp3=tmp4
	if $zlength(tmp2) set tmp4=$zpiece(tmp3,tmp2,1) for i=2:1:$zlength(tmp3,tmp2) set tmp4=tmp4_env("gtmver")_$zpiece(tmp3,tmp2,i)
	do:""=$zsearch(tmp4,$increment(zstmp))
	. ; Release-specific directory (e.g. /tmp/yottadb/r1.23_x86_64) does not exist. Create it.
	. ; Note: One might be tempted to combine the "umask" and "chmod o-rwx" commands below into one "umask command
	. ;       But that might not be correct in case we also create /tmp/yottadb as part of the below "mkdir".
	. ;       In that case, we do not want to create /tmp/yottadb with no world execute permissions because the
	. ;       current YottaDB version is installed with no execute permissions for the world. Later if a different
	. ;       YottaDB version gets installed with execute permissions for the world, a ydb_env_set invocation using
	. ;       that version might not be able to access /tmp/yottadb with the restricted chmod. Hence we first do the
	. ;       mkdir with a "umask 0" and later do a chmod of just the subdirectory /tmp/yottadb/r1.23_x86_64.
	. zsystem "umask 0; mkdir -p "_tmp4
	. new line,worldexecute,ydbgroup
	. open "file":(shell="/bin/sh":command="ls -l "_dist_"/libyottadb.so":readonly)::"pipe"
	. use "file" read line use io close "file"
	. set worldexecute=$zextract(line,10)	; permissions are the first word in "line" so no need to do $zpiece before $zextract
	. set ydbgroup=$zpiece(line," ",4)
	. if "x"'=worldexecute do
	. . ; $ydb_dist/libyottadb.so does not have world execute permissions, restrict directory access to only user and group
	. . zsystem "chmod o-rwx "_tmp4
	. . ; ---------------------------------------------------------------------------------
	. . ; If currently running user is part of the group that libyottadb.so belongs to,
	. . ; then change the group of the created directory to the yottadb group. If not,
	. . ; we cannot change the group (chgrp would error out) so skip this step in that case.
	. . new user,index,membergroup
	. . open "file":(shell="/bin/sh":command="id":readonly)::"pipe"
	. . use "file" read line use io close "file"
	. . set user=$zpiece($zpiece(line,")",1),"(",2)
	. . set grouplist=$zpiece(line," groups=",2)	; gets list of group names that "user" is a member of
	. . ; Since every group is surrounded by parentheses all we need to do is check if "(ydbgroup)" exists in "grouplist"
	. . zsystem:$zfind(grouplist,"("_ydbgroup_")") "chgrp "_ydbgroup_" "_tmp4
	do ExportEnv("ydb_log",tmp4),ExportEnv("gtm_log",tmp4),ExportEnv("ydb_tmp",tmp4),ExportEnv("gtm_tmp",tmp4)
	; ydb_etrap is set here, followed by miscellaneous environment variables
	set tmp1=$select($data(currenv("ydb_etrap")):currenv("ydb_etrap"),$data(currenv("gtm_etrap")):currenv("gtm_etrap"),1:"Write:(0=$STACK) ""Error occurred: "",$ZStatus,!")
	do ExportEnv("ydb_etrap",tmp1),ExportEnv("gtm_etrap",tmp1)
	do:'$zfind($get(currenv("LD_LIBRARY_PATH")),dist) ExportEnv("LD_LIBRARY_PATH",dist_$select($data(currenv("LD_LIBRARY_PATH")):":"_currenv("LD_LIBRARY_PATH"),1:""))
	if $increment(zstmp)	       ; new search context for search in next line
	for  set tmp1=$zsearch("$ydb_dist/plugin/*.xc",zstmp) quit:""=tmp1  do
	. set tmp2=$zparse(tmp1,"name")
	. do ExportEnv("ydb_xc_"_tmp2,tmp1),ExportEnv("GTM_XC_"_tmp2,tmp1)
	set tmp1=currenv("PATH"),tmp2=":"_tmp1_":"
	set:'$zfind(tmp2,":"_dist_":") tmp1=dist_":"_tmp1
	set tmp3=$zsearch("$ydb_dist/plugin/bin",$increment(zstmp))
	set:$zlength(tmp3)&'$zfind(tmp2,":"_tmp3_":") tmp1=tmp3_":"_tmp1
	do ExportEnv("PATH",tmp1)
	; Set environment variables to restore ydb_dist / gtm_dist in the event they were set before invoking ydb_env_set
	do:$data(currenv("ydb_tmp_ydb_dist"))
	. do ExportEnv("ydb_sav_"_ppid_"_ydb_dist",currenv("ydb_tmp_ydb_dist"))
	. set unset=unset_"ydb_tmp_ydb_dist "
	do:$data(currenv("ydb_tmp_gtm_dist"))
	. do ExportEnv("ydb_sav_"_ppid_"_gtm_dist",currenv("ydb_tmp_gtm_dist"))
	. set unset=unset_"ydb_tmp_gtm_dist "
	; As unset always has a extraneous trailing space, the following omits the last character of unset when writing
	write:" "'=unset setcmd,"ydb_unset_",ppid,setsep,"""",$zextract(unset,2,$zlength(unset)-1),"""",!
	write "alias gde",setsep,"""$ydb_dist/yottadb -run GDE""",!
	quit

unset	; Unset the environment set by entryref set
	new currenv,io,ppid,prefix,setcmd,setsep,startpos,unsetcmd,var
	do Etrap
	set io=$io
	use io:nowrap
	set unset=" "	; initialize list of variables to be unset
	do GetCurrEnv	; get current environment
	do GetPPid	; get parent pid
	set var="ydb_unset_"_ppid
	write:$data(currenv(var)) unsetcmd,currenv(var)," ",var,!
	set (var,prefix)="ydb_sav_"_ppid_"_",startpos=1+$zlength(prefix)
	for  set var=$order(currenv(var)) quit:startpos'=$zfind(var,prefix)  write setcmd,$zextract(var,startpos,$zlength(var)),setsep,"'",currenv(var),"'",!
	quit

; Utility labels, expected to be called only from within the routine

DirEnsure(ydbvar,gtmvar)
	; Cases
	;   One is defined by the other is not
	;   Both are defined
	;   Neither ydbvar nor gtmvar is defined
	;     ydbvar default exists: define both to point to it
	;     ydbvar default does not exist
	;       gtmvar default exists: define both to point to it
	;	gtmver default does not exist: create ydbvar default & define both to point to it
	new io,zdir
	set io=$io,zdir=$zdirectory
	set:'$data(env(ydbvar)) env(ydbvar)=$get(currenv((ydbvar)))
	set:'$data(env(gtmvar)) env(gtmvar)=$get(currenv((gtmvar)))
	if $zlength($get(env(ydbvar))) do
	. ; ydbvar is defined
	. do FileTypeEnsure(ydbvar,1)			; does directory exist for ydbvar?
	. if $data(env(ydbvar,"path")) do		; if it exists, use it
	. . set:'$zlength($get(env(ydbvar))) env(ydbvar)=env(ydbvar,"path")
	. . do FileTypeEnsure(gtmvar,1)
	. . ; if $gtmvar exists and is different from ydbvar, it is an error
	. . set:$data(env(gtmvar,"path"))&'$$PathSame(env(gtmvar,"path"),env(ydbvar,"path")) $ecode=",U251,"
	. . set:'$zlength($get(env(gtmvar))) env(gtmvar)=$select($data(env(gtmvar,"path"))#10:env(gtmvar,"path"),1:env(ydbvar,"path"))
	. else  do		       	   	     	; directory for ydbvar does not exist, need to create it
	. . do:'$data(env(ydbvar,"create")) GetDefaults
	. . set $zdirectory=$select($data(env(ydbvar,"directory")):env(ydbvar,"directory"),$data(env("ydb_dir","path")):env("ydb_dir","path"),1:$zparse(env(ydbvar),"directory"))
	. . zsystem @env(ydbvar,"create")		; create the YottaDB directory
	. . do FileTypeEnsure(ydbvar,1)			; verify that it exists
	. . set:'$zlength($zsearch(env(ydbvar,"path"),$increment(zstmp))) $ecode=",U253,"
	. . do FileTypeEnsure(gtmvar,1)
	. . ; if $gtmvar exists and is different from ydbvar, it is an error
	. . set:$data(env(gtmvar,"path"))&'$$PathSame(env(gtmvar,"path"),env(ydbvar,"path")) $ecode=",U251,"
	. . set:'$zlength($get(env(gtmvar))) env(gtmvar)=$select($data(env(gtmvar,"path"))#10:env(gtmvar,"path"),1:env(ydbvar,"path"))
	else  if $zlength($get(env(gtmvar))) do
	. ; ydbvar is not defined but gtmvar is defined
	. do FileTypeEnsure(gtmvar,1)	     	 	; does directory exist for gtmvar?
	. if $data(env(gtmvar,"path")) do	       	; if it exists, use it
	. . set:'$zlength($get(env(ydbvar))) env(ydbvar)=$select($data(env(ydbvar,"path"))#10:env(ydbvar,"path"),1:env(gtmvar,"path"))
	. else  do					; directory for gtmvar does not exist, need to create it
	. . do:'$data(env(gtmvar,"create")) GetDefaults
	. . set $zdirectory=$select($data(env(gtmvar,"directory")):env(gtmvar,"directory"),$data(env("gtmdir","path")):env("gtmdir","path"),1:$zparse(env(gtmvar),"directory"))
	. . zsystem @env(gtmvar,"create")		; create the gtmvar directory
	. . do FileTypeEnsure(gtmvar,1)			; verify that it exists
	. . set:'$zlength($zsearch(env(gtmvar,"path"),$increment(zstmp))) $ecode=",U250,"
	. . set env(ydbvar)=$select($data(env(ydbvar,"path"))#10:env(ydbvar,"path"),1:env(gtmvar,"path"))
	else  do
	. ; Neither ydbvar nor gtmvar is defined
	. do:'($data(env(ydbvar,"default"))&$data(env(gtmvar,"default"))) GetDefaults
	. set:$data(env(ydbvar,"default"))#10 env(ydbvar)=env(ydbvar,"default")
	. set:$data(env(gtmvar,"default"))#10 env(gtmvar)=env(gtmvar,"default")
	. set $zdirectory=$select($data(env(ydbvar,"directory")):$zsearch(env(ydbvar,"directory"),$increment(zstmp)),$data(env("ydb_dir","path")):env("ydb_dir","path"),1:env("gtmdir","path"))
	. do FileTypeEnsure(ydbvar,1)
	. if $data(env(ydbvar,"path")) do		; if default directory exists for ydbvar, use it
	. . do FileTypeEnsure(gtmvar,1)
	. . if $data(env(gtmvar,"path")) do		; if default directory exists for gtmvar, ensure it is the same as ydbvar
	. . . set:'$$PathSame(env(gtmvar,"path"),env(ydbvar,"path")) $ecode=",U251,"
	. . else  do					; default directory for gtmvar does not exist, create link to ydbvar
	. . . zsystem @env(gtmvar,"link")		; Link to it from the GT.M name
	. . . set:'$zlength($zsearch(env(gtmvar,"default"),$increment(zstmp))) $ecode=",U252,"
	. else  do					; default directory for ydbvar does not exist
	. . do FileTypeEnsure(gtmvar,1)
	. . if $data(env(gtmvar,"path")) do		; if default directory exists for gtmvar, use it
	. . . zsystem @env(ydbvar,"link")		; Link to it from the YottaDB name
	. . . set:'$zlength($zsearch(env(ydbvar,"default"),$increment(zstmp))) $ecode=",U252,"
	. . else  do					; neither default exists, create ydbvar default
	. . . zsystem @env(ydbvar,"create")		; create the YottaDB directory
	. . . do FileTypeEnsure(ydbvar,1)		; verify that it exists
	. . . set:'$zlength($zsearch(env(ydbvar,"default"),$increment(zstmp))) $ecode=",U253,"
	. . . zsystem @env(gtmvar,"link")		; Link to it from the GT.M name
	. . . set:'$zlength($zsearch(env(gtmvar,"default"),$increment(zstmp))) $ecode=",U252,"
	set $zdirectory=zdir				; Restore current directory to that at process entry
	quit

Etrap	; Set error handler to print error message and return error code to shell
	open "/proc/self/fd/2" ; open stderr for output if needed
	set $etrap="set $etrap=""use """"/proc/self/fd/2"""" write $zstatus,! zshow """"*"""" zhalt 1"" set tmp1=$zpiece($ecode,"","",2),tmp2=$text(@tmp1) if $zlength(tmp2) use ""/proc/self/fd/2"" write $text(+0),@$zpiece(tmp2,"";"",2),! zshow ""*"" zhalt +$extract(tmp1,2,$zlength(tmp1))"
	quit

ExportEnv(var,value)
	; Write an export statement to set the environment var to value
	; If var has an existing value, write an export statement to save the old value
	;   unless one already exists (since invoking the set label is idempotent)
	; Else add to the list of variables to be unset when the unset label is invoked
	; currenv and ppid should have been set prior to calling this label
	new envsav,envval
	write setcmd,var,setsep,"'",value,"'",!	; write even if already in the enviroment because it may not have been exported
	if $data(currenv(var)) do
	. set envsav="ydb_sav_"_ppid_"_"_var
	. do:'$zfind(unset," "_envsav_" ")	; variables in unset have spaces on both sides to avoid substring matches
	. . write setcmd,envsav,setsep,"'",currenv(var),"'",!
	. . set unset=unset_envsav_" "
	else  set unset=unset_var_" "
	quit

FileType(fpath,followlink)
	; Determine type of file at fpath (assumption is that existence is already confirmed)
	; followlink true means dereference link if fpath is a link
	; Future todo: use stat() instead of file command if POSIX plugin is installed
	new io,line,type
	set io=$io
	open "file":(shell="/bin/sh":command="file "_$select(followlink:"-L ",1:"-h ")_fpath:readonly)::"pipe"
	use "file" read line use io close "file"
	set type=$zpiece(line,fpath_": ",2)
	quit $select($zfind(type,"symbolic link to "):"link",$zfind(type,"directory"):"directory",1:"other")

FileTypeEnsure(envvar,followlink)
	; Make sure environment variable envvar, if defined:
	;   - refers to either a link or a directory if followlink is undefined or otherwise evaluates to 0
	;   - refers to a directory otherwise
	new flag
	if '($data(env(envvar))#10) set env(envvar)=$get(currenv(envvar)),flag=1
	else  set flag=0
	if $zlength(env(envvar)) do
	. set env(envvar,"path")=$zsearch(env(envvar),$increment(zstmp))
	. if $zlength(env(envvar,"path")) do
	. . set env(envvar,"type")=$$FileType(env(envvar,"path"),+$get(followlink))
	. . zsy "mkdir -p "_env(envvar,"path")_"/r"
	. . set:"other"=env(envvar,"type") $ecode=",U254,"	; error if it exists and is not a link or a directory
	. else  kill env(envvar,"path")	   			; path does not exist
	else  zwithdraw:flag env(envvar)			; remove null value if set by this function
	quit

GetCurrEnv
	; Get current environment
	; io should have been set before calling this label
	new file,i,line,tmp
	set file="/proc/self/environ"
	open file:readonly use file
	set line="" for  read tmp quit:$zeof  set line=line_tmp
	use io close file
	for i=1:1:$zlength(line,$zchar(0)) set tmp=$zpiece(line,$zchar(0),i) if ""'=tmp s currenv($zpiece(tmp,"=",1))=$zpiece(tmp,"=",2,$zlength(tmp,"="))
	quit

GetDefaults
	; Get default values for environment variables
	new i,line,tmp1,tmp2,var
	for i=2:1 set tmp1=$text(Defaults+i),line=$zpiece(tmp1,"; ",2,$zlength(tmp1,":")) quit:""=line  do
	. set var=$zpiece(line,":",1)
	. set tmp1=$zpiece(line,":",2)
	. set:'$data(env(var,"directory"))&$zlength(tmp1) env(var,"directory")=$zparse(tmp1)
	. set tmp2=$zpiece(line,":",3)
	. set:'$data(env(var,"name"))&$zlength(tmp2) env(var,"name")=tmp2
	. do:'$data(env(var,"default"))
	. . if $zlength(tmp1)&$zlength(tmp2) set env(var,"default")=env(var,"directory")_"/"_env(var,"name")
	. . else  xecute "set env(var,""default"")="_$zpiece(line,":",6)
	. set:'$data(env(var,"create")) env(var,"create")=$zpiece(line,":",4)
	. set:'$data(env(var,"link")) env(var,"link")=$zpiece(line,":",5)
	quit

GetPPid
	; Get parent pid; initialize related variables based on parent shell type
	; io should have been set before calling this label
	new file,line,tmp1,tmp2
	set file="/proc/self/stat"
	open file:readonly use file
	read line
	use io close file
	set ppid=$zpiece(line," ",4)
	set file="/proc/"_ppid_"/cmdline"
	open file:readonly use file
	read line
	use io close file
	set tmp1=$zlength(line)-1,tmp2=$zextract(line,tmp1-2,tmp1)
	if "csh"=tmp2!("-sh"=tmp2) set setcmd="setenv ",setsep=" ",unsetcmd="unsetenv " ; tcsh or csh
	else  set setcmd="export ",setsep="=",unsetcmd="unset "	 		      	; all other shells
	quit

PathSame(path1,path2)
	; determine whether path1 and path2 are the same
	new io,realpath1,realpath2
	set io=$io
	open "realpath":(shell="/bin/sh":command="realpath "_path1_" "_path2:readonly)::"pipe"
	use "realpath" read realpath1,realpath2 use io close "realpath"
	quit realpath1=realpath2

Robustify	; rollback / recover an existing database if needed
	new allok,cmd,cutoff,fhead,field,fname,io,jnlfile,jnlfilelist,line,region,replon,sem,semid,semkey,timestamp,year
	set io=$io
	view "setenv":"ydb_dir":env("ydb_dir"),"setenv":"ydb_rel":env("ydb_rel"),"setenv":"ydb_gbldir":ydbgbldir,"setenv":"ydb_repl_instance":ydbreplinst
	; create files for any regions that don't have database files; they're likely temporary regions
	; ignore stderr as mupip create will likely complain but attempt to read one line from stdin to ensure command completes
	open "create":(shell="/bin/sh":command="$ydb_dist/mupip create":readonly)::"pipe"
	use "create" read line use io close "create"
	open "fhead":(shell="/bin/sh":command="$ydb_dist/mupip dumpfhead -region ""*"" 2>&1")::"pipe"
	use "fhead"
	for  read line quit:$zeof  do
	. set:"%"=$zextract(line,1,1) $ecode=",U245,"	; mupip dumpfhead reports an error, e.g, a database file does not exist
	. if 1<$zlength(line,"Fileheader dump of region ") set region=$zpiece(line,"Fileheader dump of region ",2)
	. else  if 1<$zlength(line,"Dumping fileheader of ") set fhead(region,"fname")=$zpiece(line,"Dumping fileheader of ",2)
	. else  set fhead(region,$zpiece(line,"""",2))=$zpiece(line,"=",2)
	use io close "fhead"
	open "ipcs -s":(shell="/bin/sh":command="ipcs -s":readonly)::"pipe"
	use "ipcs -s"
	for  read line quit:$zeof  do
	. set semkey=$zpiece(line," ",1)
	. set semid=$zpiece(line," ",2)
	. set:semkey?1"0x"."0" sem(semid)=""	; this pattern looks for a private semaphore (with a key of 0x00000000)
	use io close "ipcs -s"
	; Check whether every region is either not open, or open with an existing shared memory segment
	; If all regions satisfy one or the other requirement, there is nothing for robustify to do
	set allok=1,region=""	; In next line, verify that every region is either not open, or if open has a semaphore
	for  set region=$order(fhead(region)) quit:'$zlength(region)  set allok=allok*((-1=fhead(region,"sgmnt_data.semid")!$data(sem(fhead(region,"sgmnt_data.semid")))))
	do:'allok		; Rollback / recover database if not allok
	. set region=""
	. for  set region=$order(fhead(region)) quit:""=region  do:-1'=fhead(region,"sgmnt_data.semid")
	. . set:2'=fhead(region,"sgmnt_data.jnl_state") $ecode=",U248,"	; rollback/recovery ruled out because open region not before-image journaled
	. . if '$data(replok) do
	. . . set replok=fhead(region,"sgmnt_data.repl_state")	; set replication state to that of the first region requiring rollback/recovery
	. . . set jnlfilelist=$zpiece($zwrite(fhead(region,"sgmnt_data.jnl_file_name"),1),$zchar(0),1)	; initialize region list with first region
	. . else  do
	. . . set:replok'=fhead(region,"sgmnt_data.repl_state") $ecode=",U247,"	; error because not all regions have same replication state
	. . . set jnlfilelist=jnlfilelist_","_$zpiece($zwrite(fhead(region,"sgmnt_data.jnl_file_name"),1),$zchar(0),1)	; add this region's journal file to list
	. set cmd="$ydb_dist/mupip journal "_$select(replok:"-rollback -backward ""*""",1:"-recover -backward "_jnlfilelist)
	. open "robustify":(shell="/bin/sh":command="/bin/sh")::"pipe"
	. use "robustify"
	. write cmd,!
	. write /eof
	. for  read line quit:$zeof  use "/proc/self/fd/2" write line,! use "robustify"
	. use io close "robustify"
	. set:$zclose $ecode=",U246,"	; error - mupip journal -rollback/-recover returned non-zero status
	; Clean up prior generation journal files older than ydbretention
	set tmp=$zpiece($horolog,",",1)
	set year=$zdate(tmp,"YYYY")
	set day=$ztranslate($zjustify(tmp-$$FUNC^%DATE("1/1/"_year)+1,3)," ",0)	; day of the year left justified to three digits
	set cutoff=year_day-ydbretention_"000000"		; journal files with a timestamp smaller than this will be deleted
	set region=""
	for   set region=$order(fhead(region)) quit:""=region  do
	. set jnlfile=$zsearch($zpiece($zwrite(fhead(region,"sgmnt_data.jnl_file_name"),1),$zchar(0),1)_"_*",$increment(zstmp))
	. for  quit:""=jnlfile  do
	. . set timestamp=$zpiece($zparse(jnlfile,"type"),"_",2)
	. . if timestamp>cutoff set jnlfile=""	; if jnlfile is newer than cutoff, done looking for journal files
	. . else  do		; delete old journal file and find next candidate for deletion
	. . . open jnlfile close jnlfile:delete
	. . . use "/proc/self/fd/2" write jnlfile," deleted",! use io
	. . . set jnlfile=$zsearch($zpiece($zwrite(fhead(region,"sgmnt_data.jnl_file_name"),1),$zchar(0),1)_"_*",zstmp)
	quit

; End of code in routines - what follows are defaults and errors

Defaults
	; Default values for environment variables
	; ydb_dir:$HOME:.yottadb:"mkdir -p "_env(ydbvar,"name")_"/r":"ln -s "_env(gtmvar,"name")_" "_env(ydbvar,"name")
	; gtmdir:$HOME:.fis-gtm:"mkdir -p "_env(gtmvar,"name")_"/r":"ln -s "_env(ydbvar,"name")_" "_env(gtmvar,"name")
	; ydb_rel:::"mkdir -p "_env(ydbvar)_"; cd "_env(ydbvar)_"; mkdir -p g o o/utf8 r ; cd ..":"ln -s "_env(gtmvar)_" "_env(ydbvar):$zpiece($zyrelease," ",2)_"_"_$zpiece($zyrelease," ",4)
	; gtmver:::"mkdir -p "_env(gtmvar)_"; cd "_env(gtmvar)_"; mkdir -p g o o/utf8 r ; cd ..":"ln -s "_env(ydbvar)_" "_env(gtmvar):$zpiece($zversion," ",2)_"_"_$zpiece($zversion," ",4)

;	Error message texts
U245	;"-F-DUMPFHEADERR MUPIP DUMPFHEAD reports error: ",line
U246	;"-F-MUPIPERR command """_cmd_""" terminated with non-zero status ("_$zclose_")"
U247	;"-F-INCONSISTENTREPL replication state "_fhead(region,"sgmnt_data.repl_state")_" for region """_region_" does not match that of prior regions"
U248	;"-F-NOTBEFOREIMAGEJOURNAL backward rollback/recover not possible because region """_region_""" does not have before-image journaling"
U249	;"-F-INVCHSET """_chset_""" is not a valid character set"
U250	;"-F-CREATEFAIL unable to create directory "_env(gtmvar)
U251	;"-F-YDBGTMMISMATCH YottaDB variable "_ydbvar_"="_env(ydbvar,"path")_" is not equal to GT.M variable "_gtmvar_"="_env(gtmvar,"path")
U252	;"-F-LINKFAIL unable to create link "_env(gtmvar)_" to "_env(ydbvar)
U253	;"-F-CREATEFAIL unable to create directory "_env(ydbvar)
U254	;"-F-REQLINKORDIR type of "_envvar_"="_env(envvar,"path")_" - """_env(envvar,"type")_""" is neither a directory nor a symbolic link"
U255	;"-F-BADINVOCATION Must invoke as yottadb -run set^"_$text(+0)_" or yottadb -run unset^"_$text(+0)
