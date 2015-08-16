#include <stdio.h>
#include "Vj1b.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    Vj1b* top = new Vj1b;

    if (argc != 2) {
      fprintf(stderr, "usage: sim <hex-file>\n");
      exit(1);
    }

    FILE *hex = fopen(argv[1], "r");
    int i;
    for (i = 0; i < 8192; i++) {
      unsigned int v;
      if (fscanf(hex, "%x\n", &v) != 1) {
        fprintf(stderr, "invalid hex value at line %d\n", i + 1);
        exit(1);
      }
      top->v__DOT__ram[i] = v;
    }

    top->resetq = 0;
    top->eval();
    top->resetq = 1;
    top->uart0_valid = 1;   // pretend to always have a character waiting

    for (i = 0; ; i++) {
      top->clk = 1;
      top->eval();
      top->clk = 0;
      top->eval();

      if (top->uart0_wr) {
        putchar(top->uart_w);
      }
      if (top->uart0_rd) {
        int c = getchar();
        if (c == EOF)
          break;
        top->uart0_data = (c == '\n') ? '\r' : c;
      }
    }
    printf("Simulation ended after %d cycles\n", i);
    delete top;

    exit(0);
}
