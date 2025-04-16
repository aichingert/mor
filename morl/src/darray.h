#ifndef DARRAY_H
#define DARRAY_H

#include <string.h>

// used from: https://www.bytesbeneath.com/p/dynamic-arrays-in-c

#define ARRAY_INITIAL_CAPACITY 16

typedef struct {
    size_t length;
    size_t capacity;
    size_t padding;
} array_header;

#define array(T) array_init(sizeof(T), ARRAY_INITIAL_CAPACITY)
#define array_header(a) ((array_header *)(a) - 1)
#define array_length(a) (array_header(a)->length)
#define array_capacity(a) (array_header(a)->capacity)

#define array_append(a, v) ( \
    (a) = array_ensure_capacity(a, 1, sizeof(v)), \
    (a)[array_header(a)->length] = (v), \
    &(a)[array_header(a)->length++])

#define array_remove(a, i) do { \
    array_header *h = array_header(a); \
    if (i == h->length - 1) { \
        h->length -= 1; \
    } else if (h->length > 1) { \
        void *ptr = &a[i]; \
        void *last = &a[h->length - 1]; \
        h->length -= 1; \
        memcpy(ptr, last, sizeof(*a)); \
    } \
} while (0);

#define array_pop_back(a) (array_header(a)->length -= 1)

void *array_init(size_t item_size, size_t capacity) {
    void *ptr = 0;
    size_t size = item_size * capacity + sizeof(array_header);
    array_header *h = malloc(size);

    if (h) {
        h->capacity = capacity;
        h->length = 0;
        ptr = h + 1;
    }

    return ptr;
}

void *array_ensure_capacity(void *a, size_t item_count, size_t item_size) {
    array_header *h = array_header(a);
    size_t desired_capacity = h->length + item_count;

    if (h->capacity < desired_capacity) {
        size_t new_capacity = h->capacity * 2;
        while (new_capacity < desired_capacity) {
            new_capacity *= 2;
        }

        size_t new_size = sizeof(array_header) + new_capacity * item_size;
        array_header *new_h = malloc(new_size);

        if (new_h) {
            size_t old_size = sizeof(*h) + h->length * item_size;
            memcpy(new_h, h, old_size);
            free(h);

            new_h->capacity = new_capacity;
            h = new_h + 1;
        } else {
            h = 0;
        }
    } else { h += 1; }

    return h;
}

#endif /* DARRAY_H */
