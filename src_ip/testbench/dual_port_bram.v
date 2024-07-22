module dual_port_bram #(
    parameter WIDTH = 32,
    parameter DEPTH = 16
) (
    // Port 0
    input                          clk0  ,
    input      [$clog2(DEPTH)-1:0] addr0 ,
    input                          ce0   ,
    input                          we0   ,
    output reg [WIDTH-1:0]         q0    ,
    input      [WIDTH-1:0]         d0    ,

    // Port 1
    input                          clk1  ,
    input      [$clog2(DEPTH)-1:0] addr1 ,
    input                          ce1   ,
    input                          we1   ,
    output reg [WIDTH-1:0]         q1    ,
    input      [WIDTH-1:0]         d1    
);

    (* ram_style = "block" *) reg [WIDTH-1:0] ram[0:DEPTH-1];

    // Port 0
    always @(posedge clk0) begin
        if (ce0) begin
            if (we0)
                ram[addr0] <= d0;
            else
                q0 <= ram[addr0];
        end
    end

    // Port 1
    always @(posedge clk1) begin
        if (ce1) begin
            if (we1)
                ram[addr1] <= d1;
            else
                q1 <= ram[addr1];
        end
    end

endmodule
