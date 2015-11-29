#include <stdio.h>
#include <stdint.h>

void _dotx(uint64_t x)
{
  printf("%016llx ", x);
}

void _emit(char c)
{
  putchar(c);
}

char _key()
{
  return getchar();
}

int main()
{
  extern int64_t swapforth(int64_t *stack);
  int64_t stack[600];
  int64_t r = swapforth(stack + 512);
  printf("\ndepth = %ld\n", (stack + 512) - (int64_t*)r);
  // printf("%p %p\n",(stack + 512), (int64_t*)r);
  return 0;
}
