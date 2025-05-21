# Matrix Accelerator Demonstrator

## Software

1. [Bender](https://github.com/pulp-platform/bender)
1. QuestaSim or VCS
1. Vivado >= 2024.1

## First steps

1. Download Bender submodules
1. Build RISC-V custom toolchain (*make gcc*)
1. Build Openocd (*make openocd*)

### Example

```bash
bender update
make gcc
make openocd
```

## Usage

Extra Bender arguments with **DEFINES** variable.

Project arguments, configure with defines:

* PRF_LOG_P (default 1) - log2 number of internal memory banks, rows
* PRF_LOG_Q (default 2) - log2 number of internal memory banks, columns

### RTL simulation

```bash
make sim # for modelsim
```

### Vivado run

```bash
make vivado
```
