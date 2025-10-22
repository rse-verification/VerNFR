void foo(void);
void bar(void);

static void internal_func(void);
static int internal_int_func(void);

static void func_w_int_param(int x);

void main() {
    foo();
    bar();

    void (*f_ptr)(void) = internal_func;
    int (*int_f_ptr)(void) = internal_int_func;
    
    f_ptr();
    func_w_int_param(int_f_ptr());
    
    int x = int_f_ptr();
}