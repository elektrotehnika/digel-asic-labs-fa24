// Defines
`timescale 1ns/1ps
// CLOCK_PERIOD is defined in a .yml file

// Finite Impulse Response module testbench (with file inputs)
module fir_tb_file();

  // FIR inputs
  reg clk;
  reg signed [3:0] In;
  // FIR outputs
  wire signed [15:0] Out;

  // FIR instance (Design Under Test)
  fir dut(.In (In ),
          .clk(clk),
          .Out(Out)
  );

  // Clock generation
  initial clk = 0;
  always #(`CLOCK_PERIOD/2) clk <= ~clk;

  // Main test process
  initial begin
    // Start test
    $display("Test started.");
    // Wait for 26 clock cycles
    repeat (26) @(negedge clk);
    // Finish test
    $display("Test finished.");
    $finish;
  end

  // Collect FIR inputs and expected FIR outputs
  reg signed [3:0] input_array [25:0];
  reg signed [15:0] Out_correct_array [25:0];
  initial begin
    $readmemb("../src/data_b.txt", Out_correct_array);
    $readmemb("../src/input.txt", input_array);
  end

  // Check if FIR filter behaves as expected
  integer index_counter = 0;
  assign In = input_array[index_counter];
  wire signed [15:0] Out_correct;
  assign Out_correct = Out_correct_array[index_counter];
  always @(negedge clk) begin
    $display($time, ": Out should be %d, got %d", Out_correct, Out);
    if (Out_correct != Out)
      $error("SIMULATION MISMATCH");
    index_counter <= index_counter + 1;
  end

  // VCD generation
  initial begin
    $dumpfile ("build/sim-rundir/fir_tb.vcd");
    $dumpvars (0, dut);
    #0;
  end

endmodule
