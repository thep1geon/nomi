#ifndef __STRING_H
#define __STRING_H

#include "base.h"

struct string {
    const char* cstr;
    usize length;
};

#define STRING_FROM_PARTS(cstr, len) (struct string){cstr, len}
#define STRING(cstr) (struct string){cstr, strlen(cstr)}
#define STRING_LIT(strlit) {(strlit), sizeof(strlit)-1}

bool string_equal(struct string a, struct string b);

#endif  /* __STRING_H */
