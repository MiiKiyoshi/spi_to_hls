module spi_to_hls #(
    parameter SPI_MODE   = 3,
    parameter BRAM_WIDTH = 32,
    parameter BRAM_DEPTH = 10  
) (
    input      i_clk   , 
    input      i_rst_n , 
    input      i_sclk  ,
    output     o_miso  ,
    input      i_mosi  ,
    input      i_ss_n    
);

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
        .i_rst_n    (i_rst_n   ),
        .i_clk      (i_clk     ),
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
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
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

    // Byte counter
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
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
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_data_buffer <= 32'd0;
        end else if (w_rx_valid) begin
            if (r_state == S_STORE_VALS) begin
                r_data_buffer <= {w_rx_data, r_data_buffer[31:8]};
            end
        end
    end
    
    // Write enable logic
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_store_word_complete <= 1'b0;
        end else if (w_rx_valid) begin
            r_store_word_complete <= (r_byte_counter == 2'd3);
        end else begin
            r_store_word_complete <= 1'b0;
        end
    end

    // BRAM select logic
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
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
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
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
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
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
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
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
        .clk0  (i_clk           ),
        .addr0 (w_bram_addr     ),
        .ce0   (1'b1            ),
        .we0   (w_bram_we1      ),
        .q0    (w_bram_data_out1),
        .d0    (w_bram_data_in  ),
        .clk1  (i_clk           ),
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
        .clk0  (i_clk           ),
        .addr0 (w_bram_addr     ),
        .ce0   (1'b1            ),
        .we0   (w_bram_we2      ),
        .q0    (w_bram_data_out2),
        .d0    (w_bram_data_in  ),
        .clk1  (i_clk           ),
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

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            ap_start <= 1'b0;
        end else begin
            if (hls_start_trigger) begin
                ap_start <= 1'b1;
            end else if (ap_ready) begin
                ap_start <= 1'b0;
            end
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
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
        .ap_clk             (i_clk            ),
        .ap_rst             (~i_rst_n         ),
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

    // LOAD operation and result management
    reg [31:0] r_result1, r_result2;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
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

endmodule
