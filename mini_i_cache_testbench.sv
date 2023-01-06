`default_nettype none
`include "svut_h.sv"
`timescale 1 ns / 100 ps

interface mini_i_cache_bfm;
    // DUT parameters begin
    parameter int data_width = 32;
    parameter int addr_width = 32;
    // DUT parameters end

    // DUT ports begin
    logic clk;
    logic rst;
    logic ir_data_valid;
    logic ir_addr_ready;
    logic [data_width-1:0] ir_data;
    logic ir_data_ready;
    logic ir_addr_valid;
    logic [addr_width-1:0] ir_addr;
    logic bus_ir_data_valid;
    logic bus_ir_addr_ready;
    logic [data_width-1:0] bus_ir_data;
    logic bus_ir_data_ready;
    logic bus_ir_addr_valid;
    logic [addr_width-1:0] bus_ir_addr;
    // DUT ports end

    string tag = "mini_i_cache_bfm: ";
    integer svut_error = 0;
    initial begin
        ir_data_ready = 1;
        clk = 0;
        rst = 0;
        forever begin
            #5;
            clk = ~clk;
        end
    end
    task info(string msg);
        `INFO($sformatf(tag,msg));
    endtask : info
    task error(string msg);
        `ERROR($sformatf(tag,msg));
    endtask : error
    task reset();
        info("reset");
        @(negedge clk);
        rst = 1;
        @(negedge clk);
        rst = 0;
    endtask : reset
    task read(input int addr, output int data);
        assert(!$isunknown(ir_addr_ready)) else error("read ir_addr_ready is unknown");
        while(!ir_addr_ready)
            @(negedge clk);
        info($sformatf("read addr 0x%0X",addr));
        ir_addr = addr;
        ir_addr_valid = 1;
        @(negedge clk);
        ir_addr_valid = 0;
        while(!ir_data_valid)
            @(negedge clk);
        assert(!$isunknown(ir_data_valid)) else error("read ir_data_valid has X or Z bits");
        data = ir_data_valid;
        info($sformatf(tag,"read addr=0x%0X data=0x%0X",addr,data));
    endtask : read
    task bus_recv(output int addr);
    endtask : bus_recv
    task bus_reply(input int data);
    endtask : bus_reply
endinterface

module mini_i_cache_testbench();

    `SVUT_SETUP

    int addr, raddr, data, rdata;

    mini_i_cache_bfm bfm ();

    mini_i_cache #(
        .data_width (32),
        .addr_width (32)
    ) dut (
        .clock             (bfm.clk),
        .reset             (bfm.rst),
        .ir_data_valid     (bfm.ir_data_valid),
        .ir_addr_ready     (bfm.ir_addr_ready),
        .ir_data           (bfm.ir_data),
        .ir_data_ready     (bfm.ir_data_ready),
        .ir_addr_valid     (bfm.ir_addr_valid),
        .ir_addr           (bfm.ir_addr),
        .bus_ir_data_valid (bfm.bus_ir_data_valid),
        .bus_ir_addr_ready (bfm.bus_ir_addr_ready),
        .bus_ir_data       (bfm.bus_ir_data),
        .bus_ir_data_ready (bfm.bus_ir_data_ready),
        .bus_ir_addr_valid (bfm.bus_ir_addr_valid),
        .bus_ir_addr       (bfm.bus_ir_addr)
    );

    // To dump data for visualization:
    initial begin
        $dumpfile("mini_i_cache_testbench.vcd");
        $dumpvars(0, mini_i_cache_testbench);
    end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        // setup() runs when a test begins
        bfm.reset();
        bfm.svut_error = 0;
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
        svut_error += bfm.svut_error;
    end
    endtask

    `TEST_SUITE("TESTSUITE_NAME")

    //  Available macros:"
    //
    //    - `MSG("message"):       Print a raw white message
    //    - `INFO("message"):      Print a blue message with INFO: prefix
    //    - `SUCCESS("message"):   Print a green message if SUCCESS: prefix
    //    - `WARNING("message"):   Print an orange message with WARNING: prefix and increment warning counter
    //    - `CRITICAL("message"):  Print a purple message with CRITICAL: prefix and increment critical counter
    //    - `ERROR("message"):     Print a red message with ERROR: prefix and increment error counter
    //
    //    - `FAIL_IF(aSignal):                 Increment error counter if evaluaton is true
    //    - `FAIL_IF_NOT(aSignal):             Increment error coutner if evaluation is false
    //    - `FAIL_IF_EQUAL(aSignal, 23):       Increment error counter if evaluation is equal
    //    - `FAIL_IF_NOT_EQUAL(aSignal, 45):   Increment error counter if evaluation is not equal
    //    - `ASSERT(aSignal):                  Increment error counter if evaluation is not true
    //    - `ASSERT((aSignal == 0)):           Increment error counter if evaluation is not true
    //
    //  Available flag:
    //
    //    - `LAST_STATUS: tied to 1 is last macro did experience a failure, else tied to 0

    `UNIT_TEST("READ_MISS")

        // Describe here the testcase scenario
        //
        // Because SVUT uses long nested macros, it's possible
        // some local variable declaration leads to compilation issue.
        // You should declare your variables after the IOs declaration to avoid that.
        
        addr = 123;
        data = 101;
        fork
            bfm.read(addr,rdata);
            bfm.bus_recv(raddr);
            bfm.bus_reply(data);
        join
        `FAIL_IF_NOT_EQUAL(data,rdata);
        `FAIL_IF_NOT_EQUAL(addr,raddr);

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
