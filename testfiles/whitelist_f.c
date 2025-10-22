
void foo(void);
void bar(void);
void snd_foo(void);
int snd_bar(void);


static void internal_func(void);
static void internal_int_func(int x);
int g;

void main() {
    foo();
    bar();
    internal_func();

    //Illegal stuff
    snd_foo();
    g = 3 + snd_bar();
    int v = snd_bar();
    internal_int_func(snd_bar());
}