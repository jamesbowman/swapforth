#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <string.h>
#include <stdlib.h>
#include <sys/mman.h>

void _dotx(uint64_t x)
{
  printf("%016" PRIx64 " ", x);
}

void _emit(char c)
{
  if (c == 26)
    exit(0);
  putchar(c);
}

char _key()
{
  int r = getchar();
  if (r == -1)
    exit(0);
  return r;
}

int main()
{
  // Hexadecimal x86_64 machine code for: int mul (int a, int b) { return a * b; }
  unsigned char code [] = {
    0x55, // push rbp
    0x48, 0x89, 0xe5, // mov rbp, rsp
    0x89, 0x7d, 0xfc, // mov DWORD PTR [rbp-0x4],edi
    0x89, 0x75, 0xf8, // mov DWORD PTR [rbp-0x8],esi
    0x8b, 0x75, 0xfc, // mov esi,DWORD PTR [rbp-04x]
    0x0f, 0xaf, 0x75, 0xf8, // imul esi,DWORD PTR [rbp-0x8]
    0x89, 0xf0, // mov eax,esi
    0x5d, // pop rbp
    0xc3 // ret
  };

  extern unsigned char swapforth[];

  // allocate executable memory via sys call
  void* mem = mmap(NULL, 1024 * 1024, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANON, -1, 0);

  // copy runtime code into allocated memory
  memcpy(mem, swapforth, 65536);

  // typecast allocated memory to a function pointer
  int64_t (*func) () = mem;

  int64_t stack[512 + 500];
  int64_t r = func(stack + 512, &_emit, &_dotx, &_key);
  printf("r = %" PRIu64 "x\n", r);
  printf("\ndepth = %d\n", (int)((stack + 512) - (int64_t*)r));

  // Free up allocated memory
  munmap(mem, sizeof(code));

  return 0;
}
