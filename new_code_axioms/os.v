(* autogenerated by goose axiom generator; do not modify *)
From New.golang Require Import defn.

Section axioms.
Context `{ffi_syntax}.

Axiom File__Readdir : val.
Axiom File__Readdirnames : val.
Axiom DirEntry : go_type.
Axiom DirEntry__mset : list (string * val).
Axiom DirEntry__mset_ptr : list (string * val).
Axiom File__ReadDir : val.
Axiom ReadDir : val.
Axiom CopyFS : val.
Axiom Expand : val.
Axiom ExpandEnv : val.
Axiom Getenv : val.
Axiom LookupEnv : val.
Axiom Setenv : val.
Axiom Unsetenv : val.
Axiom Clearenv : val.
Axiom Environ : val.
Axiom PathError : go_type.
Axiom PathError__mset : list (string * val).
Axiom PathError__mset_ptr : list (string * val).
Axiom SyscallError : go_type.
Axiom SyscallError__mset : list (string * val).
Axiom SyscallError__mset_ptr : list (string * val).
Axiom SyscallError__Error : val.
Axiom SyscallError__Unwrap : val.
Axiom SyscallError__Timeout : val.
Axiom NewSyscallError : val.
Axiom IsExist : val.
Axiom IsNotExist : val.
Axiom IsPermission : val.
Axiom IsTimeout : val.
Axiom Process : go_type.
Axiom Process__mset : list (string * val).
Axiom Process__mset_ptr : list (string * val).
Axiom ProcAttr : go_type.
Axiom ProcAttr__mset : list (string * val).
Axiom ProcAttr__mset_ptr : list (string * val).
Axiom Signal : go_type.
Axiom Signal__mset : list (string * val).
Axiom Signal__mset_ptr : list (string * val).
Axiom Getpid : val.
Axiom Getppid : val.
Axiom FindProcess : val.
Axiom StartProcess : val.
Axiom Process__Release : val.
Axiom Process__Kill : val.
Axiom Process__Wait : val.
Axiom Process__Signal : val.
Axiom ProcessState__UserTime : val.
Axiom ProcessState__SystemTime : val.
Axiom ProcessState__Exited : val.
Axiom ProcessState__Success : val.
Axiom ProcessState__Sys : val.
Axiom ProcessState__SysUsage : val.
Axiom ProcessState : go_type.
Axiom ProcessState__mset : list (string * val).
Axiom ProcessState__mset_ptr : list (string * val).
Axiom ProcessState__Pid : val.
Axiom ProcessState__String : val.
Axiom ProcessState__ExitCode : val.
Axiom Executable : val.
Axiom File__Name : val.
Axiom O_RDONLY : val.
Axiom O_WRONLY : val.
Axiom O_RDWR : val.
Axiom O_APPEND : val.
Axiom O_CREATE : val.
Axiom O_EXCL : val.
Axiom O_SYNC : val.
Axiom O_TRUNC : val.
Axiom SEEK_SET : val.
Axiom SEEK_CUR : val.
Axiom SEEK_END : val.
Axiom LinkError : go_type.
Axiom LinkError__mset : list (string * val).
Axiom LinkError__mset_ptr : list (string * val).
Axiom LinkError__Error : val.
Axiom LinkError__Unwrap : val.
Axiom File__Read : val.
Axiom File__ReadAt : val.
Axiom File__ReadFrom : val.
Axiom noReadFrom__ReadFrom : val.
Axiom File__Write : val.
Axiom File__WriteAt : val.
Axiom File__WriteTo : val.
Axiom noWriteTo__WriteTo : val.
Axiom File__Seek : val.
Axiom File__WriteString : val.
Axiom Mkdir : val.
Axiom Chdir : val.
Axiom Open : val.
Axiom Create : val.
Axiom OpenFile : val.
Axiom Rename : val.
Axiom Readlink : val.
Axiom TempDir : val.
Axiom UserCacheDir : val.
Axiom UserConfigDir : val.
Axiom UserHomeDir : val.
Axiom Chmod : val.
Axiom File__Chmod : val.
Axiom File__SetDeadline : val.
Axiom File__SetReadDeadline : val.
Axiom File__SetWriteDeadline : val.
Axiom File__SyscallConn : val.
Axiom DirFS : val.
Axiom dirFS__Open : val.
Axiom dirFS__ReadFile : val.
Axiom dirFS__ReadDir : val.
Axiom dirFS__Stat : val.
Axiom ReadFile : val.
Axiom WriteFile : val.
Axiom File__Close : val.
Axiom Chown : val.
Axiom Lchown : val.
Axiom File__Chown : val.
Axiom File__Truncate : val.
Axiom File__Sync : val.
Axiom Chtimes : val.
Axiom File__Chdir : val.
Axiom File__Fd : val.
Axiom NewFile : val.
Axiom DevNull : val.
Axiom Truncate : val.
Axiom Remove : val.
Axiom Link : val.
Axiom Symlink : val.
Axiom unixDirent__Name : val.
Axiom unixDirent__IsDir : val.
Axiom unixDirent__Type : val.
Axiom unixDirent__Info : val.
Axiom unixDirent__String : val.
Axiom Getwd : val.
Axiom MkdirAll : val.
Axiom RemoveAll : val.
Axiom PathSeparator : val.
Axiom PathListSeparator : val.
Axiom IsPathSeparator : val.
Axiom Pipe : val.
Axiom Getuid : val.
Axiom Geteuid : val.
Axiom Getgid : val.
Axiom Getegid : val.
Axiom Getgroups : val.
Axiom Exit : val.
Axiom rawConn__Control : val.
Axiom rawConn__Read : val.
Axiom rawConn__Write : val.
Axiom Stat : val.
Axiom Lstat : val.
Axiom File__Stat : val.
Axiom Hostname : val.
Axiom CreateTemp : val.
Axiom MkdirTemp : val.
Axiom Getpagesize : val.
Axiom File : go_type.
Axiom File__mset : list (string * val).
Axiom File__mset_ptr : list (string * val).
Axiom FileInfo : go_type.
Axiom FileInfo__mset : list (string * val).
Axiom FileInfo__mset_ptr : list (string * val).
Axiom FileMode : go_type.
Axiom FileMode__mset : list (string * val).
Axiom FileMode__mset_ptr : list (string * val).
Axiom ModeDir : val.
Axiom ModeAppend : val.
Axiom ModeExclusive : val.
Axiom ModeTemporary : val.
Axiom ModeSymlink : val.
Axiom ModeDevice : val.
Axiom ModeNamedPipe : val.
Axiom ModeSocket : val.
Axiom ModeSetuid : val.
Axiom ModeSetgid : val.
Axiom ModeCharDevice : val.
Axiom ModeSticky : val.
Axiom ModeIrregular : val.
Axiom ModeType : val.
Axiom ModePerm : val.
Axiom fileStat__Name : val.
Axiom fileStat__IsDir : val.
Axiom SameFile : val.
Axiom fileStat__Size : val.
Axiom fileStat__Mode : val.
Axiom fileStat__ModTime : val.
Axiom fileStat__Sys : val.

End axioms.
