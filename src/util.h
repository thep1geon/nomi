#ifndef __UTIL_H
#define __UTIL_H

#include <stdint.h>
#include <stdbool.h>

#define _STR(X) #X
#define STR(X) _STR(X)

#define ARR_LEN(xs) (sizeof((xs))/sizeof((*xs)))

#define PRINT_FILE_LOC(f) fprintf((f), "%s:%d: ", __FILE__, __LINE__)

// TODO: come up with a prefix for these so they don't conflict with other libraries
typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef int8_t  i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;

typedef float f32;
typedef double f64;

#endif  //__UTIL_H
