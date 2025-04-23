`ifndef MA_CVXIF_TYPES_SVH
`define MA_CVXIF_TYPES_SVH

//CVXIF
`define MA_READREGFLAGS_T(Cfg) logic [Cfg.X_NUM_RS+Cfg.X_DUALREAD-1:0]
`define MA_WRITEREGFLAGS_T(Cfg) logic [Cfg.X_DUALWRITE:0]
`define MA_ID_T(Cfg) logic [Cfg.X_ID_WIDTH-1:0]
`define MA_HARTID_T(Cfg) logic [Cfg.X_HARTID_WIDTH-1:0]

`define MA_X_COMPRESSED_REQ_T(Cfg, hartid_t) struct packed { \
    logic [15:0] instr; /*Offloaded compressed instruction*/ \
    hartid_t     hartid;  /*Identification of the hart offloading the instruction*/ \
}
`define MA_X_COMPRESSED_RESP_T(Cfg) struct packed { \
    logic [31:0] instr; /*Uncompressed instruction*/ \
    logic accept; /*Is the offloaded compressed instruction (id) accepted by the coprocessor?*/ \
}

`define MA_X_ISSUE_REQ_T(Cfg, hartid_t, id_t) struct packed { \
    logic [31:0] instr; /*Offloaded instruction*/ \
    hartid_t hartid; /*Identification of the hart offloading the instruction*/ \
    id_t id; /*Identification of the offloaded instruction*/ \
}
`define MA_X_ISSUE_RESP_T(Cfg, writeregflags_t, readregflags_t) struct packed { \
    logic accept; /*Is the offloaded instruction (id) accepted by the coprocessor?*/ \
    writeregflags_t writeback; /*Will the coprocessor perform a writeback in the core to rd?*/ \
    readregflags_t register_read; /*Will the coprocessor perform require specific registers to be read?*/ \
}

`define MA_X_REGISTER_T(Cfg, hartid_t, id_t, readregflags_t) struct packed { \
    hartid_t hartid;  /*Identification of the hart offloading the instruction*/ \
    id_t id;  /*Identification of the offloaded instruction*/ \
    logic [Cfg.X_NUM_RS-1:0][Cfg.X_RFR_WIDTH-1:0] rs;  /*Register file source operands for the offloaded instruction.*/ \
    readregflags_t rs_valid; /*Validity of the register file source operand(s).*/ \
}

`define MA_X_COMMIT_T(Cfg, hartid_t, id_t) struct packed { \
    hartid_t hartid;  /*Identification of the hart offloading the instruction*/ \
    id_t id;  /*Identification of the offloaded instruction*/ \
    logic commit_kill;  /*Shall an offloaded instruction be killed?*/ \
}

`define MA_X_RESULT_T(Cfg, hartid_t, id_t, writeregflags_t) struct packed { \
    hartid_t hartid;  /*Identification of the hart offloading the instruction*/ \
    id_t id;  /*Identification of the offloaded instruction*/ \
    logic [Cfg.X_RFW_WIDTH-1:0] data;  /*Register file write data value(s)*/ \
    logic [4:0] rd;  /*Register file destination address(es)*/ \
    writeregflags_t we;  /*Register file write enable(s)*/ \
}

`define MA_CVXIF_REQ_T(Cfg, x_compressed_req_t, x_issue_req_t, x_register_req_t, x_commit_t) struct packed { \
    logic              compressed_valid; \
    x_compressed_req_t compressed_req; \
    logic              issue_valid; \
    x_issue_req_t      issue_req; \
    logic              register_valid; \
    x_register_req_t   register; \
    logic              commit_valid; \
    x_commit_t         commit; \
    logic              result_ready; \
}

`define MA_CVXIF_RESP_T(Cfg, x_compressed_resp_t, x_issue_resp_t, x_result_t) struct packed { \
    logic               compressed_ready; \
    x_compressed_resp_t compressed_resp; \
    logic               issue_ready; \
    x_issue_resp_t      issue_resp; \
    logic               register_ready; \
    logic               result_valid; \
    x_result_t          result; \
}

`endif // MA_CVXIF_TYPES_SVH
