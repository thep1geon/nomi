#ifndef __TYPEDEF_H
#define __TYPEDEF_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <sys/types.h>

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef int8_t  i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;

typedef size_t  usize;
typedef ssize_t isize;

typedef float       f32;
typedef double      f64;
typedef long double f128; /*, or at least on my machine. */

#endif  /* __TYPEDEF_H */
