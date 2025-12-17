#ifndef __DS_H
#define __DS_H

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stddef.h>
#include <string.h>

#include "typedef.h"

/*
 * Generic Functions for working with string-hashmap like data structures.
 *
 * After watching a clip from Tsoding where he was talking about why he doesn't
 * use templated generics via macros and instead manually writes a new type
 * everytime he wants a dynamic array (for example) of a new type, I have been
 * moved to his approach as well. His rationale was duck typing. If it walks 
 * like a duck, quacks like a duck, it is a duck. Similarly, if it has all the
 * fields of a dynamic array it is a dynamic array. This leads to more
 * extensible code via a system of interfaces that naturally form when you start
 * programming like this.
 *
 * Instead of having code generated for a specific type which a type parameter
 * and all the "methods" being generated along side it, you simply write up a new
 * type following a specific schema, and all the existing code for similiarly
 * typed objects will just work with it.
 *
 * An example here is a dynamic array. At the very core, a dynamic array is just
 * a pointer to an array with two other fields which say how many items it has
 * and how large the array is. So, by our system of duck typing, if a structure
 * has these three fields, it is a valid dynamic array; This keeps the door open
 * for more extensible code, however. If we wanted to add more fields to this
 * dynamic array, we can do so without disrupting the function of the dynamic
 * array. This also allows for a single-unified interface for working with a
 * specific "interface". We only need one `dynarray_append` function (macro) to
 * work with anything like "looks" like a dynamic array. 
 *
 * Using this approach we can make a simple string-hashmap that works with this
 * principle. As long as you have a structure that follows the correct layout
 * of a string-hashmap, it is a string-hashmap and will work with our interface.
 *
 * Schema for a String-Hashmap:
 *
 * struct string_hashmap {
 *     // actual key-value-pair stucture. Can be named anything (or nothing at all ;))
 *     struct {
 *         const char* key; // key part of the key-value pair
 *         bool occupied;   // flag to denote empty slots
 *         T value;         // your data here (must be named `value`)
 *     }* items;            // array of the slots
 *     usize capacity;      // total numbers of slots in the hashmap
 *     usize size;          // number of taken spots in the hashmap
 * };
 *
 * String-Hashmaps have an optional little bit of initialization:
 *  1. You must allocate a block of memory for the slots
 *  2. You must set the number of items the block of memory can hold
 *
 * For example:
 *
 * ```c
 *  struct hashtable table = {0};
 *  size_t table_size = 1024;
 *  table.items = calloc(sizeof(struct slot), table_size);
 *  table.capacity = table_size;
 * ```
 *
 * initializes `table` to be in a valid state. This way of doing is great if you
 * don't want to use the libc memory allocator. In the future there will be a
 * way to use custom allocators even when the functions/macros allocate memory
 * for you.
 *
 * But! If you don't want to do all of that, you can choose to just
 * zero-initialize the hashmap and let the functions initialize everything
 * for you. This abstraction does come at the cost of using libc's calloc, so
 * if you want to use your own allocator, do it yourself!
 * */

#define STRING_HASHMAP_DEFAULT_CAP (1024)

#define STRING_HASHMAP_KV_FIELDS const char* key; bool occupied
#define STRING_HASHMAP_FILEDS usize capacity; usize size

usize strhash(const char* key);

void* __string_hashmap_get(void* items, usize item_size, usize items_count,
                           usize offset_of_occupied, usize offset_of_value,
                           const char* key);

#define STRING_HASHMAP_GET(table, _key) \
        __string_hashmap_get( \
                             (table).items, \
                             sizeof((table).items[0]), \
                             (table).capacity, \
                             (usize)&table.items[0].occupied - (usize)&table.items[0], \
                             (usize)&table.items[0].value - (usize)&table.items[0], \
                             _key)

void __string_hashmap_put(void** items, usize item_size, usize* items_count, 
                          usize* table_size, usize offset_of_occupied,
                          usize offset_of_value, char* key, void* value);

#define STRING_HASHMAP_PUT(table, _key, _value) \
    __string_hashmap_put( \
                         (void**)&(table).items, \
                         sizeof((table).items[0]), \
                         &(table).capacity, \
                         &(table).size, \
                         (usize)&table.items[0].occupied - (usize)&table.items[0], \
                         (usize)&table.items[0].value - (usize)&table.items[0], \
                         _key, \
                         _value)

