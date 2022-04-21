#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <inttypes.h>


typedef struct __attribute__((packed)) {
  __uint8_t A, D, X, Y, PC;
  __uint8_t unused; // Wypełniacz, aby struktura zajmowała 8 bajtów.
  bool    C, Z;
} cpu_state_t;

// Tak zadeklarowaną funkcję można wywoływać też dla procesora jednordzeniowego.
cpu_state_t so_emul(__uint16_t const *code, __uint8_t *data, size_t steps, size_t core);

void execute_mov(__uint8_t arg1, __uint8_t arg2);

cpu_state_t push_state_to_rax();

void push_state_to_registers();

__uint8_t get_value_from_register_code(__uint8_t arg);




static void dump_cpu_state(size_t core, cpu_state_t cpu_state, uint8_t const *data) {
  printf("core %zu: A = %02" PRIx8 ", D = %02" PRIx8 ", X = %02" PRIx8 ", Y = %02"
         PRIx8 ", PC = %02" PRIx8 ", C = %hhu, Z = %hhu, [X] = %02" PRIx8 ", [Y] = %02"
         PRIx8 ", [X + D] = %02" PRIx8 ", [Y + D] = %02" PRIx8 "\n",
         core, cpu_state.A, cpu_state.D, cpu_state.X, cpu_state.Y, cpu_state.PC,
         cpu_state.C, cpu_state.Z, data[cpu_state.X], data[cpu_state.Y],
         data[(cpu_state.X + cpu_state.D) & 0xFF], data[(cpu_state.Y + cpu_state.D) & 0xFF]);
}

__uint8_t testowa(__uint8_t* data);

int main()
{
    int data_size = 256;
    uint8_t* data = malloc(data_size);
    for (int i = 0; i < data_size; i++)
    {
        data[i] = 0;
    }
    data[0] = 7;
    printf("%d\n", testowa(data));
    /* cpu_state_t st;
    st = testowa(data);
    dump_cpu_state(1, st, data); */
}
