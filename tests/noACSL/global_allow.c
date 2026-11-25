/* run.config
   OPT: -vernfr -nfr-no-acsl -keep-unused-functions=all
   OPT: -vernfr -nfr-no-acsl -keep-unused-functions=all -nfr-acsl-allow lemma,predicate,logic-function
   OPT: -vernfr -nfr-no-acsl -keep-unused-functions=all -nfr-acsl-allow predicate
*/

/*@ predicate nonnegative(integer x) = x >= 0; */
/*@ logic integer inc(integer x) = x + 1; */
/*@ lemma inc_nonnegative:
      \forall integer x; nonnegative(x) ==> nonnegative(inc(x));
*/

/*@ axiomatic GlobalMath {
      predicate bounded(integer x) = 0 <= x <= 10;
      logic integer dec(integer x) = x - 1;
      lemma dec_bounded:
        \forall integer x; 1 <= x <= 10 ==> bounded(dec(x));
    }
*/

int main(void) {
  return 0;
}
