#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <string.h>
#include <stdlib.h>
#include <sys/mman.h>

// These are Forth-callable C functions
// SwapForth is passed the array CFUNCS, so it knows the
// address of each of function at run-time.
//
// This means that SwapForth itself does not refer to any
// external symbols, so it can be relocated with memcpy().

typedef size_t cell_t;

void _dotx(cell_t x)
{
  printf("%016zx ", x);
}

void _bye()
{
  exit(0);
}

void _emit(char c)
{
  putchar(c);
  fflush(stdout);
}

int _key()
{
  return getchar();
}

static const size_t cfuncs[] = {
  (size_t)_dotx,
  (size_t)_bye,
  (size_t)_emit,
  (size_t)_key
};


#define MEMSIZE (1024 * 1024)

int main()
{
  extern unsigned char swapforth, swapforth_ends;

  // allocate executable memory via sys call
  void* mem = mmap(NULL, MEMSIZE, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANON, -1, 0);

  // copy runtime code into allocated memory
  memcpy(mem, &swapforth, &swapforth_ends - &swapforth);
  printf("swapforth = %p\n", &swapforth);
  printf("mem       = %p\n", mem);

  // typecast allocated memory to a function pointer
  int64_t (*func) () = mem;

  int64_t stack[512 + 500];
  cell_t r = func(stack + 512, cfuncs);
  printf("(%p, %p)\n", stack + 512, cfuncs);
  printf("r = %zx\n", r);
  // printf("\ndepth = %d\n", (int)((stack + 512) - (int64_t*)r));

  // Free up allocated memory
  munmap(mem, MEMSIZE);

  return 0;
}
