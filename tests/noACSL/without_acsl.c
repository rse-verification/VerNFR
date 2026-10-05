/* axiomatic Math {
      logic integer square(integer x);

      axiom square_nonnegative:
        \forall integer x; square(x) >= 0;
    }
*/

/* Function contract on a declaration */
/*
  requires x >= 0;
  ensures \result >= x;
*/
int declared_fun(int x);

/* Function contract on a definition */
/*
  requires n >= 0;
  ensures \result == n * (n - 1) / 2;
*/
int sum_upto(int n) {
  int s = 0;
  int i = 0;

  /*
    loop invariant 0 <= i <= n;
    loop invariant s == i * (i - 1) / 2;
    loop assigns i, s;
    loop variant n - i;
  */
  while (i < n) {
    s += i;
    i++;
  }

  /* Inline assertion */
  // assert s == n * (n - 1) / 2;

  return s;
}

int example(int x) {
  int y = x + 1;

  /* Statement contract */
  /*
    requires x >= 0;
    ensures y > x;
  */
  {
    y = x + 1;
  }

  /* Admit */
  // admit y > 1000;

  return y;
}

int declared_fun(int x) {
  return x + 1;
}
void main() {

}