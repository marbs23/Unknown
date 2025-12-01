# RISC-V Pipelined Processor with Floating-Point Support

[![RISC-V](https://img.shields.io/badge/RISC--V-5--Stage%20Pipeline-blue)](https://riscv.org/)
[![FPU](https://img.shields.io/badge/FPU-IEEE%20754%20FP32-green)](https://ieee.org)
[![Verilog](https://img.shields.io/badge/HDL-Verilog-orange)](https://en.wikipedia.org/wiki/Verilog)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A fully functional **32-bit RISC-V pipelined processor** with integrated **IEEE 754 single-precision floating-point unit (FPU)**. This implementation features a 5-stage pipeline with advanced hazard handling, data forwarding, and support for both integer and floating-point operations.

## 📋 Table of Contents

- [Features](#-features)
- [Architecture Overview](#-architecture-overview)
- [Pipeline Stages](#-pipeline-stages)
- [Floating-Point Unit](#-floating-point-unit)
- [Hazard Handling](#-hazard-handling)
- [Instruction Set](#-instruction-set)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Simulation and Testing](#-simulation-and-testing)
- [Design Decisions](#-design-decisions)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

### Core Features
- ✅ **5-Stage Pipeline**: IF, ID, EX, MEM, WB stages with inter-stage registers
- ✅ **RISC-V RV32I Base**: Supports standard integer instructions
- ✅ **IEEE 754 FP32 Support**: Full floating-point arithmetic operations
- ✅ **Advanced Hazard Handling**: Forwarding and stalling mechanisms
- ✅ **Memory Operations**: Support for both integer and floating-point load/store

### Floating-Point Operations
- **FADD.S**: Floating-point addition
- **FSUB.S**: Floating-point subtraction
- **FMUL.S**: Floating-point multiplication
- **FDIV.S**: Floating-point division
- **FLW**: Floating-point load word
- **FSW**: Floating-point store word

### Hazard Resolution
- **Data Forwarding**: From MEM and WB stages to EX stage
- **Load-Use Hazards**: Automatic stall insertion for load dependencies
- **Control Hazards**: Branch and jump handling with pipeline flushing

---

## 🏗️ Architecture Overview

### High-Level Block Diagram

```
┌─────────────┐      ┌──────────────────┐      ┌─────────────┐
│ Instruction │      │                  │      │    Data     │
│   Memory    │◄─────┤  Pipeline        ├─────►│   Memory    │
│   (IMEM)    │      │  Processor       │      │   (DMEM)    │
└─────────────┘      └──────────────────┘      └─────────────┘
                            │
                    ┌───────┴────────┐
                    │                │
              ┌─────▼─────┐    ┌─────▼─────┐
              │  Control  │    │  Hazard   │
              │   Unit    │    │   Unit    │
              └───────────┘    └───────────┘
```

### Main Components

1. **`riscvpipelined.v`**: Top-level processor module integrating all components
2. **`datapath.v`**: Complete 5-stage pipeline datapath implementation
3. **`controller.v`**: Control unit with instruction decoding
4. **`HazardUnit.v`**: Hazard detection and resolution logic
5. **`alu_fp.v`**: Combinational floating-point ALU (IEEE 754 FP32)
6. **`alu.v`**: Integer ALU for standard RISC-V operations

---

## 🔄 Pipeline Stages

The processor implements a classic 5-stage pipeline with intermediate registers between each stage:

### Stage 1: Instruction Fetch (IF)
- **Purpose**: Fetch instruction from instruction memory
- **Components**:
  - Program Counter (PC)
  - Instruction Memory (IMEM)
  - PC+4 adder
- **Pipeline Register**: IF/ID

### Stage 2: Instruction Decode (ID)
- **Purpose**: Decode instruction and read registers
- **Components**:
  - Register file (32 registers × 32 bits)
  - Immediate extension unit
  - Main decoder (opcode decoding)
  - FP operation decoder
- **Pipeline Register**: ID/EX
- **Signals Generated**:
  - `IsFpD`: Indicates FP operation
  - `FpOpD`: FP operation type (00=ADD, 01=SUB, 10=MUL, 11=DIV)

### Stage 3: Execute (EX)
- **Purpose**: Execute arithmetic/logic operations
- **Components**:
  - Integer ALU (for standard RISC-V operations)
  - Floating-point ALU (`alu_fp.v`)
  - Forwarding multiplexers
  - Branch address adder
- **Pipeline Register**: EX/MEM
- **Multiplexing**:
  - Selection between ALU or FPU result based on `IsFpE`
  - Forwarding from MEM or WB stages

### Stage 4: Memory (MEM)
- **Purpose**: Access data memory
- **Components**:
  - Data Memory (DMEM)
  - Memory control unit
- **Pipeline Register**: MEM/WB
- **Operations**:
  - Load: Read data from memory
  - Store: Write data to memory

### Stage 5: Write Back (WB)
- **Purpose**: Write result to register file
- **Components**:
  - Result selection multiplexer
  - Register file (write on negative clock edge)
- **Result Sources**:
  - `00`: ALU/FPU result
  - `01`: Memory read data (load)
  - `10`: PC+4 (for JAL)

---

## 🔬 Floating-Point Unit

### Architecture

The FPU implements operations according to **IEEE 754 single-precision (FP32)** standard:
- **Format**: 1 sign bit + 8 exponent bits + 23 mantissa bits
- **Exponent Bias**: 127
- **Range**: ±1.175×10⁻³⁸ to ±3.403×10³⁸

### Implementation Details

**Key Design Decision**: The FPU is **combinational**, completing all operations in a single cycle. This design choice simplifies hazard handling and improves pipeline efficiency.

#### Supported Operations

| Instruction | Opcode | funct7 | Operation | Latency |
|-------------|--------|--------|-----------|---------|
| FADD.S | `1010011` | `0000000` | Addition | 1 cycle |
| FSUB.S | `1010011` | `0000100` | Subtraction | 1 cycle |
| FMUL.S | `1010011` | `0001000` | Multiplication | 1 cycle |
| FDIV.S | `1010011` | `0001100` | Division | 1 cycle |

#### Algorithms

**Addition/Subtraction**:
1. Exponent comparison and mantissa alignment
2. Mantissa addition/subtraction
3. Normalization
4. Rounding (round-to-nearest, ties-to-even)

**Multiplication**:
1. Mantissa multiplication (24×24 = 48 bits)
2. Exponent addition with bias adjustment
3. Normalization
4. Rounding

**Division**:
1. Mantissa division with remainder
2. Exponent subtraction with bias adjustment
3. Normalization
4. Rounding

#### Special Cases Handling

The FPU correctly handles:
- **NaN** (Not a Number): Invalid operations
- **Infinity**: Exponent overflow
- **Zero**: Exponent underflow or zero mantissa
- **Denormalized numbers**: Exponent = 0

---

## ⚠️ Hazard Handling

The processor implements a robust hazard handling system to maintain correctness in pipelined execution.

### Types of Hazards

#### 1. Data Hazards (RAW - Read After Write)

**Strategy**: **Forwarding (Bypassing)**
- Forwarding from EX/MEM to EX stage
- Forwarding from MEM/WB to EX stage
- Eliminates most unnecessary stalls

**Implementation**:
```verilog
// Forwarding for operand A
if (Rs1E == RdM && RegWriteM && Rs1E != 0)
    ForwardAE = 2'b10;  // Forward from MEM
else if (Rs1E == RdW && RegWriteW && Rs1E != 0)
    ForwardAE = 2'b01;  // Forward from WB
```

**Priority**: MEM stage has priority over WB stage

#### 2. Load-Use Hazards

Occurs when an instruction tries to use the result of a `LW` or `FLW` immediately after.

**Strategy**: **Stalling**
- Detects when `ResultSrcE == 01` (load) and dependency in ID
- Inserts one cycle of stall (pipeline bubble)

**Implementation**:
```verilog
loadUseHazard = (ResultSrcE == 2'b01) && (RdE != 5'b0) && 
               ((Rs1D == RdE) || (Rs2D == RdE));
```

#### 3. Control Hazards

Occurs with branches and jumps.

**Strategy**: **Flushing**
- When branch taken or jump detected:
  - Flush ID stage (`FlushD`)
  - Flush EX stage (`FlushE`)
  - Insert bubble in pipeline

### Forwarding Mechanism

Forwarding allows data to pass directly from later stages to earlier stages, avoiding unnecessary waits:

```
EX Stage:
  ┌─────────┐     ┌──────────┐
  │  ALU/FPU│     │  Forward │
  │  Result │────►│   MUX    │
  └─────────┘     └──────────┘
       ▲                │
       │                │
  ┌────┴────────────────┘
  │
  MEM Stage ──────┐
  │               │
  WB Stage ───────┘
```

**Forwarding Multiplexers**:
- `ForwardAE`: Selection for operand A (Rs1E)
- `ForwardBE`: Selection for operand B (Rs2E)

**Selection**:
- `00`: Register value (no forwarding)
- `01`: Value from WB stage
- `10`: Value from MEM stage (priority)

### Design Evolution: Hazard Unit Simplification

**Important Design Decision**: The hazard unit was simplified to reflect the combinational nature of the FPU.

#### Previous Implementation
- Included latency counters for FP operations (3-6 cycles)
- Complex stall logic based on FP operation type
- Unnecessary complexity for combinational FPU

#### Current Implementation
- **Simplified**: Removed all FP latency logic
- **Efficient**: No unnecessary stalls for FP operations
- **Correct**: Forwarding handles all FP dependencies
- **Clean**: Reduced from ~85 to 50 lines of code

**Result**: The processor correctly handles hazards for a combinational FPU:
- ✅ Forwarding works for both FP and integer operations
- ✅ Load-use hazards handled correctly
- ✅ Control hazards work as before
- ✅ No unnecessary stalls

---

## 📜 Instruction Set

### Integer Instructions

#### Arithmetic R-type
- `ADD rd, rs1, rs2`: Addition
- `SUB rd, rs1, rs2`: Subtraction

#### Arithmetic I-type
- `ADDI rd, rs1, imm`: Add immediate
- `SLTI rd, rs1, imm`: Set if less than immediate
- `ANDI rd, rs1, imm`: AND immediate
- `ORI rd, rs1, imm`: OR immediate

#### Memory
- `LW rd, offset(rs1)`: Load word
- `SW rs2, offset(rs1)`: Store word

#### Control Flow
- `BEQ rs1, rs2, offset`: Branch if equal
- `JAL rd, offset`: Jump and link

#### Immediate
- `LUI rd, imm`: Load upper immediate

### Floating-Point Instructions

#### FP Arithmetic
- `FADD.S rd, rs1, rs2`: Floating-point addition
- `FSUB.S rd, rs1, rs2`: Floating-point subtraction
- `FMUL.S rd, rs1, rs2`: Floating-point multiplication
- `FDIV.S rd, rs1, rs2`: Floating-point division

#### FP Memory
- `FLW rd, offset(rs1)`: Load floating-point word
- `FSW rs2, offset(rs1)`: Store floating-point word

### Instruction Formats

#### R-type (Register)
```
31:25    24:20    19:15    14:12    11:7     6:0
 funct7   rs2      rs1      funct3   rd      opcode
```

#### I-type (Immediate)
```
31:20             19:15    14:12    11:7     6:0
 immediate         rs1      funct3   rd      opcode
```

#### S-type (Store)
```
31:25             19:15    14:12    11:7     6:0
 imm[11:5]         rs1      funct3   rs2     opcode
```

---

## 📁 Project Structure

```
.
├── riscvpipelined.v    # Top-level processor module
├── datapath.v          # Complete pipeline datapath
├── controller.v        # Control unit
├── HazardUnit.v        # Hazard detection and resolution
│
├── alu.v               # Integer ALU
├── alu_fp.v            # Floating-point ALU (IEEE 754)
├── aludec.v            # ALU decoder
├── maindec.v           # Main decoder
│
├── regfile.v           # Register file (32 registers)
├── extend.v            # Immediate extension unit
├── adder.v             # Adder module
│
├── IF_ID.v             # IF/ID pipeline register
├── ID_EX.v             # ID/EX pipeline register
├── EX_MEM.v            # EX/MEM pipeline register
├── MEM_WB.v            # MEM/WB pipeline register
├── flopenrc.v          # Flip-flop with enable and clear
│
├── mux2.v              # 2:1 Multiplexer
├── mux3.v              # 3:1 Multiplexer
│
├── imem.v              # Instruction memory
├── dmem.v              # Data memory
│
├── top.v               # Top-level test module
├── testbench.v         # Testbench
│
├── riscvtest.txt       # Test program (hexadecimal)
├── run.sh              # Simulation script
│
└── README.md           # This file
```

### Key Module Descriptions

#### `riscvpipelined.v`
- Integrates controller, datapath, and hazard unit
- Interfaces with instruction and data memories
- Manages all global control signals

#### `datapath.v`
- Implements all 5 pipeline stages
- Contains intermediate registers between stages
- Manages forwarding multiplexers
- Integrates ALU and FPU with automatic selection
- Register file with negative-edge write

#### `alu_fp.v`
- Implements IEEE 754 FP32 operations
- Handles special cases (NaN, Infinity, Zero)
- Rounding: round-to-nearest, ties-to-even
- **Combinational**: All operations complete in 1 cycle

#### `HazardUnit.v`
- Detects and resolves data hazards
- Implements forwarding (bypassing) logic
- Manages stalls for load-use hazards
- Handles control hazards with flushing
- **Simplified**: Optimized for combinational FPU

---

## 🚀 Getting Started

### Prerequisites

- **Verilog Simulator**: Icarus Verilog (iverilog) or Verilator
- **Waveform Viewer**: GTKWave or Verdi
- **Text Editor**: For editing test programs

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Unknown
```

2. Verify Icarus Verilog installation:
```bash
iverilog -v
```

### Quick Start

1. **Edit test program**: Modify `riscvtest.txt` with your instructions (hexadecimal format, one per line)

2. **Compile and simulate**:
```bash
# Using the provided script
./run.sh

# Or manually
iverilog -o riscv_pipeline testbench.v top.v riscvpipelined.v datapath.v controller.v \
         HazardUnit.v alu.v alu_fp.v aludec.v maindec.v regfile.v extend.v adder.v \
         IF_ID.v ID_EX.v EX_MEM.v MEM_WB.v flopenrc.v mux2.v mux3.v imem.v dmem.v

vvp riscv_pipeline
```

3. **View waveforms**:
```bash
gtkwave dump.vcd
```

---

## 🧪 Simulation and Testing

### Test Program Format

Programs are written in hexadecimal format in `riscvtest.txt`, one instruction per line:

```
404000B7  # lui x1, 0x40400  (load 3.0 into x1)
40000137  # lui x2, 0x40000  (load 2.0 into x2)
00208253  # fadd.s x4, x1, x2  (x4 = 3.0 + 2.0 = 5.0)
```

### Example Test Program

The included `riscvtest.txt` demonstrates:
- Loading FP values using LUI
- All 4 FP operations (ADD, SUB, MUL, DIV)
- Pipeline execution

### Verifying Results

To verify correct operation:

1. **Pipeline**: Observe instructions advancing through 5 stages
2. **Forwarding**: Verify data forwarding without unnecessary stalls
3. **Hazards**: Confirm stalls inserted only when necessary
4. **FPU**: Validate FP operation results against expected IEEE 754 values

### Key Signals to Monitor

- `PC`: Program counter
- `InstrF/InstrD/InstrE/InstrM/InstrW`: Instruction in each stage
- `ForwardAE/ForwardBE`: Forwarding signals
- `StallF/StallD`: Stall signals
- `FlushD/FlushE`: Flush signals
- `ALUResultM`: ALU result in MEM stage
- `ResultW`: Final result written to register file

### IEEE 754 Reference Values

| Decimal | Hexadecimal | Description |
|---------|-------------|-------------|
| 0.0 | `0x00000000` | Positive zero |
| 1.0 | `0x3F800000` | One |
| 2.0 | `0x40000000` | Two |
| 3.0 | `0x40400000` | Three |
| 1.5 | `0x3FC00000` | 1.5 |
| Inf | `0x7F800000` | Positive infinity |
| NaN | `0x7FC00000` | Not a Number |

---

## 🎓 Design Decisions

### 1. Combinational FPU

**Decision**: Implement FPU as combinational logic (1-cycle completion)

**Rationale**:
- Simplifies hazard handling
- No need for complex latency counters
- Forwarding handles all dependencies
- Better pipeline efficiency

**Impact**: Simplified hazard unit, no FP-specific stalls needed

### 2. Simplified Hazard Unit

**Decision**: Remove FP latency logic from hazard unit

**Rationale**:
- FPU is combinational (no multi-cycle latency)
- Forwarding resolves all data dependencies
- Only load-use hazards require stalls

**Impact**: Reduced code complexity, improved maintainability

### 3. Unified Register File

**Decision**: Use single register file for both integer and FP values

**Rationale**:
- Simpler implementation
- Standard RISC-V approach
- Easier to manage

**Impact**: Simpler datapath, standard-compliant design

### 4. Pipeline Control Signals

**Decision**: Pipeline control signals through stages

**Rationale**:
- Each stage has correct control signals at the right time
- Standard pipeline design pattern
- Easier to debug

**Impact**: Correct control signal timing throughout pipeline

---

## 📊 Performance Characteristics

### Pipeline Efficiency

- **Ideal CPI**: 1.0 (one instruction per cycle)
- **With Hazards**: 
  - Load-use: +1 cycle per load-use hazard
  - Branch taken: +1 cycle (flush penalty)
  - Forwarding: Eliminates most stalls

### FPU Performance

- **Latency**: 1 cycle (all operations)
- **Throughput**: 1 operation per cycle
- **No stalls required**: Forwarding handles dependencies

---

## 🔧 Troubleshooting

### Common Issues

1. **Incorrect FP Results**
   - Verify IEEE 754 format encoding
   - Check FPU implementation
   - Compare bit-by-bit with expected results

2. **Pipeline Not Advancing**
   - Check for infinite stalls
   - Verify flush logic
   - Confirm reset functionality

3. **Forwarding Not Working**
   - Verify forwarding signal connections
   - Check forwarding priority logic
   - Ensure x0 (zero register) is never forwarded

4. **Memory Values Incorrect**
   - Verify memory alignment (word-aligned)
   - Check FSW write operations
   - Verify FLW read operations

---

## 📚 References

- **RISC-V Instruction Set Manual**: Official RISC-V specification
- **IEEE 754-2008**: Floating-point arithmetic standard
- **Computer Organization and Design (Patterson & Hennessy)**: Classic computer architecture reference

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

This project is open source and available under the MIT License.

---

## 👨‍💻 Author

Developed as part of a Computer Architecture course project.

---

**Version**: 2.0  
**Last Updated**: 2024  
**Status**: ✅ Production Ready

---

## 🙏 Acknowledgments

- RISC-V Foundation for the open instruction set architecture
- IEEE for the floating-point standard
- The open-source hardware community

---

**⭐ If you find this project useful, please consider giving it a star!**
