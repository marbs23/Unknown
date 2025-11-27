module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;
  
  // instantiate device to be tested
  top dut(
    .clk(clk), 
    .reset(reset), 
    .WriteData(WriteData), 
    .DataAdr(DataAdr), 
    .MemWrite(MemWrite)
  );

  // initialize test
  initial begin
    reset = 1; # 22
    reset = 0;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, testbench);
  end

  // generate clock to sequence tests
  always begin
    clk = 1;
    # 5; clk = 0; # 5;
  end

  // check results
  integer cycle = 0;
  always @(negedge clk) begin
    cycle = cycle + 1;
    if (cycle == 200) begin   // por ejemplo 200 ciclos
      $display("Fin de simulaci�n (%0d ciclos)", cycle);
      $finish;
    end
  end
  
endmodule