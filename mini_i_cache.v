`default_nettype none
`timescale 1 ns / 100 ps

module mini_i_cache #(
        parameter data_width = 32,
        parameter addr_width = 32
    ) (
        input clock,
        input reset,
        // to cpu
        output ir_data_valid,
        output reg ir_addr_ready,
        output [data_width-1:0] ir_data,
        input ir_data_ready,
        input ir_addr_valid,
        input [addr_width-1:0] ir_addr,
        // to bus
        input bus_ir_data_valid,
        input bus_ir_addr_ready,
        input [data_width-1:0] bus_ir_data,
        output bus_ir_data_ready,
        output bus_ir_addr_valid,
        output [addr_width-1:0] bus_ir_addr
    );

    always @(posedge clock)
        if (reset)
            ir_addr_ready <= 1;

endmodule

