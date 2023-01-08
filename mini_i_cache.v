`default_nettype none
`timescale 1 ns / 100 ps

module mini_i_cache #(
        parameter data_width = 32,
        parameter addr_width = 32,
        parameter cache_size = 16
    ) (
        input clock,
        input reset,
        // to cpu
        output reg ir_data_valid,
        output reg ir_addr_ready,
        output reg [data_width-1:0] ir_data,
        input ir_data_ready,
        input ir_addr_valid,
        input [addr_width-1:0] ir_addr,
        // to bus
        input bus_ir_data_valid,
        input bus_ir_addr_ready,
        input [data_width-1:0] bus_ir_data,
        output reg bus_ir_data_ready,
        output reg bus_ir_addr_valid,
        output reg [addr_width-1:0] bus_ir_addr
    );

    parameter cache_addr_width = $clog2(cache_size);
    parameter tag_width = addr_width - cache_addr_width;
    parameter entry_width = tag_width + data_width;
    parameter IDLE = 0;
    parameter RECEIVED = 1;
    parameter REPLY = 2;
    parameter MISS = 3;
    parameter WAIT_BUS = 4;

    reg [entry_width-1:0] mem [cache_size-1:0];
    wire cache_addr = addr_buf[cache_addr_width-1:0];
    wire tag = addr_buf[addr_width-1:cache_addr_width];
    reg [addr_width-1:0] addr_buf;
    reg [2:0] state;
    reg [2:0] next_state;
    reg request_received;
    reg [entry_width-1:0] entry;
    reg data_received;
    wire addr_sent;

    always @(posedge clock)
        if (reset)
            state <= IDLE;
        else
            state <= next_state;

    always @(*) begin
        next_state = IDLE;
        case (state)
            IDLE: begin
                if (request_received)
                    next_state = RECEIVED;
                end
            RECEIVED: begin
                next_state = MISS;
                if ({tag,entry[addr_width:data_width]} == addr_buf)
                    next_state = REPLY;
                end
            REPLY: begin
                next_state = REPLY;
                if (ir_data_valid == 0)
                    next_state = IDLE;
                end
            MISS: begin
                next_state = MISS;
                if (addr_sent)
                    next_state = WAIT_BUS;
                end
            WAIT_BUS: begin
                next_state = WAIT_BUS;
                if (data_received)
                    next_state = REPLY;
                end
        endcase
    end

    always @(posedge clock)
        if (reset) begin
            ir_addr_ready <= 1;
            bus_ir_data_ready <= 1;
        end

    always @(posedge clock)
        if (ir_addr_ready && ir_addr_valid) begin
            entry <= mem[cache_addr];
        end else if (bus_ir_data_ready && bus_ir_data_valid) begin
            entry <= {addr_buf[addr_width-1:cache_addr_width],bus_ir_data};
        end

    always @(posedge clock)
        if (reset || state == RECEIVED)
            request_received <= 0;
        else if (ir_addr_ready && ir_addr_valid) begin
            addr_buf <= ir_addr;
            request_received <= 1;
        end

    always @(posedge clock)
        if (reset)
            ir_data_valid <= 0;
        else if (state == REPLY) begin
            ir_data <= entry[data_width:0];
            ir_data_valid <= 1;
        end else if (ir_data_valid && ir_data_ready)
            ir_data_valid <= 0;

    assign addr_sent = bus_ir_addr_valid;
    always @(posedge clock)
        if (reset)
            bus_ir_addr_valid <= 0;
        else if (bus_ir_addr_valid && bus_ir_addr_ready)
            bus_ir_addr_valid <= 0;
        else if (state == MISS && bus_ir_addr_ready) begin
            bus_ir_addr <= addr_buf;
            bus_ir_addr_valid <= 1;
        end 

    always @(posedge clock)
        if (reset || next_state == MISS)
            data_received <= 0;
        else if (bus_ir_data_ready && bus_ir_data_valid) begin
            mem[addr_buf[cache_addr_width-1:0]] <= {addr_buf[addr_width-1:cache_addr_width],bus_ir_data};
            data_received <= 1;
        end

endmodule

