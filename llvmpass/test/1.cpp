

int foo(char c) { return c; }

int bar(int i) { return foo(i); }

void *a[] = {(void *)foo, (void *)bar, nullptr};

int main() {
  int (*f)(int) = (int (*)(int))a[0];
  int (*g)(char) = (int (*)(char))a[1];
  return f(g('a'));
}
