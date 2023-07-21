
struct test {
    int(*f)();
};

extern struct test T;

class C {
public:
    int f() {
        return 1;
    }
};
