/* run.config
   OPT: -vernfr -nfr-no-acsl -keep-unused-functions=all -nfr-acsl-allow assert,loop-invariant,loop-assigns,loop-variant
   OPT: -vernfr -nfr-no-acsl -keep-unused-functions=all -nfr-acsl-allow assert
   OPT: -vernfr -keep-unused-functions=all -nfr-acsl-allow assert
*/

/* Never whitelistable: axioms are assumptions */
/*@ axiomatic Math {
      logic integer square(integer x);

      axiom square_nonnegative:
        \forall integer x; square(x) >= 0;
    }
*/

/* Never whitelistable: function contract */
/*@ requires n >= 0; */
int sum_upto(int n) {
  int s = 0;
  int i = 0;

  /* Whitelistable obligations */
  /*@
    loop invariant 0 <= i <= n;
    loop invariant s == i * (i - 1) / 2;
    loop assigns i, s;
    loop variant n - i;
  */
  while (i < n) {
    s += i;
    i++;
  }

  //@ assert s == n * (n - 1) / 2;
  //@ check s >= 0;

  return s;
}

int count_down(int n) {
  int i = n;

  /* Never whitelistable: admit modifier turns obligations into assumptions */
  /*@
    admit loop invariant i <= n;
    loop assigns i;
  */
  while (i > 0) {
    i--;
  }

  //@ admit i == 0;

  /* Never whitelistable: ghost code */
  //@ ghost int g = i;

  return i;
}

void main() {

}
