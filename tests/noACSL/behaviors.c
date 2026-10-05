/*@ behavior has_key: 
  @   assumes
  @     \exists integer i; 0 <= i <= len - 1 && a[i] == key;
  @   ensures
  @     a[\result] == key;
  @
  @ behavior has_not_key:
  @   assumes 
  @     \forall integer i; 0 <= i <= len - 1 ==> a[i] != key;
  @   ensures
  @     \true;
  @
  @ disjoint behaviors;
  @
  @ complete behaviors;
  @
  @*/
int binary_search(int* a, int len, int key) {
  int low = 0;
  int high = len - 1;
  while (low <= high) {
    int mid = low + ((high - low) / 2);
    int mid_val = a[mid];
    if (mid_val < key) {
      low = mid + 1;
    } else if (mid_val > key) {
      high = mid - 1;
    } else {
      return mid;
    }
  }
  return -low - 1;
}
