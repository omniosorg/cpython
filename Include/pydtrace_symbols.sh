#!/bin/ksh

obj=${1:?obj}

# Find the function directly after the one that we want to annotate with
# the dtrace ustack helper

func=_PyEval_EvalFrameDefaultReal
sym=`/usr/bin/nm -hgp $obj \
    | grep ' T ' \
    | sort -n \
    | sed -n "/$func\$/{n;s/.* //;p;}"`

echo "#define PYDTRACE_AFTER_$func $sym"

