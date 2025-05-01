int add(int (*cb)(void), int a, int b) {
    return cb() + a + b;
}
