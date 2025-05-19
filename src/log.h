#ifndef __LOG_H
#define __LOG_H

#include <stdio.h>

#include "util.h"

#ifndef LOG_END
#   define LOG_END "\n"
#endif

#define LOG_INFO  (1)
#define LOG_WARN  (2)
#define LOG_ERROR (3)

#define LOG(l, ...) do {                        \
    switch (l) {                                \
        case LOG_INFO:                          \
            PRINT_FILE_LOC(stderr);             \
            fprintf(stderr, "[INFO] ");         \
            fprintf(stderr, __VA_ARGS__);       \
            fprintf(stderr, LOG_END);           \
            break;                              \
        case LOG_WARN:                          \
            PRINT_FILE_LOC(stderr);             \
            fprintf(stderr, "[WARNING] ");      \
            fprintf(stderr, __VA_ARGS__);       \
            fprintf(stderr, LOG_END);           \
            break;                              \
        case LOG_ERROR:                         \
            PRINT_FILE_LOC(stderr);             \
            fprintf(stderr, "[ERROR] ");        \
            fprintf(stderr, __VA_ARGS__);       \
            fprintf(stderr, LOG_END);           \
            break;                              \
        default:                                \
            PRINT_FILE_LOC(stderr);             \
            fprintf(stderr, "[%s] ", #l);       \
            fprintf(stderr, __VA_ARGS__);       \
            fprintf(stderr, LOG_END);           \
            break;                              \
    }                                           \
} while(0)

#define FLOG(f, l, ...) do {                \
    switch (l) {                            \
        case LOG_INFO:                      \
            PRINT_FILE_LOC((f));            \
            fprintf((f), "[INFO] ");        \
            fprintf((f), __VA_ARGS__);      \
            fprintf((f), LOG_END);          \
            break;                          \
        case LOG_WARN:                      \
            PRINT_FILE_LOC((f));            \
            fprintf((f), "[WARNING] ");     \
            fprintf((f), __VA_ARGS__);      \
            fprintf((f), LOG_END);          \
            break;                          \
        case LOG_ERROR:                     \
            PRINT_FILE_LOC((f));            \
            fprintf((f), "[ERROR] ");       \
            fprintf((f), __VA_ARGS__);      \
            fprintf((f), LOG_END);          \
            break;                          \
        default:                            \
            PRINT_FILE_LOC((f));            \
            fprintf((f), "[%s] ", #l);      \
            fprintf((f), __VA_ARGS__);      \
            fprintf((f), LOG_END);          \
            break;                          \
    }                                       \
} while(0)

#endif  //__LOG_H
