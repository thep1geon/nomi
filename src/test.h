#ifndef __TEST_H
#define __TEST_H

#include "log.h"

#define TEST_PASSING 0
#define TEST_FAILING 0

#define TEST(name) bool test__##name()

#define TEST_RUN(name) test__##name()

#define TEST_PASS() do {                        \
    LOG(TEST_PASSING, "%s passed", __func__);   \
    return 1;                                   \
} while (0)

#define TEST_FAIL() do {                        \
    LOG(TEST_FAILING, "%s failed", __func__);   \
    return 0;                                   \
} while (0)

#define TEST_ASSERT(expr) do {  \
    if (!(expr)) TEST_FAIL();   \
} while (0)

#define TEST_ASSERT_FALSE(expr) TEST_ASSERT(!(expr))

#define TEST_EXPECT(expr) do {  \
    if (!(expr)) TEST_FAIL();   \
    TEST_PASS();                \
} while (0)

#endif  //__TEST_H
