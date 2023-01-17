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

    parameter entry_addr_width = $clog2(cache_size);
    parameter tag_width = addr_width - entry_addr_width;
    parameter entry_width = 1 + tag_width + data_width;
    parameter IDLE = 0;
    parameter RECEIVED = 1;
    parameter REPLY = 2;
    parameter MISS = 3;
    parameter WAIT_BUS = 4;
    parameter RESET = 5;

    reg [entry_width-1:0] mem [cache_size-1:0];
    wire [entry_addr_width-1:0] entry_addr;
    wire [tag_width-1:0] tag;
    reg [addr_width-1:0] addr_buf;
    reg [2:0] state;
    reg [2:0] next_state;
    reg request_received;
    reg [entry_width-1:0] entry;
    reg data_received;
    wire addr_sent;
    wire [addr_width-1:0] cached_addr;
    wire reset_done;
    reg [entry_addr_width-1:0] reset_counter;
    wire dirty;
    wire [entry_width-1:0] reset_value;

    always @(posedge clock)
        if (reset)
            state <= RESET;
        else
            state <= next_state;

    assign tag = entry[entry_width-1:data_width];
    assign cached_addr = {tag,entry_addr};
    assign dirty = entry[entry_width-1];
    always @(*) begin
        next_state = RESET;
        case (state)
            RESET: begin
                next_state = RESET;
                if (reset_done)
                    next_state = IDLE;
                end
            IDLE: begin
                next_state = IDLE;
                if (request_received)
                    next_state = RECEIVED;
                end
            RECEIVED: begin
                next_state = MISS;
                if (cached_addr == addr_buf && !dirty)
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
            ir_addr_ready <= 0;
            bus_ir_data_ready <= 0;
        end
        else if (state == IDLE) begin
            ir_addr_ready <= 1;
            bus_ir_data_ready <= 1;
        end

    assign entry_addr = addr_buf[entry_addr_width-1:0];
    always @(posedge clock)
        if (request_received) begin
            entry <= mem[entry_addr];
        end else if (bus_ir_data_ready && bus_ir_data_valid) begin
            entry <= {1'b0,addr_buf[addr_width-1:entry_addr_width],bus_ir_data};
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
            mem[addr_buf[entry_addr_width-1:0]] <= {1'b0,addr_buf[addr_width-1:entry_addr_width],bus_ir_data};
            data_received <= 1;
        end

    assign reset_done = &reset_counter;
    assign reset_value = {1'b1,{tag_width{1'b0}},{data_width{1'b0}}};
    always @(posedge clock)
        if (reset)
            reset_counter <= 0;
        else if (state == RESET) begin
            mem[reset_counter] <= reset_value;
            reset_counter <= reset_counter + 1;
        end

endmodule

