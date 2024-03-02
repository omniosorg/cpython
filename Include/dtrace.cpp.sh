#!/bin/bash

# A cpp wrapper used by the dtrace compiler that strips //-style comments
# and static inline functions

op=${@: -1}
args=${@:1:$#-1}

# Our native cpp cannot cope with this, and we still need to remove some
# pieces to keep the dtrace compiler happy.
: "${DTRACE_CPP:=/opt/gcc-10/bin/cpp}"

$DTRACE_CPP $args \
	-D'__attribute__(x)=' \
	-D'__alignof__(x)=' \
	-D'__aligned(x)=' \
	-D__builtin_va_list='void *' \
	-D_Bool=char \
	-D_Noreturn= \
	-Dstring=_string \
	-Dcounter=_counter \
	| sed '
	s^//.*^^
	/^.*static inline .*/,/^}/d
	/^.*static inline *$/,/^}/d
	/\* *self\>/s/self/_&/
	/ob_refcnt_split/,/};/ {
		s/};/} _u;/
	}
	/^$/d
' | tee dtrace.out >> $op

