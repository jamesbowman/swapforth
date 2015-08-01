#include <stdio.h>
#include "Vj1a.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    Vj1a* top = new Vj1a;

    // Verilated::traceEverOn(true);
    // VerilatedVcdC* tfp = new VerilatedVcdC;
    // top->trace (tfp, 99);
    // tfp->open ("simx.vcd");

    if (argc != 2) {
      fprintf(stderr, "usage: sim <hex-file>\n");
      exit(1);
    }

    FILE *hex = fopen(argv[1], "r");
    int i;
    for (i = 0; i < 2048; i++) {
      unsigned int v;
      if (fscanf(hex, "%x\n", &v) != 1) {
        fprintf(stderr, "invalid hex value at line %d\n", i + 1);
        exit(1);
      }
      top->v__DOT__ram_prog[i] = v;
    }
    for (i = 0; i < 2048; i++) {
      unsigned int v;
      if (fscanf(hex, "%x\n", &v) != 1) {
        fprintf(stderr, "invalid hex value at line %d\n", i + 1);
        exit(1);
      }
      top->v__DOT__ram_data[i] = v;
    }

    // FILE *input = fopen(argv[1], "r");
    // if (!input) {
    //   perror(argv[1]);
    //   exit(1);
    // }
    // top->io_din = getc(input);

    top->resetq = 0;
    top->eval();
    top->resetq = 1;

    FILE *log = fopen("log", "w");
    int t = 0;
    // for (i = 0; /*i < 534563551 */; i++) {
    for (i = 0; ; i++) {
      top->clk = 1;
      top->eval();
      // tfp->dump(t);
      t += 20;

      top->clk = 0;
      top->eval();
      // tfp->dump(t);
      t += 20;
      if (top->uart0_wr) {
        // printf("out %d\n", top->uart_w);
        putchar(top->uart_w);
        putc(top->uart_w, log);
      }
      if (top->uart0_rd) {
        int c = getchar();
        top->uart0_data = (c == '\n') ? '\r' : c;
        if (c == EOF)
          break;
      }
    }
    printf("Simulation ended after %d cycles\n", i);
    delete top;
    // tfp->close();
    fclose(log);

    exit(0);
}
