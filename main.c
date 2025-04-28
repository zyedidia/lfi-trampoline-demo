#include <assert.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#include "lfi.h"
#include "lfi_tux.h"

extern uint8_t stub_start[];
extern uint8_t stub_end[];

_Thread_local void* lfi_retfn;
_Thread_local void* lfi_targetfn;

static struct TuxThread* p;

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
    p = lfi_tux_proc_new(tux, &stub_start[0], size, 1, &args[0]);
    assert(p);

    lfi_tux_proc_run(p);
}

extern void lfi_trampoline();
static const void* lfi_trampoline_addr = &lfi_trampoline;

static int
lfi_add(int a, int b)
{
    lfi_retfn = (void*) lfi_proc_sym(lfi_tux_ctx(p), "_lfi_retfn");
    lfi_targetfn = (void*) lfi_proc_sym(lfi_tux_ctx(p), "add");
    int (*trampoline)(int, int) = (int (*)(int, int)) lfi_trampoline_addr;
    return trampoline(a, b);
}

int main() {
    lfi_init();

    int result = lfi_add(10, 32);
    printf("result: %d\n", result);
    return 0;
}
