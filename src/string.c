#include "string.h"

bool string_equal(struct string a, struct string b) {
    if (a.length != b.length) return false;
    return (memcmp(a.cstr, b.cstr, a.length) == 0);
}
