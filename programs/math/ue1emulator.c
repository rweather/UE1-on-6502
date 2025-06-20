
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_TAPE 4096

/* Opcodes, aligned in the high nibble */
#define OP_NOP0     0x00
#define OP_LD       0x10
#define OP_ADD      0x20
#define OP_SUB      0x30
#define OP_ONE      0x40
#define OP_NAND     0x50
#define OP_OR       0x60
#define OP_XOR      0x70
#define OP_STO      0x80
#define OP_STOC     0x90
#define OP_IEN      0xA0
#define OP_OEN      0xB0
#define OP_IOC      0xC0
#define OP_RTN      0xD0
#define OP_SKZ      0xE0
#define OP_NOPF     0xF0

/* Memory addresses */
#define MEM_SR0     0x00
#define MEM_SR1     0x01
#define MEM_SR2     0x02
#define MEM_SR3     0x03
#define MEM_SR4     0x04
#define MEM_SR5     0x05
#define MEM_SR6     0x06
#define MEM_SR7     0x07
#define MEM_OR0     0x08
#define MEM_OR1     0x09
#define MEM_OR2     0x0A
#define MEM_OR3     0x0B
#define MEM_OR4     0x0C
#define MEM_OR5     0x0D
#define MEM_OR6     0x0E
#define MEM_OR7     0x0F
#define MEM_RR      0x08
#define MEM_IR1     0x09
#define MEM_IR2     0x0A
#define MEM_IR3     0x0B
#define MEM_IR4     0x0C
#define MEM_IR5     0x0D
#define MEM_IR6     0x0E
#define MEM_IR7     0x0F

struct ue1_state
{
    unsigned char ien;
    unsigned char oen;
    unsigned char skip;
    unsigned char rr;
    unsigned char car;
    unsigned char data_in;
    unsigned char sr[8];
    unsigned char or[8];
    unsigned char ir[8]; /* IR0 is unused */
};

static unsigned char read_mem(struct ue1_state *state, unsigned char addr)
{
    if (addr < 8) {
        return state->sr[addr];
    } else if (addr == MEM_RR) {
        return state->rr;
    } else {
        return state->ir[addr & 0x07];
    }
}

static void write_mem(struct ue1_state *state, unsigned char addr, unsigned char value)
{
    if (addr < 8) {
        state->sr[addr] = value;
    } else {
        state->or[addr & 0x07] = value;
    }
}

#define OP_MUL 0
#define OP_DIV 1

