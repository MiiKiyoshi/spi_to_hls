module spi_master #
(
    parameter SPI_MODE = 0,
    parameter CLK_HZ   = 100_000_000,  
    parameter SCK_HZ   = 1_000_000     
) (
    input            i_rst_n    ,  
    input            i_clk      ,  

    input      [7:0] i_tx_data  ,  
    input            i_tx_valid ,  
    output reg       o_tx_ready ,  

    output reg       o_rx_valid ,  
    output reg [7:0] o_rx_data  ,  

    output reg       o_sclk     ,
    input            i_miso ,
    output reg       o_mosi 
);

    // Calculate CLKS_PER_HALF_BIT
    localparam DIVISOR = CLK_HZ / SCK_HZ;
    localparam CLKS_PER_HALF_BIT = DIVISOR / 2;

    wire w_cpol;     // Clock polarity
    wire w_cpha;     // Clock phase

    reg [$clog2(CLKS_PER_HALF_BIT*2)-1:0] r_sclk_count;
    reg r_sclk;
    reg [4:0] r_sclk_edges;
    reg r_leading_edge;
    reg r_trailing_edge;
    reg       r_tx_valid;
    reg [7:0] r_tx_byte;

    reg [2:0] r_rx_bit_count;
    reg [2:0] r_tx_bit_count;

    assign w_cpol = (SPI_MODE == 2) | (SPI_MODE == 3);
    assign w_cpha = (SPI_MODE == 1) | (SPI_MODE == 3);

    // Generate SPI Clock
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_tx_ready      <= 1'b0;
            r_sclk_edges <= 0;
            r_leading_edge  <= 1'b0;
            r_trailing_edge <= 1'b0;
            r_sclk       <= w_cpol;
            r_sclk_count <= 0;
        end else begin
            r_leading_edge  <= 1'b0;
            r_trailing_edge <= 1'b0;
            if (i_tx_valid) begin
                o_tx_ready      <= 1'b0;
                r_sclk_edges <= 16;
            end else if (r_sclk_edges > 0) begin
                o_tx_ready <= 1'b0;
                if (r_sclk_count == CLKS_PER_HALF_BIT*2-1) begin
                    r_sclk_edges <= r_sclk_edges - 1'b1;
                    r_trailing_edge <= 1'b1;
                    r_sclk_count <= 0;
                    r_sclk       <= ~r_sclk;
                end else if (r_sclk_count == CLKS_PER_HALF_BIT-1) begin
                    r_sclk_edges <= r_sclk_edges - 1'b1;
                    r_leading_edge  <= 1'b1;
                    r_sclk_count <= r_sclk_count + 1'b1;
                    r_sclk       <= ~r_sclk;
                end else begin
                    r_sclk_count <= r_sclk_count + 1'b1;
                end
            end else begin
                o_tx_ready <= 1'b1;
            end
        end
    end

    // Register TX Byte
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_tx_byte <= 8'h00;
            r_tx_valid   <= 1'b0;
        end else begin
            r_tx_valid <= i_tx_valid;
            if (i_tx_valid) begin
                r_tx_byte <= i_tx_data;
            end
        end
    end

    // Generate MOSI data
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_mosi     <= 1'b0;
            r_tx_bit_count <= 3'b111;
        end else begin
            if (o_tx_ready) begin
                r_tx_bit_count <= 3'b111;
            end else if (r_tx_valid & ~w_cpha) begin
                o_mosi     <= r_tx_byte[3'b111];
                r_tx_bit_count <= 3'b110;
            end else if ((r_leading_edge & w_cpha) | (r_trailing_edge & ~w_cpha)) begin
                r_tx_bit_count <= r_tx_bit_count - 1'b1;
                o_mosi     <= r_tx_byte[r_tx_bit_count];
            end
        end
    end

    // Read MISO data
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_rx_data      <= 8'h00;
            o_rx_valid        <= 1'b0;
            r_rx_bit_count <= 3'b111;
        end else begin
            o_rx_valid   <= 1'b0;
            if (o_tx_ready) begin
                r_rx_bit_count <= 3'b111;
            end else if ((r_leading_edge & ~w_cpha) | (r_trailing_edge & w_cpha)) begin
                o_rx_data[r_rx_bit_count] <= i_miso;
                r_rx_bit_count            <= r_rx_bit_count - 1'b1;
                if (r_rx_bit_count == 3'b000) begin
                    o_rx_valid   <= 1'b1;
                end
            end
        end
    end
    
    // Output SPI Clock
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_sclk  <= w_cpol;
        end else begin
            o_sclk <= r_sclk;
        end
    end

endmodule
