#include "Python.h"
#include "unicodeobject.h"
#include <stdlib.h>
#include <stdio.h>

int
main(int argc, const char **argv)
{
	PyCompactUnicodeObject o;
	unsigned char *p = (unsigned char *)(&o);

	memset(&o, '\0', sizeof(o));
	o._base.state.ascii = 1;
	while (*p == '\0')
		p++;

	printf("/* File auto-generated. DO NOT MODIFY MANUALLY */\n");
	printf("\n");
	printf("#ifndef PYDTRACE_OFFSETS_H\n");
	printf("#define PYDTRACE_OFFSETS_H\n");
	printf("\n");
	printf("#define PYDTRACE_ASCII_OFFSET %ld\n",
	    p - (unsigned char *)(&o));
	printf("#define PYDTRACE_ASCII_MASK %d\n", *p);
	printf("#define PYDTRACE_PyASCIIObject_SIZE %ld\n",
	    sizeof(PyASCIIObject));
	printf("#define PYDTRACE_UTF8_LENGTH_OFFSET %ld\n",
	    offsetof(PyCompactUnicodeObject, utf8_length));
	printf("#define PYDTRACE_UTF8_OFFSET %ld\n",
	    offsetof(PyCompactUnicodeObject, utf8));
	printf("\n");
	printf("#endif\n");
}

