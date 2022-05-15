

package iopmp_pkg;

//localparam  NR_ENTRIES_PER_MD        = 8;

//  MAX Number of: 
localparam  NR_MEMORY_DOMAINS_MAX    = 63;
localparam  NR_ENTRIES_MAX           = 32;

//  Local Parameters to allow easy changes in the future
localparam  MDCFG_OFFSET         = 4 * (NR_MEMORY_DOMAINS_MAX);
localparam  ENTRY_ADDR_OFFSET    = MDCFG_OFFSET + (8 *  (NR_ENTRIES_MAX+1));
localparam  ENTRY_CFG_OFFSET     = ENTRY_ADDR_OFFSET + 4 *  (NR_ENTRIES_MAX);

//  Registers OFF 
localparam  int  IOPMP_CTL_OFF           = 16'h0;    // IOPMP control register
localparam  int  IOPMP_RCD_OFF           = 16'h4;
localparam  int  IOPMP_RCD_ADDR_OFF      = 16'h8;
//localparam  int  IOPMP_RCD_ADDR_H_OFF      = 16'hc;
localparam  int  IOPMP_MDMASK_OFF        = 16'h10;
// localparam  int  IOPMP_MDMASK_L_OFF      = 16'h10;
// localparam  int  IOPMP_MDMASK_H_OFF      = 16'h14;
localparam  int  IOPMP_MDLCK_OFF         = 16'h18;
localparam  int  IOPMP_MDCFG_OFF         = 16'h100;            
localparam  int  IOPMP_ENTRY_ADDR_OFF    = 16'h104 + MDCFG_OFFSET;      //0x1FC
// localparam  int  IOPMP_ENTRY_ADDR_L_OFF  = 16'h104 + MDCFG_OFFSET;    
// localparam  int  IOPMP_ENTRY_ADDR_H_OFF  = 16'h108 + MDCFG_OFFSET; 
localparam  int  IOPMP_ENTRY_CFG_OFF     = 16'h10c + ENTRY_ADDR_OFFSET;
localparam  int  IOPMP_SRCMD_OFF         = 16'h110 + ENTRY_CFG_OFFSET;
// localparam  int  IOPMP_SRCMD_L_OFF       = 16'h110 + ENTRY_CFG_OFFSET;
// localparam  int  IOPMP_SRCMD_H_OFF       = 16'h114 + ENTRY_CFG_OFFSET;


typedef struct packed {
        logic   L;    // Lock this register
        logic   rcall;
        logic   [29:1] reserved;                
        logic   enable;
} iopmp_ctl_t;

typedef struct packed {
        logic   illcgt;
        logic   [30:28] extra;  
        logic   [27:15] length;
        logic   read;
        logic   [13:0] sid;
} iopmp_rcd_t;

typedef struct packed {
        logic  L;
        logic  [62:0] md;
} iopmp_srcmd_t;

typedef struct packed {
        logic  L;
        logic  [30:16] F;
        logic  [15:0] T;
} iopmp_mdcfg_t;

typedef struct packed {
        logic  L;
        logic  [62:0] md;
} iopmp_mdmsk_t;

typedef struct packed {
        logic  L;
        logic  [30:16] reserved;
        logic  [15:0] F;
} iopmp_mdlck_t;

//  IOPMP Entry 
typedef enum logic [1:0] {
    OFF   = 2'b00,
    TOR   = 2'b01,
    NA4   = 2'b10,
    NAPOT = 2'b11
} iopmp_addr_mode_t;

typedef struct packed {
    logic           w;  //  write
    logic           r;  //  read
} iopmpcfg_access_t;

// PMP Access Type
typedef enum logic [1:0] {
        ACCESS_NONE     = 2'b00,
        ACCESS_READ     = 2'b01,
        ACCESS_WRITE    = 2'b10
} iopmp_access_t;

// packed struct of a PMP configuration register (8bit)
typedef struct packed {
    logic               L;     // lock this configuration
    logic [6:5]         reserved;
    iopmp_addr_mode_t   addr_mode;  // Off, TOR, NA4, NAPOT
    logic               interrupt;
    iopmpcfg_access_t   access_type;
} iopmp_entry_t;

endpackage
