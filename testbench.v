module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;
  
  // Instantiate device to be tested
  top dut(
    .clk(clk), 
    .reset(reset), 
    .WriteData(WriteData), 
    .DataAdr(DataAdr), 
    .MemWrite(MemWrite)
  );

  // Initialize test
  initial begin
    reset = 1; 
    #22;
    reset = 0;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, testbench);
  end

  // Generate clock
  always begin
    clk = 1; #5; 
    clk = 0; #5;
  end

  // Monitor execution
  integer cycle = 0;
  integer instr_count = 0;
  
  always @(posedge clk) begin
    if (reset) begin
      cycle = 0;
      instr_count = 0;
    end else begin
      cycle = cycle + 1;
      
      // Monitor PC and instructions
      if (cycle % 10 == 0) begin
        $display("Cycle %0d: PC=%h, Instr=%h", 
                 cycle, dut.rvpipelined.PC, dut.imem.rd);
      end
      
      // Monitor memory writes
      if (MemWrite) begin
        $display("Cycle %0d: MEM WRITE Addr=%h, Data=%h", 
                 cycle, DataAdr, WriteData);
      end
      
      // Check if we reached halt (PC not changing)
      if (cycle > 50 && dut.rvpipelined.PC == 32'h74) begin
        $display("\n=== PROGRAM HALTED at cycle %0d ===", cycle);
        $display("\nVerifying Matrix C results:");
        $display("Expected C = [[4.0, 5.0], [7.0, 9.0]]");
        $display("C[0][0] (addr 32) = %h (expected 40800000 = 4.0)", dut.dmem.RAM[8]);
        $display("C[0][1] (addr 36) = %h (expected 40A00000 = 5.0)", dut.dmem.RAM[9]);
        $display("C[1][0] (addr 40) = %h (expected 40E00000 = 7.0)", dut.dmem.RAM[10]);
        $display("C[1][1] (addr 44) = %h (expected 41100000 = 9.0)", dut.dmem.RAM[11]);
        
        // Verify results
        if (dut.dmem.RAM[8]  == 32'h40800000 &&
            dut.dmem.RAM[9]  == 32'h40A00000 &&
            dut.dmem.RAM[10] == 32'h40E00000 &&
            dut.dmem.RAM[11] == 32'h41100000) begin
          $display("\n✓ TEST PASSED - Matrix multiplication correct!");
        end else begin
          $display("\n✗ TEST FAILED - Results don't match expected values");
        end
        
        $display("\nTotal cycles: %0d", cycle);
        $finish;
      end
      
      // Timeout
      if (cycle >= 500) begin
        $display("\n✗ TIMEOUT at cycle %0d", cycle);
        $display("PC stuck at: %h", dut.rvpipelined.PC);
        $display("Last instruction: %h", dut.imem.rd);
        $finish;
      end
    end
  end
  
endmodule