int main(int argc, char **argv)
{
    unsigned char tape[MAX_TAPE];
    unsigned char inst;
    unsigned char temp;
    FILE *file;
    size_t size, pc;
    struct ue1_state ue1 = {
        .rr = 0
    };
    char buffer[64];
    unsigned inputs;
    int bits_A = 0;
    int bits_B = 0;
    int value_A, value_B;
    int actual_A;
    int enter_A;
    int exitval = 0;
    int op = OP_MUL;

    /* Read in the program tape */
    if (argc < 2) {
        fprintf(stderr, "Usage: %s tape.bin [bits-A] [bits-B]\n", argv[0]);
        return 1;
    }
    if ((file = fopen(argv[1], "rb")) == NULL) {
        perror(argv[1]);
        return 1;
    }
    size = fread(tape, 1, MAX_TAPE, file);
    fclose(file);
    if (!size) {
        fprintf(stderr, "%s: empty tape\n", argv[1]);
        return 1;
    }
    if (argc >= 4) {
        bits_A = atoi(argv[2]);
        bits_B = atoi(argv[3]);
    }
    if (argc >= 5 && !strcmp(argv[4], "div")) {
        op = OP_DIV;
    }

    /* Run the tape until NOPF / halt */
    for (value_A = 0; value_A < (1 << bits_A); ++value_A) {
    for (value_B = 0; value_B < (1 << bits_B); ++value_B) {
    enter_A = 1;
    pc = 0;
    actual_A = value_A;
    for (;;) {
        inst = tape[pc++];
        if (pc >= size) {
            pc = 0;
        }
        if (ue1.skip) {
            /* Skip this instruction, back to normal on next instruction */
            ue1.skip = 0;
            continue;
        }
        ue1.data_in = read_mem(&ue1, inst & 0x0F);
        if ((inst & 0xF0) == OP_NOPF) {
            /* If we have wrapped around, this is the actual halt.
             * Otherwise ask for new input register values. */
            if (pc == 0) {
                break;
            }
            if (bits_A != 0 || bits_B != 0) {
                if (enter_A) {
                    inputs = value_A;
                    if (op == OP_DIV && bits_B == 8) {
                        /* Put the MSB of the dividend into A */
                        actual_A &= 0x0F;
                        if ((value_B & 0x80) != 0) {
                            inputs |= 0x40;
                        }
                    }
                    enter_A = 0;
                } else {
                    inputs = value_B & 0x7F;
                }
            } else {
                printf("Enter IR: ");
                fflush(stdout);
                if (!fgets(buffer, sizeof(buffer), stdin)) {
                    break;
                }
                inputs = strtoul(buffer, NULL, 2);
            }
            ue1.ir[1] = (inputs & 1) != 0;
            ue1.ir[2] = ((inputs >> 1) & 1) != 0;
            ue1.ir[3] = ((inputs >> 2) & 1) != 0;
            ue1.ir[4] = ((inputs >> 3) & 1) != 0;
            ue1.ir[5] = ((inputs >> 4) & 1) != 0;
            ue1.ir[6] = ((inputs >> 5) & 1) != 0;
            ue1.ir[7] = ((inputs >> 6) & 1) != 0;
            continue;
        }
        switch (inst & 0xF0) {
        case OP_NOP0: break;

        case OP_LD:
            if (!ue1.ien) {
                /* IEN = 0 forces the input data to zero */
                ue1.data_in = 0;
            }
            ue1.rr = ue1.data_in;
            break;

        case OP_ADD:
            if (!ue1.ien) {
                /* IEN = 0 forces the input data to zero */
                ue1.data_in = 0;
            }
            temp = ue1.rr + ue1.data_in + ue1.car;
            ue1.rr = temp & 1;
            ue1.car = (temp >> 1) & 1;
            break;

        case OP_SUB:
            if (!ue1.ien) {
                /* IEN = 0 forces the input data to zero */
                ue1.data_in = 0;
            }
            temp = ue1.rr + (ue1.data_in ^ 1) + ue1.car;
            ue1.rr = temp & 1;
            ue1.car = (temp >> 1) & 1;
            break;

        case OP_ONE:
            ue1.rr = 1;
            ue1.car = 0;
            break;

        case OP_NAND:
            if (!ue1.ien) {
                /* IEN = 0 forces the input data to zero */
                ue1.data_in = 0;
            }
            ue1.rr = (ue1.rr & ue1.data_in) ^ 1;
            break;

        case OP_OR:
            if (!ue1.ien) {
                /* IEN = 0 forces the input data to zero */
                ue1.data_in = 0;
            }
            ue1.rr = (ue1.rr | ue1.data_in);
            break;

        case OP_XOR:
            if (!ue1.ien) {
                /* IEN = 0 forces the input data to zero */
                ue1.data_in = 0;
            }
            ue1.rr = (ue1.rr ^ ue1.data_in);
            break;

        case OP_STO:
            if (ue1.oen) {
                write_mem(&ue1, inst & 0x0F, ue1.rr);
            }
            break;

        case OP_STOC:
            if (ue1.oen) {
                write_mem(&ue1, inst & 0x0F, ue1.rr ^ 1);
            }
            break;

        case OP_IEN:
            ue1.ien = ue1.data_in;
            break;

        case OP_OEN:
            ue1.oen = ue1.data_in;
            break;

        case OP_IOC:
            /* Ring the bell - not implemented yet */
            break;

        case OP_RTN:
            /* Unconditional skip */
            ue1.skip = 1;
            break;

        case OP_SKZ:
            /* Conditional skip */
            ue1.skip = ue1.rr ^ 1;
            break;

        case OP_NOPF:
            /* Already handled above */
            break;
        }
    }
    if (bits_A != 0 || bits_B != 0) {
        int result = 0;
        int bit;
        if (op == OP_MUL) {
            for (bit = 7; bit >= 0; --bit) {
                result <<= 1;
                result |= ue1.sr[bit];
            }
            for (bit = 7; bit >= 0; --bit) {
                result <<= 1;
                result |= ue1.or[bit];
            }
            printf("%d x %d = %d", value_A, value_B, result);
            if (result != (value_A * value_B)) {
                printf("  WRONG!");
                exitval = 1;
            }
            printf("\n");
        } else if (op == OP_DIV) {
            int remainder = 0;
            for (bit = 3; bit >= 0; --bit) {
                remainder <<= 1;
                remainder |= ue1.sr[bit];
            }
            for (bit = 8; bit >= 0; --bit) {
                result <<= 1;
                result |= ue1.or[bit];
            }
            if (actual_A != 0) {
                printf("%d / %d = %d, remainder %d",
                       value_B, actual_A, result, remainder);
                if (result != (value_B / actual_A) ||
                        remainder != (value_B % actual_A)) {
                    printf("  WRONG!");
                    exitval = 1;
                }
            } else {
                /* Division by zero maxes out the quotient value */
                printf("%d / %d = %d", value_B, actual_A, result);
                if (result != ((1 << bits_B) - 1)) {
                    printf("  WRONG!");
                    exitval = 1;
                }
            }
            printf("\n");
        }
    }
    } // for value_B
    } // for value_A
    if (bits_A == 0 && bits_B == 0) {
        printf("Result  : %d%d%d%d %d%d%d%d %d%d%d%d %d%d%d%d\n",
               ue1.sr[7], ue1.sr[6], ue1.sr[5], ue1.sr[4],
               ue1.sr[3], ue1.sr[2], ue1.sr[1], ue1.sr[0],
               ue1.or[7], ue1.or[6], ue1.or[5], ue1.or[4],
               ue1.or[3], ue1.or[2], ue1.or[1], ue1.or[0]);
    }
    return exitval;
}
