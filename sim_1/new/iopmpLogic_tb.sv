`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/15/2022 04:59:52 AM
// Design Name: 
// Module Name: iopmpLogic_tb
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


module iopmpLogic_tb();

    // Step 1: Internal signals declaration
    logic                       clk;
    logic                       reset_n;
    
    // Signals from AXI 4 interface with DMA
    logic [56-1:0]            addr;
    logic                       sid;
    iopmp_pkg::iopmp_access_t   access_type;
    logic [63:0]                data;

    // Signals to AXI 4 interface with Bus
    logic                       allow_transaction;

    // signals from AXI 4 Lite
    logic [31:0]              reg_addr;
    logic                       en;
    logic                       we;
    logic [63:0]                wdata;
    logic [63:0]                rdata;


    iopmp #(
        // IOPMP block parameters
        .PLEN       (56),       // rv64: 56
        .IOPMP_LEN  (54),    // rv64: 54

        // Implementation specific parameters
        .NR_MD      (2),
        .NR_ENTRIES_PER_MD (8),
        .NR_MASTERS (2),

        //  AXI Lite interface parameters
        .AXI_ADDR_WIDTH(32),
        .AXI_DATA_WIDTH(64),
        .AXI_ID_WIDTH  (10)
        
    ) uut (
        //  clock and reset lines
        .clk_i(clk),
        .rst_ni(reset_n),

        // Signals from AXI 4 interface with DMA
        .addr_i(addr),
        .sid_i(sid),
        .access_type_i(access_type),
        .data_i(data),

        // Signals to AXI 4 interface with Bus
        .allow_transaction_o(allow_transaction),
        
        // signals from AXI 4 Lite
        .address_cfg(reg_addr),
        .en_cfg(en),
        .we_cfg(we),
        .wdata_cfg(wdata),
        .rdata_cfg(rdata)
    );

    localparam IOPMP_BASE = 64'h5000_0000;

    // clock generation
    always begin
        clk <= 1;
        #(5);
        clk <= 0;
        #(5);
    end


    // registers write and read test
    initial begin
        reset_n     = 0;
        addr        = '0;
        sid         = 0;
        access_type = iopmp_pkg::ACCESS_NONE;
        data        = '0;
        reg_addr    = '0;
        en          = 0;
        we          = 0;
        wdata       = '0;
        #(1);
        reset_n     = 1;
        #(5);

        // Registers configuration
        
        // 1. Configure iopmp_ctl to enable this iopmp device, 
        //    allow always record illegal transactions and lock the register
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_CTL_OFF;
        en          = 1;
        we          = 1;
        wdata       = 32'hC000_0001;    //  L = 1, RCALL = 1, EN = 1
        #(10);

        // 2. Configure iopmp_srcmd[0] to give access to MD[0]
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_SRCMD_OFF;
        en          = 1;
        we          = 1;
        wdata       = 64'h8000_0000_0000_0001;    //  L = 1, MD[0] = 1
        #(10);
        // 2b. Configure iopmp_srcmd[1] but do not to give access to MD[1]
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_SRCMD_OFF + 8;
        en          = 1;
        we          = 1;
        wdata       = 64'h8000_0000_0000_0002;    //  L = 1, MD[1] = 1, MD[0] = 0
        #(10);

        // 3. Configure iopmp_mdmsk to lock 
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_MDMASK_OFF;
        en          = 1;
        we          = 1;
        wdata       = 64'h8000_0000_0000_0001;    //  L = 1, MD[0] = 1
        #(10);

        // 4a. Configure entry 0 
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_ENTRY_ADDR_OFF;
        en          = 1;
        we          = 1;
        wdata       = 64'h0000_0000_0000_1000;  // O que ele vai ler é na verdade 0x1000 << 2 = 0x4000
        #(10);
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_ENTRY_CFG_OFF;
        en          = 1;
        we          = 1;
        wdata       = 8'b1001_1101; // |L|R[6:5]|A[4:3]|I|W|R| A = 11 = NAPOT
        #(10);
        // 4b. Configure entry 1 
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_ENTRY_ADDR_OFF + 8;
        en          = 1;
        we          = 1;
        wdata       = 64'h0000_0000_0000_2000; // O que ele vai ler é na verdade 0x2000 << 2 = 0x8000
        #(10);
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_ENTRY_CFG_OFF + 1;
        en          = 1;
        we          = 1;
        wdata       = 8'b1001_1110; // |L|R[6:5]|A[4:3]|I|W|R| A = 11 = NAPOT
        #(10);
        // 4c. Configure entry 1 
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_ENTRY_ADDR_OFF + 8*2;
        en          = 1;
        we          = 1;
        wdata       = 64'h0000_0000_0000_3000; // O que ele vai ler é na verdade 0x1000 << 2 = 0xC000
        #(10);
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_ENTRY_CFG_OFF + 1*2;
        en          = 1;
        we          = 1;
        wdata       = 8'b1000_1110; // |L|R[6:5]|A[4:3]|I|W|R| A = 01 = TOR
        #(10);
        // 4a. Configure entry 8 
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_ENTRY_ADDR_OFF + 8*8;
        en          = 1;
        we          = 1;
        wdata       = 64'h0000_0000_0000_4000;  // O que ele vai ler é na verdade 0x4000 << 2 = 0x10000
        #(10);
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_ENTRY_CFG_OFF + 1*8;
        en          = 1;
        we          = 1;
        wdata       = 8'b1001_1101; // |L|R[6:5]|A[4:3]|I|W|R| A = 11 = NAPOT
        #(10);


        // 5. Try to access mem position 0x4007 for a read. It should be possible.
        en = 0; //disable register configuration  
        addr        = 64'h0000_0000_0000_4007;
        sid         = 0;
        access_type = iopmp_pkg::ACCESS_READ;
        data        = '0;
        #(10);
        if(allow_transaction) begin
            $display("[Success] Memory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end else begin
            $display("[Failed] Failed to access memory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end
        #(10);

        // 5. Try to access mem position 0x4007 for a read with SID 1. It should NOT be possible.
        en = 0; //disable register configuration  
        addr        = 64'h0000_0000_0000_4007;
        sid         = 1;
        access_type = iopmp_pkg::ACCESS_READ;
        data        = '0;
        #(10);
        if(allow_transaction) begin
            // In this case faild if can access.
            $display("[Failed] Memory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end else begin
            $display("[Success] Failed to access memory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end
        #(10);
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_RCD_OFF;
        en          = 1;
        we          = 0;
        #(1)
        if(rdata[31])begin // this means that an illegal transaction was caught
            $display("iopmp_rcd:");
            $display("---------------------------------------------------");
            $display("|ILLCGT: %x | EXTRA: %x | LEN: %x | R: %x | SID: %x|", rdata[31], rdata[30:28], rdata[27:15], rdata[14], rdata[13:0]);
            $display("---------------------------------------------------");
        end
        #(10);

        // 5. Try to access mem position 0x4007 for a write. It should NOT be possible.
        en = 0; //disable register configuration  
        addr        = 64'h0000_0000_0000_4007;
        sid         = 0;
        access_type = iopmp_pkg::ACCESS_WRITE;
        data        = '0;
        #(10);
        if(allow_transaction) begin
            // In this case faild if can access.
            $display("[Failed] Memory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end else begin
            $display("[Success] Fialed to access emory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end
        #(10);
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_RCD_OFF;
        en          = 1;
        we          = 0;
        #(1)
        if(rdata[31])begin // this means that an illegal transaction was caught
            $display("iopmp_rcd:");
            $display("---------------------------------------------------");
            $display("|ILLCGT: %x | EXTRA: %x | LEN: %x | R: %x | SID: %x|", rdata[31], rdata[30:28], rdata[27:15], rdata[14], rdata[13:0]);
            $display("---------------------------------------------------");
        end
        #(10);

        // 6. Try to access mem position 0x9400 for a write. It should be possible.
        en = 0; //disable register configuration  
        addr        = 64'h0000_0000_0000_9400;
        sid         = 0;
        access_type = iopmp_pkg::ACCESS_WRITE;
        data        = '0;
        #(10);
        if(allow_transaction) begin
            $display("[Success] Memory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end else begin
            $display("[Failed] Failed to access memory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end
        #(10);

        // 6. Try to access mem position 0x9400 for a read. It should NOT be possible.
        en = 0; //disable register configuration  
        addr        = 64'h0000_0000_0000_9400;
        sid         = 0;
        access_type = iopmp_pkg::ACCESS_READ;
        data        = '0;
        #(10);
        if(allow_transaction) begin
            $display("[Failed] Memory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end else begin
            $display("[Success] Failed to access memory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end
        #(10);
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_RCD_OFF;
        en          = 1;
        we          = 0;
        #(1)
        if(rdata[31])begin // this means that an illegal transaction was caught
            $display("iopmp_rcd:");
            $display("---------------------------------------------------");
            $display("|ILLCGT: %x | EXTRA: %x | LEN: %x | R: %x | SID: %x|", rdata[31], rdata[30:28], rdata[27:15], rdata[14], rdata[13:0]);
            $display("---------------------------------------------------");
        end
        #(10);
        #(10);
        reg_addr    = IOPMP_BASE + iopmp_pkg::IOPMP_RCD_ADDR_OFF;
        en          = 1;
        we          = 0;
        #(1)
        $display("iopmp_rcd_addr:");
        $display("---------------------------------------------------");
        $display("|ILLCGT:%x                                ", rdata);
        $display("---------------------------------------------------");
        #(10);

        // 5. Try to access mem position 0x10007 for a read. It should be possible.
        en = 0; //disable register configuration  
        addr        = 64'h0000_0000_0000_10007;
        sid         = 1;
        access_type = iopmp_pkg::ACCESS_READ;
        data        = '0;
        #(10);
        if(allow_transaction) begin
            $display("[Success] Memory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end else begin
            $display("[Failed] Failed to access memory position: %x, Access type: %x, SID: %x", addr, access_type, sid);
        end
        #(10);

        $finish;
    end

endmodule
