#!/bin/bash

# A cpp wrapper used by the dtrace compiler that strips //-style comments
# and static inline functions

op=${@: -1}
args=${@:1:$#-1}

/usr/lib/cpp $args | sed '
	s^//.*^^
	/^.*static inline .*/,/^}/d
	/^$/d
	/PYGEN_NEXT = 1,/s/,//
' >> $op

