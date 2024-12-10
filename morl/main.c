int func_a() {
    return 42;
}

int func_b() {
    return func_a() + 27;
}

int main(void) {
    int b = func_b();

    return b;
}
