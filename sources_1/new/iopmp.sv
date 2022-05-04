
// Author: Francisco Marques, University of Minho
// Date: 23/04/2022
// Description: A RISC-V IOPMP implementation (based on IOPMPand IOMMU meetings. Don't implement any official specification) 
//

import iopmp_pkg::*;


module iopmp #(
    // IOPMP block parameters
    parameter int unsigned PLEN = 34,       // rv64: 56
    parameter int unsigned IOPMP_LEN = 32,    // rv64: 54

    // Implementation specific parameters
    parameter int unsigned NR_MD = 2,
    parameter int unsigned NR_ENTRIES = 8,
    parameter int unsigned NR_MASTERS = 2,

    //  AXI interface parameters
    parameter int unsigned AXI_ADDR_WIDTH = 32,
    parameter int unsigned AXI_DATA_WIDTH = 32,
    parameter int unsigned AXI_ID_WIDTH   = 10
    
) (
    //  clock and reset lines
    input   logic                   clk_i,
    input   logic                   rst_ni,
    
    // signals from AXI 4 Lite
    input   logic [AXI_ADDR_WIDTH-1:0]  address_cfg,
    input   logic                       en_cfg,
    input   logic                       we_cfg,
    input   logic [63:0]                wdata_cfg,
    output  logic [63:0]                rdata_cfg

);
    // It need to be riscv:XLEN in final implementation
    localparam XLEN = 64;

    // Allow to select the:
    // Master among all the masters;
    localparam AddrSIDSelWidth = (NR_MASTERS == 1) ? 1 : $clog2(NR_MASTERS);  
    // Memory Domain among all the Memory Domain;
    localparam AddrMDSelWidth = (NR_MD == 1) ? 1 : $clog2(NR_MD);  
    // Entry among all the Entry;
    localparam AddrEntrySelWidth = ((NR_ENTRIES*NR_MD) == 1) ? 1 : $clog2((NR_ENTRIES * NR_MD));   

    logic [15:0] register_address_cfg;
    assign register_address_cfg = address_cfg[15:0];
    // actual registers implemented
    iopmp_pkg::iopmp_ctl_t                      iopmp_ctl_d, iopmp_ctl_q;               
    iopmp_pkg::iopmp_rcd_t                      iopmp_rcd_d, iopmp_rcd_q;               
    logic [63:0]                                iopmp_rcd_addr_d, iopmp_rcd_addr_q;     
    iopmp_pkg::iopmp_mdmsk_t                    iopmp_mdmask_d, iopmp_mdmask_q;         
    iopmp_pkg::iopmp_mdlck_t                    iopmp_mdlck_d, iopmp_mdlck_q;           
    iopmp_pkg::iopmp_mdcfg_t [NR_MD-1:0]        iopmp_mdcfg_d, iopmp_mdcfg_q;           
    logic [15:0][IOPMP_LEN-1:0]                 iopmp_entry_addr_d, iopmp_entry_addr_q;
    // the value 15 means: NR_ENTRIES * NR_MD
    iopmp_pkg::iopmp_entry_t   [15:0]           iopmp_entry_cfg_d, iopmp_entry_cfg_q; 
    iopmp_pkg::iopmp_srcmd_t [NR_MASTERS-1:0]   iopmp_srcmd_d, iopmp_srcmd_q;           


    // Hardwired Values
    assign iopmp_mdlck_d.L              = '1;
    assign iopmp_mdlck_d.reserved       = 15'b0;
    assign iopmp_mdlck_d.F              = 16'b1;

    always_comb begin
        for ( int unsigned i = 0; i < NR_MD; i = i + 1) begin
            iopmp_mdcfg_d[i].T  = ((i + 1) * NR_ENTRIES);
            iopmp_mdcfg_d[i].F  = '0;
            iopmp_mdcfg_d[i].L  = 1'b1;
        end
    end 

    // -----------------------------
    // Configuration Registers Update Logic
    // -----------------------------
    // APB register write logic
    always_comb begin
        iopmp_ctl_d         = iopmp_ctl_q;
        iopmp_mdmask_d      = iopmp_mdmask_q;
        // iopmp_mdcfg_d       = iopmp_mdcfg_q;
        iopmp_entry_addr_d  = iopmp_entry_addr_q;
        iopmp_entry_cfg_d   = iopmp_entry_cfg_q;
        iopmp_srcmd_d       = iopmp_srcmd_q;

        // written from APB bus - gets priority
        if (en_cfg && we_cfg) begin
            case (register_address_cfg) inside
                IOPMP_CTL_OFF: begin
                    if(iopmp_ctl_q.L == 0) begin
                        iopmp_ctl_d = {wdata_cfg[31:30], 29'b0, wdata_cfg[0]};
                    end
                end            

                IOPMP_MDMASK_OFF: begin

                    if(iopmp_mdmask_q.L == 0) begin
                        if (XLEN == 32) begin
                            iopmp_mdmask_d[31:0] = wdata_cfg[31:0]; 
                        end else begin
                            iopmp_mdmask_d = wdata_cfg;
                        end
                    end
            
                end

                [IOPMP_ENTRY_ADDR_OFF: IOPMP_ENTRY_CFG_OFF - 8]: begin
                    if (iopmp_entry_cfg_q[$unsigned(address_cfg[AddrEntrySelWidth-1+3:3])].L  == 0) begin
                        if(XLEN == 32) begin
                            iopmp_entry_addr_d[$unsigned(address_cfg[AddrEntrySelWidth-1+3:3])][31:0] = wdata_cfg[31:0]; 
                        end else begin
                            iopmp_entry_addr_d[$unsigned(address_cfg[AddrEntrySelWidth-1+3:3])] = wdata_cfg;
                        end
                    end 
                end

                [IOPMP_ENTRY_CFG_OFF: IOPMP_SRCMD_OFF - 1]: begin
                    if (iopmp_entry_cfg_q[$unsigned(address_cfg[AddrEntrySelWidth-1:0])].L  == 0) begin
                        // if(XLEN == 32) begin
                        //     iopmp_entry_cfg_d[$unsigned(address_cfg[AddrEntrySelWidth-1:0])][31:0] = wdata_cfg[31:0]; 
                        // end else begin
                            iopmp_entry_cfg_d[$unsigned(address_cfg[AddrEntrySelWidth-1:0])] = {wdata_cfg[7], 2'b0, wdata_cfg[4:0]};
                        // end
                    end
                end

                [IOPMP_SRCMD_OFF: IOPMP_SRCMD_OFF + (8 * (NR_MASTERS-1))]: begin

                    if (iopmp_srcmd_q[$unsigned(address_cfg[AddrSIDSelWidth-1+3:3])].L == 0) begin
                        if(XLEN == 32) begin
                            iopmp_srcmd_d[$unsigned(address_cfg[AddrSIDSelWidth-1+3:3])][31:0] = (wdata_cfg[31:0] & (~iopmp_mdmask_q.md[31:0])) | iopmp_srcmd_q[$unsigned(address_cfg[AddrSIDSelWidth-1+2:2])][31:0]; 
                        end else begin
                            iopmp_srcmd_d[$unsigned(address_cfg[AddrSIDSelWidth-1+3:3])] = (wdata_cfg & (~iopmp_mdmask_q.md)) | iopmp_srcmd_q[$unsigned(address_cfg[AddrSIDSelWidth-1+3:3])]; 
                        end
                    end

                    
                end

                default:;
            endcase
        end
    end

    // APB register read logic
    always_comb begin
        // Reset
        rdata_cfg = 'b0;
        if (en_cfg && !we_cfg) begin
            case (register_address_cfg) inside
                IOPMP_CTL_OFF: begin
                   rdata_cfg[31:0] = iopmp_ctl_q;
                end

                IOPMP_RCD_OFF: begin
                    rdata_cfg[31:0] = iopmp_rcd_q;
                end              

                IOPMP_RCD_ADDR_OFF: begin
                    if(XLEN == 32) begin
                        rdata_cfg[31:0] = iopmp_rcd_addr_q[31:0];
                    end else begin
                        rdata_cfg = iopmp_rcd_addr_q;
                    end
                end

                IOPMP_MDMASK_OFF: begin
                    if(XLEN == 32) begin
                        rdata_cfg[31:0] = iopmp_mdmask_q[31:0];
                    end else begin
                        rdata_cfg = iopmp_mdmask_q;
                    end
                end

                IOPMP_MDLCK_OFF: begin
                    rdata_cfg[31:0] = iopmp_mdlck_q;
                end

                [IOPMP_MDCFG_OFF:IOPMP_ENTRY_ADDR_OFF - 4]: begin
                    // The value 2 is because this register is 32 bits (word aligned) 
                    rdata_cfg[31:0] = iopmp_mdcfg_q[$unsigned(address_cfg[AddrMDSelWidth-1+2:2])]; 
                end

                [IOPMP_ENTRY_ADDR_OFF: IOPMP_ENTRY_CFG_OFF - 8]: begin
                    if(XLEN == 32) begin
                        rdata_cfg[31:0] = iopmp_entry_addr_q[$unsigned(address_cfg[AddrEntrySelWidth-1+3:3])][31:0]; 
                    end else begin
                        rdata_cfg = iopmp_entry_addr_q[$unsigned(address_cfg[AddrEntrySelWidth-1+3:3])];
                    end
                end

                [IOPMP_ENTRY_CFG_OFF: IOPMP_SRCMD_OFF - 1]: begin
                    // if(XLEN == 32) begin
                    //     rdata_cfg[31:0] = iopmp_entry_cfg_q[$unsigned(address_cfg[AddrEntrySelWidth-1:0])][31:0]; 
                    // end else begin
                        rdata_cfg[7:0] = iopmp_entry_cfg_q[$unsigned(address_cfg[AddrEntrySelWidth-1:0])];
                    //end
                end

                [IOPMP_SRCMD_OFF: IOPMP_SRCMD_OFF + (8 * (NR_MASTERS-1))]: begin
                    if(XLEN == 32) begin
                        // The value 3 is because this register is 64 bits (8 words of 8 bits, meaning that I need 3 bits to encode it) (word aligned)
                        rdata_cfg[31:0] = iopmp_srcmd_q[$unsigned(address_cfg[AddrSIDSelWidth-1+3:3])][31:0]; 
                    end else begin
                        rdata_cfg = iopmp_srcmd_q[$unsigned(address_cfg[AddrSIDSelWidth-1+3:3])];
                    end
                end
                default:;
            endcase
        end
    end

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // axi
            iopmp_ctl_q         <= '0;
            iopmp_rcd_q         <= '0;
            iopmp_rcd_addr_q    <= '0;
            iopmp_mdmask_q      <= '0;
            // iopmp_mdlck_q       <= '0;
            // iopmp_mdcfg_q       <= 'b0;
            iopmp_entry_addr_q  <= 'b0;
            iopmp_entry_cfg_q   <= 'b0;
            iopmp_srcmd_q       <= 'b0;

        end else begin
            iopmp_ctl_q         <= iopmp_ctl_d;
            iopmp_rcd_q         <= iopmp_rcd_d;
            iopmp_rcd_addr_q    <= iopmp_rcd_addr_d;
            iopmp_mdmask_q      <= iopmp_mdmask_d;
            iopmp_mdlck_q       <= iopmp_mdlck_d;
            iopmp_mdcfg_q       <= iopmp_mdcfg_d;
            iopmp_entry_addr_q  <= iopmp_entry_addr_d;
            iopmp_entry_cfg_q   <= iopmp_entry_cfg_d;
            iopmp_srcmd_q       <= iopmp_srcmd_d;

        end
    end
endmodule
