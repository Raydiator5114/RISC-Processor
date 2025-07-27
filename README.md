A Verilog implementation of a classic 5-stage pipelined RISC-based MIPS processor. This design fetches, decodes, executes, accesses memory, and writes back instructions in a fully pipelined fashion, with 
hazard detection and forwarding to maximize throughput.

## Features

- **32-bit datapath**: All registers, ALU inputs/outputs, and PC are 32 bits wide.  
- **Fixed 5-stage pipeline**:  
  1. Instruction Fetch (IF)  
  2. Instruction Decode/Register Fetch (ID)  
  3. Execute/ALU (EX)  
  4. Memory Access (MEM)  
  5. Write-Back (WB)  
- **Hazard Detection & Stalling**: Automatically detects load-use hazards and inserts pipeline bubbles.  
- **Forwarding Unit**: Resolves data hazards via bypass paths to avoid unnecessary stalls.  
- **Basic MIPS ISA Support**: Implements a subset of R-type and I-type instructions (ADD, SUB, NAND, SLTI, LW, SW).  
- **Modular Verilog**: Each pipeline stage and control block is encapsulated in its own Verilog module for clarity and reuse.
