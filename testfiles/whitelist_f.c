
void foo(void);
void bar(void);
void snd_foo(void);
int snd_bar(void);

static void internal_func(void);
int g;

void main() {
    foo();
    bar();
    internal_func();

    //Illegal stuff
    snd_foo();
    g = 3 + snd_bar();
    int v = snd_bar();
}