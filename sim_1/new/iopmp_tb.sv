`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/30/2022 03:07:16 PM
// Design Name: 
// Module Name: iopmp_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module iopmp_tb( );

// Step 1: Internal signals declaration
logic           clk;
logic           reset_n;
logic [32-1:0]  reg_addr;
logic           en;
logic           we;
logic [63:0]    wdata;
logic [63:0]    rdata;

logic [63:0]    handle;

localparam ADDR_UT = 64'h5000_0000 + iopmp_pkg::IOPMP_MDLCK_OFF;
// Step 2: Unit under test instantiation
iopmp #(
    .PLEN(56),
    .IOPMP_LEN(54),
    // IOPMP parameters specification
    .NR_MD(2),
    .NR_ENTRIES(8),
    .NR_MASTERS(2),
    // AXI parameters specification
    .AXI_ADDR_WIDTH(32)
) uut(
    .clk_i(clk),
    .rst_ni(reset_n),
    .address_cfg(reg_addr),
    .en_cfg(en),
    .we_cfg(we),
    .wdata_cfg(wdata),
    .rdata_cfg(rdata)
);

// Step 3: Stimulus generation
// reset the system

// clock generation
always begin
    clk <= 1;
    #(5);
    clk <= 0;
    #(5);
end

// registers write and read test
initial begin
    reset_n = 0;
    #(1);
    reset_n = 1;
    #(22);

    // // Test to entry_config registers
    // for (integer i = iopmp_pkg::IOPMP_ENTRY_CFG_OFF, integer j = 0; i <= iopmp_pkg::IOPMP_ENTRY_CFG_OFF + (8*2); i = i + 1, j = j+1) begin
    //     reg_addr    = i;
    //     en          = 1;
    //     we          = 1;
    //     wdata       = 8'b1010_0111;
    //     #(10);
    //     we = 0;
    //     #(1);
    //     if((rdata[7:0] == 8'b1000_0111)) begin
    //         $display("Success %d", j);
    //     end
    //     #(10);
    // end

    // // Test to entry_addr registers
    // for (integer i = iopmp_pkg::IOPMP_ENTRY_ADDR_OFF, integer j = 0; i <= iopmp_pkg::IOPMP_ENTRY_ADDR_OFF + (8*2)*8; i = i + 8, j = j+1) begin
    //     reg_addr    = i;
    //     en          = 1;
    //     we          = 1;
    //     wdata       = i;
    //     #(10);
    //     we = 0;
    //     #(1);
    //     if((rdata == i)) begin
    //         $display("Success %d", j);
    //     end else begin
    //         $display("ERROR");
    //     end
    //     #(10);
    // end

    // Test to entry_config and entry_addr registers
    reg_addr    = 64'h5000_0000 + iopmp_pkg::IOPMP_ENTRY_ADDR_OFF + 3*8;
    en          = 1;
    we          = 1;
    wdata       = '1;
    #(10);
    we          = 0;
    #(1);
    if((rdata == 54'h3fffffffffffff) ) begin
        $display("[success1]");
    end
    #(10);   
    reg_addr    = 64'h5000_0000 + iopmp_pkg::IOPMP_ENTRY_CFG_OFF + 3;
    en          = 1;
    we          = 1;
    wdata       = 8'b1010_0111;
    #(10);
    we          = 0;
    #(10);
    if((rdata[7:0] == 8'b1000_0111) ) begin
        $display("[success2]");
    end
    #(10);
    reg_addr    = 64'h5000_0000 + iopmp_pkg::IOPMP_ENTRY_ADDR_OFF + 3*8;
    en          = 1;
    we          = 1;
    wdata       = '0;
    #(10);
    we          = 0;
    #(10);
    if((rdata == 54'h3fffffffffffff) ) begin
        $display("[success3]");
    end

    // // Test to MDLCK
    // reg_addr    = 64'h5000_0000 + iopmp_pkg::IOPMP_MDLCK_OFF;
    // en          = 1;
    // we          = 1;
    // wdata       = 32'h7FFF_FFFF;
    // #(10);
    // we          = 0;
    // #(1);
    // if((rdata == 32'h8000_0000) ) begin
    //     $display("[success]");
    // end

    // // Test to MDCFG registers
    // for (integer i = iopmp_pkg::IOPMP_MDCFG_OFF, integer j = 1; i <= iopmp_pkg::IOPMP_MDCFG_OFF + 4; i = i + 'h4, j = j +1) begin
    //     reg_addr    = i;
    //     en          = 1;
    //     we          = 0;
    //     wdata       = '0;
    //     handle[15:0] = (j * 'h8);
    //     #(5);
    //     if((rdata[31:0] == {16'h8000, handle[15:0]})) begin
    //         $display("Success");
    //     end
    //     #(10);
    // end

    // // Test to SRCMD and MDMSK registers
    // reg_addr    = 64'h5000_0000 + iopmp_pkg::IOPMP_MDMASK_OFF;
    // en          = 1;
    // we          = 1;
    // wdata       = 64'h8000_0000_0001_0001;
    // #(10);
    // we          = 0;
    // #(1);
    // if((rdata == wdata) ) begin
    //     $display("Write %h to %h [success]", wdata, reg_addr);
    // end

    // #(10);
    // reg_addr    = 64'h5000_0000 + iopmp_pkg::IOPMP_SRCMD_OFF;
    // en          = 1;
    // we          = 1;
    // wdata       = '1;
    // #(10);
    // we          = 0;
    // #(1);
    // if((rdata == (wdata - 64'h0000_0000_0001_0001)) ) begin
    //     $display("%h, [success] %h", rdata, reg_addr);
    // end

    // #(10);
    // reg_addr    = 64'h5000_0000 + iopmp_pkg::IOPMP_SRCMD_OFF + 'h8;
    // en          = 1;
    // we          = 1;
    // wdata       = '1;
    // #(10);
    // we          = 0;
    // #(1);
    // if((rdata == (wdata - 64'h0000_0000_0001_0001)) ) begin
    //     $display("%h, [success] %h", rdata, reg_addr);
    // end

    // // Test to SRCMD registers
    // for (integer i = iopmp_pkg::IOPMP_SRCMD_OFF; i <= IOPMP_SRCMD_OFF + 8; i = i + 'h4) begin
    //     reg_addr    = i;
    //     en          = 1;
    //     we          = 1;
    //     wdata       = '1;
    //     #(10);
    //     we          = 0;
    //     #(1);
    //     if((rdata == wdata) ) begin
    //         $display("Write %h to %h [success]", wdata, i);
    //     end

    //     #(10);
    //     we          = 1;
    //     wdata       = '0;
    //     #(10);
    //     we          = 0;
    //     #(10);
    //     if((rdata == '1)) begin
    //         $display("Data on %h still the same [success]",i);
    //     end

    // end

    $finish;
end

endmodule
