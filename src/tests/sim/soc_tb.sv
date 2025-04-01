`include "soc_parameters.svh"

import "DPI-C" function void read_elf (input string filename);
import "DPI-C" function byte get_section (output longint address, output longint len);
import "DPI-C" context function byte read_section(input longint address, inout byte buffer[]);

`timescale 1ns/1ps

module soc_tb ();

localparam CLOCK_PERIOD  = 2ns;
localparam AXI_DATA_WIDTH   = `SOC_AXI_DATA_WIDTH;
localparam AXI_ADDR_WIDTH   = `SOC_AXI_ADDR_WIDTH;
localparam AXI_DATA_BYTE_WIDTH = AXI_DATA_WIDTH / 8;
localparam AXI_BYTE_OFFSET = $clog2(AXI_DATA_BYTE_WIDTH);

localparam RAM_BASE   = `SOC_RAM_BASE;
localparam RAM_LENGTH = `SOC_RAM_LENGTH;


typedef logic [AXI_DATA_WIDTH-1:0] axi_data_t;
typedef logic [AXI_ADDR_WIDTH-1:0] axi_addr_t;


logic clk;
logic rst_n;

initial begin
    clk   = 1'b0;
    rst_n = 1'b0;
    // Synch reset for TB memories
    repeat (10) #(CLOCK_PERIOD/2) clk = ~clk;
    clk = 1'b0;

    // Asynch reset for main system
    repeat (5) #(CLOCK_PERIOD);
    rst_n = 1'b1;
    repeat (5) #(CLOCK_PERIOD);
    $display("-------- STDOUT --------");
    // Start the clock
    forever #(CLOCK_PERIOD/2) clk = ~clk;
end

initial begin : dram_init
    automatic axi_data_t mem_row;
    byte buffer [];
    axi_addr_t address;
    axi_addr_t length;
    string binary;

    // tc_sram is initialized with zeros. We need to overwrite this value.
    repeat (2)
      #CLOCK_PERIOD;

    // Initialize memories
    void'($value$plusargs("PRELOAD=%s", binary));
    if (binary != "") begin
        // Read ELF
        read_elf(binary);
        $display("Loading ELF file %s", binary);
        while (get_section(address, length)) begin
            // Read sections
            automatic int nwords = (length + AXI_DATA_BYTE_WIDTH - 1)/AXI_DATA_BYTE_WIDTH;
            $display("Loading section %x of length %x", address, length);
            buffer = new[nwords * AXI_DATA_BYTE_WIDTH];
            void'(read_section(address, buffer));
            // Initializing memories
            for (int w = 0; w < nwords; w++) begin
                mem_row = '0;
                for (int b = 0; b < AXI_DATA_BYTE_WIDTH; b++) begin
                    mem_row[8 * b +: 8] = buffer[w * AXI_DATA_BYTE_WIDTH + b];
                end
                if (address >= RAM_BASE && address < RAM_BASE + RAM_LENGTH)
                    // This requires the sections to be aligned to AXI_BYTE_OFFSET,
                    // otherwise, they can be over-written.
                    i_dut.i_dram.init_val[(address - RAM_BASE + (w << AXI_BYTE_OFFSET)) >> AXI_BYTE_OFFSET] = mem_row;
                else
                    $display("Cannot initialize address %x, which doesn't fall into the L2 region.", address);
                end
            end
    end else begin
        $error("Expecting a firmware to run, none was provided!");
        $finish;
    end
end : dram_init

initial begin : wait_for_stop
    wait(i_dut.i_ctrl_regs.reg_q_o[0] == 'hFF);
    $finish();
end

matrix_accelerator_soc i_dut (
    .clk    ( clk   ),
    .rst_n  ( rst_n ),
    .tx     (       ),
    .rx     ( 1'b1  )
);

endmodule
