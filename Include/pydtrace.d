/* Python DTrace provider */

provider python {
    probe function__entry(const char *, const char *, int);
    probe function__return(const char *, const char *, int);
    probe instance__new__start(const char *, const char *);
    probe instance__new__done(const char *, const char *);
    probe instance__delete__start(const char *, const char *);
    probe instance__delete__done(const char *, const char *);
    probe line(const char *, const char *, int);
    probe gc__start(int);
    probe gc__done(long);
    probe import__find__load__start(const char *);
    probe import__find__load__done(const char *, int);
    probe audit(const char *, void *);
};

#pragma D attributes Evolving/Evolving/Common provider python provider
#pragma D attributes Evolving/Evolving/Common provider python module
#pragma D attributes Evolving/Evolving/Common provider python function
#pragma D attributes Evolving/Evolving/Common provider python name
#pragma D attributes Evolving/Evolving/Common provider python args

#ifdef PYDTRACE_STACK_HELPER
/*
 * Python ustack helper.  This relies on the first argument (PyFrame *) being
 * on the stack; see Python/ceval.c for the contortions we go through to ensure
 * this is the case.
 *
 * On x86, the PyFrame * is two slots up from the frame pointer.
 *
 * Some details about this in "Python and DTrace in build 65":
 * https://movementarian.org/blog/posts/2007-05-24-python-and-dtrace-in-build-65
 */

#include "pyconfig.h"
#undef _POSIX_PTHREAD_SEMANTICS

#include <stdio.h>
#include <sys/types.h>

#define Py_EXPORTS_H
#define Py_IMPORTED_SYMBOL
#define Py_EXPORTED_SYMBOL
#define Py_LOCAL_SYMBOL

#define string	stringDTRACE

#include "pyport.h"
#include "object.h"
#include "code.h"

#include "frameobject.h"
#include "pystate.h"

#define self	selfDTRACE
#include "unicodeobject.h"

#undef self
#undef string

#include "pydtrace_offsets.h"
#include "pydtrace_symbols.h"

#define startframe _PyEval_EvalFrameDefaultReal
#define endframe PYDTRACE_AFTER__PyEval_EvalFrameDefaultReal

extern uintptr_t startframe;
extern uintptr_t endframe;

#define at_evalframe(addr) \
    ((uintptr_t)addr >= ((uintptr_t)&``startframe) && \
     (uintptr_t)addr < ((uintptr_t)&``endframe))

#define frame_ptr_addr ((uintptr_t)arg1 + sizeof(uintptr_t) * 2)
#define copyin_obj(addr, obj) ((obj *)copyin((uintptr_t)(addr), sizeof(obj)))

/*
** Check if the string is ASCII. Don't use bitfields, because the
** packing in GCC and D are different. BEWARE!!!.
*/
#define pystr_isascii(addr) \
    ((*(((char *)addr) + PYDTRACE_ASCII_OFFSET)) & PYDTRACE_ASCII_MASK)
#define pystr_len(addr) \
    (pystr_isascii(addr) ? (addr)->_base.length : \
    *(Py_ssize_t *)(((char *)(addr)) + PYDTRACE_UTF8_LENGTH_OFFSET))
#define pystr_addr(addr, addr2) \
    (pystr_isascii(addr) ? \
    (char *)(((char *)(addr2)) + PYDTRACE_PyASCIIObject_SIZE) : \
    (char *)*(uintptr_t *)(((char *)(addr)) + PYDTRACE_UTF8_OFFSET))

#define add_digit(nr, div) (((nr) / div) ? \
    (this->result[this->pos++] = '0' + (((nr) / div) % 10)) : \
    (this->result[this->pos] = '\0'))
#define add_char(c) \
    (this->result[this->pos++] = c)

dtrace:helper:ustack: /at_evalframe(arg0)/
{
	this->framep = *(uintptr_t *)copyin(frame_ptr_addr, sizeof(uintptr_t));
	this->frameo = copyin_obj(this->framep, struct _frame);
	this->codep = this->frameo->f_code;
	this->codeo = copyin_obj(this->codep, PyCodeObject);

	this->lineno = this->codeo->co_firstlineno +
	    (this->frameo->f_lasti == -1 ? 0 :
	        *copyin_obj(this->codeo->co_linenos + this->frameo->f_lasti,
		unsigned short));
	this->filenameo = copyin_obj(this->codeo->co_filename,
	    PyCompactUnicodeObject);
	this->nameo = copyin_obj(this->codeo->co_name, PyCompactUnicodeObject);

	this->len_filename = pystr_len(this->filenameo);
	this->len_name = pystr_len(this->nameo);

	this->len = 1 + this->len_filename + 1 + 5 + 2 + this->len_name + 1 + 1;

	this->result = (char *)alloca(this->len);
	this->pos = 0;
	add_char('@');

	copyinto(
	    (uintptr_t)pystr_addr(this->filenameo, this->codeo->co_filename),
	    this->len_filename, this->result + this->pos);
	this->pos += this->len_filename;

	add_char(':');
	add_digit(this->lineno, 10000);
	add_digit(this->lineno, 1000);
	add_digit(this->lineno, 100);
	add_digit(this->lineno, 10);
	add_digit(this->lineno, 1);
	add_char(' ');
	add_char('(');

	copyinto((uintptr_t)pystr_addr(this->nameo, this->codeo->co_name),
	    this->len_name, this->result + this->pos);
	this->pos += this->len_name;

	add_char(')');
	this->result[this->pos] = '\0';
	stringof(this->result);
}

dtrace:helper:ustack: /!at_evalframe(arg0)/
{
	NULL
}

#endif  /* PYDTRACE_STACK_HELPER */

