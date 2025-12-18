#include "base.h"
#include "arena.h"

static inline void arena_init(struct arena* arena, usize capacity) {
    void* mem = malloc(capacity);
    ASSERT(mem);
    arena->capacity = capacity;
    arena->mem_start = mem;
    arena->mem_cursor = mem;
}

struct arena arena_create(usize capacity) {
    struct arena arena = {0};

    arena_init(&arena, capacity);

    return arena;
}

void arena_destroy(struct arena* arena) {
    free(arena->mem_start);
    arena->mem_cursor = 0;
    arena->mem_start = 0;
    arena->capacity = 0;
}

void* arena_alloc(struct arena* arena, usize size) {
    if (arena->mem_start == 0) arena_init(arena, ARENA_DEFAULT_CAP);

    ASSERT(size <= arena->capacity - arena_used(arena));

    return (arena->mem_cursor += size) - size;
}

void arena_clear(struct arena* arena) {
    arena->mem_cursor = arena->mem_start;
}

usize arena_used(const struct arena* arena) {
    return (usize)arena->mem_cursor - (usize)arena->mem_start;
}

