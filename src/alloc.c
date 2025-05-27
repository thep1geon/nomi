#include "alloc.h"

struct allocator {
    void* (*alloc)(struct allocator*, usize);
    void (*free)(struct allocator*, void*);
};

void* allocator_alloc(struct allocator*, usize);
void allocator_free(struct allocator*, void*);

struct arena {
    struct allocator allocator;
    void* start; // Start of the buffer
    void* curr_ptr; // Current pointer in the buffer
};

void* arena_alloc(struct arena*, usize);
void* __arena_alloc(struct allocator*, usize);

void arena_free(struct arena*, void*);
void __arena_free(struct allocator*, void*);

