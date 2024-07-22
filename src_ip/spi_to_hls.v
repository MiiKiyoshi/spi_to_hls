module spi_to_hls #
(
    parameter SPI_MODE   = 3,
    parameter BRAM_WIDTH = 32,
    parameter BRAM_DEPTH = 10,

    parameter integer C_S00_AXI_DATA_WIDTH	= 32,
    parameter integer C_S00_AXI_ADDR_WIDTH	= 6
) (

    output wire [1:0] led   ,

    input  wire i_sclk ,
    output wire o_miso ,
    input  wire i_mosi ,
    input  wire i_ss_n ,

    output wire o_done_intr , // Interrupt for Debugging

    input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready
);
    wire w_clk = s00_axi_aclk;
    wire w_soft_reset;
    wire w_rst_n = s00_axi_aresetn | !w_soft_reset;

    // Commands
    localparam [7:0] CMD_WRITE_VALS    = 8'h01,
                     CMD_READ_VALS     = 8'h02,
                     CMD_CHECK_DONE    = 8'h03,
                     CMD_READ_RESULT1  = 8'h04,
                     CMD_READ_RESULT2  = 8'h05;

    // States
    localparam [2:0] S_IDLE         = 3'd0,
                     S_STORE_VALS   = 3'd1,
                     S_LOAD_VALS    = 3'd2,
                     S_CHECK_DONE   = 3'd3,
                     S_LOAD_RESULT1 = 3'd4,
                     S_LOAD_RESULT2 = 3'd5;

    // SPI Slave Data Port
    wire       w_rx_valid;
    wire [7:0] w_rx_data;
    reg        r_tx_valid;
    reg  [7:0] r_tx_data;

    // Instantiate SPI Slave
    spi_slave #(
        .SPI_MODE(SPI_MODE)
    ) spi_slave_inst (
        .i_rst_n    (w_rst_n   ),
        .i_clk      (w_clk     ),
        .o_rx_valid (w_rx_valid),
        .o_rx_data  (w_rx_data ),
        .i_tx_valid (r_tx_valid),
        .i_tx_data  (r_tx_data ),
        .i_sclk     (i_sclk    ),
        .o_miso     (o_miso    ),
        .i_mosi     (i_mosi    ),
        .i_ss_n     (i_ss_n    )
    );

    // Control signals
    reg [2:0]  r_state;
    reg [1:0]  r_byte_counter;
    reg [3:0]  r_store_addr_counter;
    reg [3:0]  r_load_addr_counter;
    reg        r_store_word_complete;
    reg        r_select;

    reg  [$clog2(BRAM_DEPTH)-1:0] w_bram_addr;
    wire w_store_vals_complete = w_bram_addr == 4'd9 && r_select == 1'd1 && r_store_word_complete;
    wire w_load_vals_complete  = r_byte_counter == 2'd3 && r_load_addr_counter == 4'd9 && r_select == 1'd1 && w_rx_valid;
    wire w_load_result_complete = w_rx_valid && r_byte_counter == 2'd3;

    // State machine
    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            r_state <= S_IDLE;
        end else begin
            case (r_state)
                S_IDLE:
                    if (w_rx_valid)
                        case (w_rx_data)
                            CMD_WRITE_VALS:   r_state <= S_STORE_VALS;
                            CMD_READ_VALS:    r_state <= S_LOAD_VALS;
                            CMD_CHECK_DONE:   r_state <= S_CHECK_DONE;
                            CMD_READ_RESULT1: r_state <= S_LOAD_RESULT1;
                            CMD_READ_RESULT2: r_state <= S_LOAD_RESULT2;
                            default:          r_state <= S_IDLE;
                        endcase
                
                S_STORE_VALS: if (w_store_vals_complete) r_state <= S_IDLE;
                S_LOAD_VALS:  if (w_load_vals_complete ) r_state <= S_IDLE;
                S_CHECK_DONE: if (w_rx_valid           ) r_state <= S_IDLE;
                
                S_LOAD_RESULT1, S_LOAD_RESULT2:
                    if (w_load_result_complete) r_state <= S_IDLE;
                
                default: r_state <= S_IDLE;
            endcase
        end
    end

    assign led = r_state[1:0]; // For Debug

    // Byte counter
    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            r_byte_counter <= 2'd0;
        end else if (w_rx_valid) begin 
            if (r_state != S_IDLE && r_state != S_CHECK_DONE) begin
                if (r_byte_counter == 2'd3) begin
                    r_byte_counter <= 2'd0;
                end else begin
                    r_byte_counter <= r_byte_counter + 1'b1;
                end
            end else begin
                r_byte_counter <= 2'd0;
            end
        end
    end

    // Data buffer
    reg [31:0] r_data_buffer;
    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            r_data_buffer <= 32'd0;
        end else if (w_rx_valid) begin
            if (r_state == S_STORE_VALS) begin
                r_data_buffer <= {w_rx_data, r_data_buffer[31:8]};
            end
        end
    end
    
    // Write enable logic
    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            r_store_word_complete <= 1'b0;
        end else if (w_rx_valid) begin
            r_store_word_complete <= (r_byte_counter == 2'd3);
        end else begin
            r_store_word_complete <= 1'b0;
        end
    end

    // BRAM select logic
    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            r_select <= 1'b0;
        end else if (r_store_word_complete) begin 
            if (r_state == S_STORE_VALS || r_state == S_LOAD_VALS) begin
                r_select <= ~r_select;  
            end else begin
                r_select <= 1'b0;
            end
        end
    end

    // Store address counter logic
    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            r_store_addr_counter <= 4'd0;
        end else if (w_rx_valid) begin
            if (r_state == S_STORE_VALS) begin
                if(r_byte_counter == 2'd3 && r_select == 1'b1) begin
                    if (r_store_addr_counter == 4'd9) begin
                        r_store_addr_counter <= 4'd0;
                    end else begin
                        r_store_addr_counter <= r_store_addr_counter + 1'b1;
                    end
                end
            end else begin
                r_store_addr_counter <= 4'd0;
            end
        end
    end

    // Load address counter logic
    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            r_load_addr_counter <= 4'd0;
        end else if (w_rx_valid) begin
            if (r_state == S_LOAD_VALS) begin
                if (r_byte_counter == 2'd3 && r_select == 1'b1) begin
                    if (r_load_addr_counter == 4'd9) begin
                        r_load_addr_counter <= 4'd0;
                    end else begin
                        r_load_addr_counter <= r_load_addr_counter + 1'b1;
                    end
                end
            end else begin
                r_load_addr_counter <= 4'd0;
            end
        end
    end

    // BRAM signals
    wire [BRAM_WIDTH-1:0] w_bram_data_in;
    wire [BRAM_WIDTH-1:0] w_bram_data_out1, w_bram_data_out2;
    wire                  w_bram_we1, w_bram_we2;

    // BRAM control
    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            w_bram_addr <= 0; 
        end else begin
            if (r_state == S_STORE_VALS) begin
                w_bram_addr <= r_store_addr_counter;
            end else begin
                w_bram_addr <= r_load_addr_counter;
            end
        end
    end
    
    assign w_bram_data_in = r_data_buffer;
    assign w_bram_we1     = r_state == S_STORE_VALS && r_store_word_complete && !r_select;
    assign w_bram_we2     = r_state == S_STORE_VALS && r_store_word_complete && r_select;

    // HLS instance signals
    wire [3:0]  hls_addr;
    wire        hls_ce;
    wire [31:0] hls_data1, hls_data2;
    wire [31:0] hls_result1, hls_result2;
    wire        hls_result1_valid, hls_result2_valid;

    // Dual Port BRAMs
    dual_port_bram #(
        .WIDTH(BRAM_WIDTH),
        .DEPTH(BRAM_DEPTH)
    ) bram_val1_inst (
        .clk0  (w_clk           ),
        .addr0 (w_bram_addr     ),
        .ce0   (1'b1            ),
        .we0   (w_bram_we1      ),
        .q0    (w_bram_data_out1),
        .d0    (w_bram_data_in  ),
        .clk1  (w_clk           ),
        .addr1 (hls_addr        ),
        .ce1   (hls_ce          ),
        .we1   (1'b0            ),
        .q1    (hls_data1       ),
        .d1    (32'd0           )
    );

    dual_port_bram #(
        .WIDTH(BRAM_WIDTH),
        .DEPTH(BRAM_DEPTH)
    ) bram_val2_inst (
        .clk0  (w_clk           ),
        .addr0 (w_bram_addr     ),
        .ce0   (1'b1            ),
        .we0   (w_bram_we2      ),
        .q0    (w_bram_data_out2),
        .d0    (w_bram_data_in  ),
        .clk1  (w_clk           ),
        .addr1 (hls_addr        ),
        .ce1   (hls_ce          ),
        .we1   (1'b0            ),
        .q1    (hls_data2       ),
        .d1    (32'd0           )
    );

    // HLS control signals
    reg  ap_start;
    wire ap_done;
    wire ap_idle;
    wire ap_ready;
    reg  r_ap_done_latch;
    wire hls_start_trigger = ap_idle && r_state == S_STORE_VALS && w_store_vals_complete;

    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            ap_start <= 1'b0;
        end else begin
            if (hls_start_trigger) begin
                ap_start <= 1'b1;
            end else if (ap_ready) begin
                ap_start <= 1'b0;
            end
        end
    end

    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            r_ap_done_latch <= 1'b0;
        end else begin
            if (ap_done) begin
                r_ap_done_latch <= 1'b1;
            end else if (r_state == S_CHECK_DONE && w_rx_valid) begin
                r_ap_done_latch <= 1'b0;
            end else if (hls_start_trigger) begin
                r_ap_done_latch <= 1'b0;
            end
        end
    end

    // Instantiate HLS module
    divide_sum hls_inst (
        .ap_clk             (w_clk            ),
        .ap_rst             (~w_rst_n         ),
        .ap_start           (ap_start         ),
        .ap_done            (ap_done          ),
        .ap_idle            (ap_idle          ),
        .ap_ready           (ap_ready         ),
        .in_val1_address0   (hls_addr         ),
        .in_val1_ce0        (hls_ce           ),
        .in_val1_q0         (hls_data1        ),
        .in_val2_address0   (hls_addr         ),
        .in_val2_ce0        (hls_ce           ),
        .in_val2_q0         (hls_data2        ),
        .out_result1        (hls_result1      ),
        .out_result1_ap_vld (hls_result1_valid),
        .out_result2        (hls_result2      ),
        .out_result2_ap_vld (hls_result2_valid)
    );

    assign o_done_intr = ap_done;

    // LOAD operation and result management
    reg [31:0] r_result1, r_result2;

    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            r_result1 <= 32'd0;
            r_result2 <= 32'd0;
            r_tx_valid <= 1'b0;
            r_tx_data <= 8'd0;
        end else begin
            if (hls_result1_valid) r_result1 <= hls_result1;
            if (hls_result2_valid) r_result2 <= hls_result2;

            case (r_state)
                S_LOAD_VALS: begin
                    r_tx_valid <= 1'b1;
                    r_tx_data <= r_select ? w_bram_data_out2[8*r_byte_counter +: 8]:
                                            w_bram_data_out1[8*r_byte_counter +: 8];
                end
                S_CHECK_DONE: begin
                    r_tx_valid <= 1'b1;
                    r_tx_data <= {7'b0, r_ap_done_latch};
                end
                S_LOAD_RESULT1: begin
                    r_tx_valid <= 1'b1;
                    r_tx_data <= r_result1[8*r_byte_counter +: 8];
                end
                S_LOAD_RESULT2: begin
                    r_tx_valid <= 1'b1;
                    r_tx_data <= r_result2[8*r_byte_counter +: 8];
                end
                default: r_tx_valid <= 1'b0;
            endcase
        end
    end

//  SYSTEM_CONTROL_REG (0x00, read/write)
//      [31:1] : 30'b0 (reserved)
//      [0]    : o_soft_reset
//
//  SPI_STATUS_REG (0x04, read only)
//      [31:19] : 13'b0 (reserved)
//      [18]    : i_store_word_complete
//      [17]    : i_store_vals_complete
//      [16]    : i_load_vals_complete
//      [15:12] : 4'b0 (reserved)
//      [11:10] : i_byte_counter[1:0]
//      [9:6]   : i_store_addr_counter[3:0]
//      [5:2]   : i_load_addr_counter[3:0]
//      [1:0]   : i_state[1:0]
//
//  SPI_DATA_REG (0x08, read only)
//      [31:18] : 14'b0 (reserved)
//      [17]    : i_rx_valid
//      [16]    : i_tx_valid
//      [15:8]  : i_rx_data[7:0]
//      [7:0]   : i_tx_data[7:0]
//
//  DATA_BUFFER_REG (0x0C, read only)
//      [31:0] : i_data_buffer[31:0] (same as i_bram_data_in)
//
//  HLS_STATUS_REG (0x10, read only)
//      [31:6] : 26'b0 (reserved)
//      [5]    : r_ap_done_latch
//      [4]    : i_select
//      [3]    : i_ap_start
//      [2]    : i_ap_done
//      [1]    : i_ap_idle
//      [0]    : i_ap_ready
//
//  RESULT1_REG (0x14, read only)
//      [31:0] : i_result1[31:0]
//
//  RESULT2_REG (0x18, read only)
//      [31:0] : i_result2[31:0]
//
//  BRAM_DATA_OUT1_REG (0x1C, read only)
//      [31:0] : i_bram_data_out1[31:0]
//
//  BRAM_DATA_OUT2_REG (0x20, read only)
//      [31:0] : i_bram_data_out2[31:0]
//
//  BRAM_ADDR_REG (0x24, read only)
//      [31:0] : i_bram_addr[31:0]
    

    // Axi Bus Interface for Debugging Using ZynqMP(Cortex A-53) Hard Core
    axilite # 
    (
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) 
    axilite_inst 
    (
        // Standard AXI4-Lite signals
        .S_AXI_ACLK    (s00_axi_aclk   ),
        .S_AXI_ARESETN (s00_axi_aresetn),
        .S_AXI_AWADDR  (s00_axi_awaddr ),
        .S_AXI_AWPROT  (s00_axi_awprot ),
        .S_AXI_AWVALID (s00_axi_awvalid),
        .S_AXI_AWREADY (s00_axi_awready),
        .S_AXI_WDATA   (s00_axi_wdata  ),
        .S_AXI_WSTRB   (s00_axi_wstrb  ),
        .S_AXI_WVALID  (s00_axi_wvalid ),
        .S_AXI_WREADY  (s00_axi_wready ),
        .S_AXI_BRESP   (s00_axi_bresp  ),
        .S_AXI_BVALID  (s00_axi_bvalid ),
        .S_AXI_BREADY  (s00_axi_bready ),
        .S_AXI_ARADDR  (s00_axi_araddr ),
        .S_AXI_ARPROT  (s00_axi_arprot ),
        .S_AXI_ARVALID (s00_axi_arvalid),
        .S_AXI_ARREADY (s00_axi_arready),
        .S_AXI_RDATA   (s00_axi_rdata  ),
        .S_AXI_RRESP   (s00_axi_rresp  ),
        .S_AXI_RVALID  (s00_axi_rvalid ),
        .S_AXI_RREADY  (s00_axi_rready ),

        // SYSTEM_CONTROL_REG (0x00)
        .o_soft_reset          (w_soft_reset        ),

        // SPI_STATUS_REG (0x04)
        .i_store_word_complete (r_store_word_complete),
        .i_store_vals_complete (w_store_vals_complete),
        .i_load_vals_complete  (w_load_vals_complete ),
        .i_byte_counter        (r_byte_counter       ),
        .i_store_addr_counter  (r_store_addr_counter ),
        .i_load_addr_counter   (r_load_addr_counter  ),
        .i_state               (r_state              ),

        // SPI_DATA_REG (0x08)
        .i_rx_valid            (w_rx_valid          ),
        .i_tx_valid            (r_tx_valid          ),
        .i_rx_data             (w_rx_data           ),
        .i_tx_data             (r_tx_data           ),

        // DATA_BUFFER_REG (0x0C)
        .i_data_buffer         (r_data_buffer       ),

        // HLS_STATUS_REG (0x10)
        .i_ap_done_latch       (r_ap_done_latch     ),
        .i_select              (r_select            ),
        .i_ap_start            (ap_start            ),
        .i_ap_done             (ap_done             ),
        .i_ap_idle             (ap_idle             ),
        .i_ap_ready            (ap_ready            ),

        // RESULT1_REG (0x14)
        .i_result1             (r_result1           ),

        // RESULT2_REG (0x18)
        .i_result2             (r_result2           ),

        // BRAM_DATA_OUT1_REG (0x1C)
        .i_bram_data_out1      (w_bram_data_out1    ),

        // BRAM_DATA_OUT2_REG (0x20)
        .i_bram_data_out2      (w_bram_data_out2    ),

        // BRAM_ADDR_REG (0x24)
        .i_bram_addr           (w_bram_addr         )
    );

endmodule
