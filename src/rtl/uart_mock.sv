// TODO: Handle invalid addr

module uart_mock (
    input           clk     ,
    input           rst_n   ,
    AXI_LITE.Slave  axi     
);

logic addr_valid, data_valid;
logic aw_valid, w_valid, b_valid;

logic [4 : 0] addr;
logic [7 : 0] data;

assign aw_valid = axi.aw_ready & axi.aw_valid;
assign w_valid = axi.w_ready & axi.w_valid;
assign b_valid = axi.b_ready & axi.b_valid;

assign axi.aw_ready = ~addr_valid;
assign axi.w_ready = ~data_valid;
assign axi.b_valid = addr_valid & data_valid;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )       addr_valid <= 'd0;      else
    if ( aw_valid )     addr_valid <= 'd1;      else
    if ( b_valid )      addr_valid <= 'd0;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )       addr <= 'd0;                    else
    if ( aw_valid )     addr <= axi.aw_addr[4 : 0];     else
    if ( b_valid )      addr <= 'd0;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )       data_valid <= 'd0;      else
    if ( w_valid )      data_valid <= 'd1;      else
    if ( b_valid )      data_valid <= 'd0;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )       data <= 'd0;                else
    if ( w_valid )      data <= axi.w_data[7 : 0];  else
    if ( b_valid )      data <= 'd0;

always_ff @( posedge clk )
    if ( addr_valid & data_valid & addr == 'h04 )
        $write("%c", data);

endmodule