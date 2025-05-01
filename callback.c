// for the memfd_create definition
#define _GNU_SOURCE
#include <assert.h>
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>
#include <string.h>
#include <sys/mman.h>

#include "lfi.h"

#define MAXCALLBACKS 4096

// Code for a callback trampoline.
static uint8_t cbtrampoline[16] = {
   0x4c, 0x8b, 0x15, 0x09, 0x00, 0x00, 0x00, // mov    0x9(%rip),%r10
   0xff, 0x25, 0x0b, 0x00, 0x00, 0x00,       // jmp    *0xb(%rip)
   0x0f, 0x01f, 0x00,                        // nop
};

struct CallbackEntry {
    uint8_t code[16];
    uint64_t target;
    uint64_t trampoline;
};

extern void lfi_callback();

static struct CallbackEntry* cbentries_alias;
static struct CallbackEntry* cbentries_box;

static void* callbacks[MAXCALLBACKS];

static ssize_t
cbfreeslot()
{
    for (ssize_t i = 0; i < MAXCALLBACKS; i++) {
        if (!callbacks[i])
            return i;
    }
    return -1;
}

static ssize_t
cbfind(void* fn)
{
    for (size_t i = 0; i < MAXCALLBACKS; i++) {
        if (callbacks[i] == fn)
            return i;
    }
    return -1;
}

bool
lfi_cbinit(struct LFIContext* ctx)
{
    int fd = memfd_create("", 0);
    if (fd < 0)
        return false;
    size_t size = MAXCALLBACKS * sizeof(struct CallbackEntry);
    int r = ftruncate(fd, size);
    if (r < 0)
        goto err;
    // Map callback entries outside the sandbox as read/write.
    void* aliasmap = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (aliasmap == (void*) -1)
        goto err;
    cbentries_alias = (struct CallbackEntry*) aliasmap;
    // Fill in the code for each entry.
    for (size_t i = 0; i < MAXCALLBACKS; i++) {
        memcpy(&cbentries_alias[i].code, &cbtrampoline[0], sizeof(cbentries_alias[i].code));
    }
    struct HostFile* hf = lfi_host_fdopen(fd);
    assert(hf);
    // Share the mapping inside the sandbox as read/exec.
    lfiptr_t boxmap = lfi_as_mapany(lfi_ctx_as(ctx), size, PROT_READ | PROT_EXEC, MAP_SHARED, hf, 0);
    if (boxmap == (lfiptr_t) -1)
        goto err1;
    cbentries_box = (struct CallbackEntry*) boxmap;
    return true;
err1:
    munmap(aliasmap, size);
err:
    close(fd);
    return false;
}

void*
lfi_register_cb(void* fn)
{
    assert(fn);
    assert(cbfind(fn) == -1 && "fn is already registered as a callback");

    ssize_t slot = cbfreeslot();
    if (slot == -1)
        return NULL;

    // write 'fn' into the 'target' field for the chosen slot.
    __atomic_store_n(&cbentries_alias[slot].target, (uint64_t) fn, __ATOMIC_SEQ_CST);
    // write the trampoline into the 'trampoline' field for the chosen slot
    __atomic_store_n(&cbentries_alias[slot].trampoline, (uint64_t) lfi_callback, __ATOMIC_SEQ_CST);

    // Mark the slot as allocated.
    callbacks[slot] = fn;

    return &cbentries_box[slot].code[0];
}

void
lfi_unregister_cb(void* fn)
{
    ssize_t slot = cbfind(fn);
    if (slot == -1)
        return;
    callbacks[slot] = NULL;
    __atomic_store_n(&cbentries_alias[slot].target, 0, __ATOMIC_SEQ_CST);
    __atomic_store_n(&cbentries_alias[slot].trampoline, 0, __ATOMIC_SEQ_CST);
}
