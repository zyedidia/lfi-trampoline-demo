#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#include "lfi.h"
#include "lfi_tux.h"

extern void* _funcs[];

extern uint8_t stub_start[];
extern uint8_t stub_end[];

static void lfi_init(void) {
    struct LFIPlatform* plat = lfi_new_plat((struct LFIPlatOptions) {
        .pagesize = getpagesize(),
        .vmsize = 4UL * 1024 * 1024 * 1024,
    });
    if (!plat) {
        fprintf(stderr, "error loading LFI: %s\n", lfi_strerror());
        exit(1);
    }

    struct Tux* tux = lfi_tux_new(plat, (struct TuxOptions) {
        .pagesize = getpagesize(),
        .stacksize = 2 * 1024 * 1024,
        .pause_on_exit = true,
        .verbose = true,
    });
    if (!tux) {
        fprintf(stderr, "error loading LFI Linux emulator: %s\n", lfi_strerror());
        exit(1);
    }

    char* args[] = {"stub", NULL};
    size_t size = (size_t)(stub_end - stub_start);
    struct TuxThread* p = lfi_tux_proc_new(tux, &stub_start[0], size, 1, &args[0]);
    lfi_tux_ctx(p);

    uint64_t r = lfi_tux_proc_run(p);

    // TODO: sanitize this pointer
    void** sbx_funcs = (void**) r;
    _funcs[0] = sbx_funcs[0];
    _funcs[1] = sbx_funcs[1];
}

int lfi_add(int, int);

int main() {
    lfi_init();

    int result = lfi_add(10, 32);
    printf("result: %d\n", result);
    return 0;
}