/* 
 * Dynamic Arrays
 *
 * Schema for a Dynamic Array
 *
 * struct my_dynarray {
 *      T* at;          // pointer to the array
 *      usize capacity;   // size of the array in terms of the element type
 *      usize length;     // the length of the array thus far
 * };
 *
 * No special initialization is required unless you want to set specific
 * values ahead of time.
 * */

#define DYNARRAY_FIELDS usize capacity; usize length

#define DYNARRAY_APPEND(da, i) do { \
    if ((da).length >= (da).capacity) { \
        if ((da).capacity == 0) (da).capacity = 8;\
        else (da).capacity *= 2;\
        (da).at = realloc((da).at, sizeof(i)*(da).capacity);\
    }\
    (da).at[(da).length++] = i;\
} while (0)

#define DYNARRAY_CLEAR(da) (da).length = 0

#define DYNARRAY_FREE(da) free((da).at); DYNARRAY_CLEAR((da))

#define DYNARRAY_FOR_EACH(da, e) \
    for (usize __iter = 0; __iter < (da)->length && (e = &(da)->at[__iter], true); ++__iter)

#ifdef DS_IMPLEMENTATION

usize strhash(const char* key) {
    usize P = 2468047;
    usize hash = 0; 
    usize p = P;
    usize key_length = strlen(key);

    for (usize i = 0; i < key_length; ++i) {
        for (usize j = 0; j < i; ++j) {
            p *= P;
        }

        hash = (hash*(key_length-i)*i + ((usize)*key+i)*i) << (i);
        hash += key_length * i * p * (key[i] * key[i]);
        hash *= P*p;
    }

    return hash;
}

void* __string_hashmap_get(void* items, usize item_size, usize items_count,
                           usize offset_of_occupied, usize offset_of_value,
                           const char* key) {
    char* slot;
    const char* slot_key;
    i32* occupied;
    void* value;
    usize hash;
    usize initial_hash;

    if (items_count == 0) return NULL;

    hash = strhash(key) % items_count;
    initial_hash = hash;

    while (1) {
        slot = (char*)items + hash*item_size;
        slot_key = *(char**)slot;
        occupied = (i32*)(slot + offset_of_occupied);
        value = slot + offset_of_value;

        if (*occupied && strcmp(slot_key, key) != 0) {
            hash += 1;
            hash %= items_count;

            if (hash == initial_hash) return NULL;
        } else break;

    }

    if (!(*occupied)) return NULL;
    return value;
}

void __string_hashmap_put(void** items, usize item_size, usize* items_count, 
                          usize* table_size, usize offset_of_occupied,
                          usize offset_of_value, char* key, void* value) {
    char* slot;
    char** slot_key;
    i32* occupied;
    void* slot_value;
    usize hash;

    if (*items_count == 0) {
        *items = calloc(item_size, STRING_HASHMAP_DEFAULT_CAP);
        *items_count = STRING_HASHMAP_DEFAULT_CAP;
    }

    hash = strhash(key) % *items_count;

    slot = (char*)*items + hash*item_size;
    slot_key = (char**)slot;
    occupied = (i32*)(slot + offset_of_occupied);
    slot_value = (void*)(slot + offset_of_value);

    if (!(*occupied)) {
        *slot_key = key;
        *occupied = 1;
        memcpy(slot_value, value, item_size - offset_of_value);
        *table_size += 1;
    } else {
        while (1) {
            slot = (char*)*items + hash*item_size;
            slot_key = (char**)slot;
            occupied = (i32*)(slot + offset_of_occupied);
            slot_value = (void**)(slot + offset_of_value);

            if (*occupied && strcmp(*slot_key, key) != 0) {
                hash += 1;
                hash %= *items_count;
            } else {
                break;
            }
        }

        if (!(*occupied)) {
            *slot_key = key;
            *occupied = 1;
            memcpy(slot_value, value, item_size - offset_of_value);
            *table_size += 1;
        } else {
            memcpy(slot_value, value, item_size - offset_of_value);
        }
    }
}

#endif

#endif  /*__DS_H*/
