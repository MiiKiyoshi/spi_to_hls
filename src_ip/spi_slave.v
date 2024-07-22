module spi_slave #(
    parameter SPI_MODE = 0
) (
    input            i_rst_n    , 
    input            i_clk      , 

    output reg       o_rx_valid , 
    output reg [7:0] o_rx_data  , 

    input            i_tx_valid , 
    input      [7:0] i_tx_data  , 

    input            i_sclk ,
    output           o_miso ,
    input            i_mosi ,
    input            i_ss_n   
);

    wire w_cpol;  // Clock polarity
    wire w_cpha;  // Clock phase
    wire w_sclk;  // Inverted/non-inverted depending on settings
    wire w_miso_mux;
    
    reg [2:0] r_rx_bit_count;
    reg [2:0] r_tx_bit_count;
    reg [7:0] r_temp_rx_data;
    reg [7:0] r_rx_data;
    reg r_rx_done, r2_rx_done, r3_rx_done;
    reg [7:0] r_tx_data;
    reg r_miso_bit, r_preload_miso;

    assign w_cpol = (SPI_MODE == 2) | (SPI_MODE == 3);
    assign w_cpha = (SPI_MODE == 1) | (SPI_MODE == 3);
    assign w_sclk = w_cpha ? ~i_sclk : i_sclk;

    // Receive SPI Byte
    always @(posedge w_sclk or posedge i_ss_n) begin
        if (i_ss_n) begin
            r_rx_bit_count <= 0;
            r_rx_done      <= 1'b0;
        end else begin
            r_rx_bit_count <= r_rx_bit_count + 1;
            r_temp_rx_data <= {r_temp_rx_data[6:0], i_mosi};
            if (r_rx_bit_count == 3'b111) begin
                r_rx_done <= 1'b1;
                r_rx_data <= {r_temp_rx_data[6:0], i_mosi};
            end else if (r_rx_bit_count == 3'b010) begin
                r_rx_done <= 1'b0;        
            end
        end
    end

    // Cross clock domains
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r2_rx_done <= 1'b0;
            r3_rx_done <= 1'b0;
            o_rx_valid    <= 1'b0;
            o_rx_data  <= 8'h00;
        end else begin
            r2_rx_done <= r_rx_done;
            r3_rx_done <= r2_rx_done;
            if (r3_rx_done == 1'b0 && r2_rx_done == 1'b1) begin
                o_rx_valid   <= 1'b1;
                o_rx_data <= r_rx_data;
            end else begin
                o_rx_valid <= 1'b0;
            end
        end
    end

    // Control preload signal
    always @(posedge w_sclk or posedge i_ss_n) begin
        if (i_ss_n) begin
            r_preload_miso <= 1'b1;
        end else begin
            r_preload_miso <= 1'b0;
        end
    end

    // Transmit SPI Byte
    always @(posedge w_sclk or posedge i_ss_n) begin
        if (i_ss_n) begin
            r_tx_bit_count <= 3'b111;
            r_miso_bit <= r_tx_data[3'b111];
        end else begin
            r_tx_bit_count <= r_tx_bit_count - 1;
            r_miso_bit <= r_tx_data[r_tx_bit_count];
        end
    end

    // Register TX Byte
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_tx_data <= 8'h00;
        end else begin
            if (i_tx_valid) begin
                r_tx_data <= i_tx_data; 
            end
        end
    end

    assign w_miso_mux = r_preload_miso ? r_tx_data[3'b111] : r_miso_bit;
    assign o_miso = i_ss_n ? 1'bZ : w_miso_mux;

endmodule
