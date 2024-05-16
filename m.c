int main(void) {
    int ref = 15;
    int *ptr = &ref;
    *ptr = 20;

    return ref;
}
