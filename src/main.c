#include <stdio.h>

#include "util.h"
#include "log.h"
#include "test.h"

TEST(suite);

int main(void) {
    TEST_RUN(suite);
    return 0;
}

TEST(adder) {
    TEST_EXPECT(21 + 21 == 42);
}

TEST(failer) {
    TEST_EXPECT(9 + 10 == 21);
}

TEST(passer) {
    TEST_EXPECT(1);
}

TEST(suite) {
    bool dummy = true;

    dummy = TEST_RUN(adder) & dummy;

    dummy = TEST_RUN(failer) & dummy;

    dummy = TEST_RUN(passer) & dummy;

    TEST_EXPECT(dummy);
}
