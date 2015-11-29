#include <stdio.h>
#include <stdint.h>

void _emit(char c)
{
  putchar(c);
}

int main()
{
  extern int64_t swapforth(int64_t *stack);
  int64_t stack[512];
  int64_t r = swapforth(stack + 512);
  printf("\ndepth = %ld\n", (stack + 512) - (int64_t*)r);
  return 0;
}
