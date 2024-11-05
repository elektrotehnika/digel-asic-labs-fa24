// Defines
`timescale 1ns/1ps
// CLOCK_PERIOD is defined in a .yml file

// Finite Impulse Response module testbench
module fir_tb();

  // FIR inputs
  reg clk;
  reg rst;
  reg signed [3:0] In;
  // FIR outputs
  wire signed [15:0] Out;

  // FIR instance (Design Under Test)
  fir dut(.In (In ),
          .clk(clk),
          .Out(Out),
          .rst(rst)
  );

  // Clock generation
  initial clk = 0;
  always #(`CLOCK_PERIOD/2) clk <= ~clk;

  // Main test process
  initial begin
    // Start test
    $display("Test started.");
    // Apply reset
    rst <= 1'b1;
    @(negedge clk) rst <= 1'b0;
    // Drive input signal several times
    In <= 4'd0;
    @(negedge clk) In <= 4'd1;
    @(negedge clk) In <= 4'd0;
    repeat(5) @(negedge clk) ;
    @(negedge clk) In <= 4'hF;
    repeat (5) @(negedge clk) ;
    @(negedge clk) In <= 4'd4;
    @(negedge clk) In <= 4'd16;
    @(negedge clk) In <= 4'd4;
    @(negedge clk) In <= 4'd1;
    @(negedge clk) In <= 4'd0;
    @(negedge clk) In <= 4'd8;
    @(negedge clk) In <= 4'd9;
    @(negedge clk) In <= 4'd10;
    @(negedge clk) In <= 4'd11;
    @(negedge clk) In <= 4'd12;
    @(negedge clk) In <= 4'd13;
    @(negedge clk) In <= 4'd14;
    // Finish test
    $display("Test finished.");
    $finish;
  end

  // Expected FIR output
  wire signed [15:0] Out_correct_array [25:0];
  assign Out_correct_array[0] = 0;
  assign Out_correct_array[1] = 0;
  assign Out_correct_array[2] = 1;
  assign Out_correct_array[3] = 4;
  assign Out_correct_array[4] = 16;
  assign Out_correct_array[5] = 4;
  assign Out_correct_array[6] = 1;
  assign Out_correct_array[7] = 0;
  assign Out_correct_array[8] = 0;
  assign Out_correct_array[9] = -1;
  assign Out_correct_array[10] = -5;
  assign Out_correct_array[11] = -21;
  assign Out_correct_array[12] = -25;
  assign Out_correct_array[13] = -26;
  assign Out_correct_array[14] = -26;
  assign Out_correct_array[15] = -21;
  assign Out_correct_array[16] = -5;
  assign Out_correct_array[17] = 63;
  assign Out_correct_array[18] = 32;
  assign Out_correct_array[19] = 72;
  assign Out_correct_array[20] = 24;
  assign Out_correct_array[21] = -31;
  assign Out_correct_array[22] = -161;
  assign Out_correct_array[23] = -173;
  assign Out_correct_array[24] = -156;
  assign Out_correct_array[25] = -130;

  // Check if FIR filter behaves as expected
  integer index_counter;
  initial index_counter = -1;
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
