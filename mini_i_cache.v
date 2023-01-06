`default_nettype none
`timescale 1 ns / 100 ps

module mini_i_cache #(
	parameter data_width = 32,
	parameter addr_width = 32
) (
    input clk,
    // to cpu
    input ir_data_valid,
    input ir_addr_ready,
    input [data_width-1:0] ir_data,
    output ir_data_ready,
    output ir_addr_valid,
    output [addr_width-1:0] ir_addr,
    // to bus
    output bus_ir_data_valid,
    output bus_ir_addr_ready,
    output [data_width-1:0] bus_ir_data,
    input bus_ir_data_ready,
    input bus_ir_addr_valid,
    input [addr_width-1:0] bus_ir_addr
);

endmodule

