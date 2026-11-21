/* run.config
   EXIT: 1
   OPT: -vernfr -nfr-no-acsl -keep-unused-functions=all -nfr-acsl-allow assert,axiom
*/

int f(int x) {
  //@ assert x == x;
  return x;
}

void main() {

}
