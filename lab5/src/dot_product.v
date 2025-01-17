// Implement a vector dot product of a and b
// using a single-port SRAM of 5-bit address width, 32-bit data width

module dot_product #(
  parameter ADDR_WIDTH = 5,
  parameter WIDTH = 32
) (
  input clk,
  input rst,

  input [ADDR_WIDTH:0] len,

  // input vector a
  input [WIDTH-1:0] a_data,
  input a_valid,
  output reg a_ready,

  // input vector b
  input [WIDTH-1:0] b_data,
  input b_valid,
  output reg b_ready,

  // dot product result c
  output reg [WIDTH-1:0] c_data,
  output reg c_valid,
  input c_ready
);

// State machine variables
reg [1:0] state;
localparam RECV = 2'd0;
localparam CALC = 2'd1;
localparam SEND = 2'd2;

// SRAM signals
reg we;
reg [WIDTH-1:0] din;
wire [WIDTH-1:0] dout;
reg [ADDR_WIDTH:0] addr;

// SRAM instance
sram22_64x32m4w8 sram (
  .clk(clk),
  .we(we),
  .wmask(4'b1111),
  .addr(addr),
  .din(din),
  .dout(dout)
);

// TODO: fill in the rest of this module.

endmodule
