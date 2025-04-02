module metrics_counter #(
    parameter COUNTER_WIDTH =   32  
) (
    input   logic                           clk     ,
    input   logic                           rst_n   ,
    input   logic                           en      ,
    input   logic                           clear   ,
    output  logic   [COUNTER_WIDTH - 1 : 0] cnt     
);

always_ff @( posedge clk or negedge rst_n )
    if ( ~rst_n )                   cnt <= 'd0;         else
    if ( clear )                    cnt <= 'd0;         else
    if ( en )                       cnt <= cnt + 1'b1;

endmodule