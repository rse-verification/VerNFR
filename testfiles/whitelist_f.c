
void foo(void);
void bar(void);
void snd_foo(void);

static void internal_func(void);

void main() {
    foo();
    bar();
    internal_func();
    snd_foo();
}