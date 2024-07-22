module tb_spi_system;

    // Parameters
    parameter CLK_PERIOD = 10; // 100MHz clock
    parameter SPI_MODE = 3;
    parameter CLK_HZ = 100_000_000;
    parameter SCK_HZ = 10_000_000;
    parameter BRAM_WIDTH = 32;
    parameter BRAM_DEPTH = 10;

    // Command parameters
    parameter [7:0] CMD_WRITE_VALS    = 8'h01,
                    CMD_READ_VALS     = 8'h02,
                    CMD_CHECK_DONE    = 8'h03,
                    CMD_READ_RESULT1  = 8'h04,
                    CMD_READ_RESULT2  = 8'h05;

    // Signals
    reg        tb_clk;
    reg        tb_rst_n;
    wire       tb_sclk;
    wire       tb_mosi;
    wire       tb_miso;
    reg        tb_ss_n;

    // SPI Master signals
    reg  [7:0] tb_tx_data;
    reg        tb_tx_valid;
    wire       tb_tx_ready;
    wire       tb_rx_valid;
    wire [7:0] tb_rx_data;

    // Test variables
    reg signed [31:0] test_data [0:19];  
    reg [7:0] dummy_byte;
    reg [31:0] dummy_word;
    reg signed [31:0] received_word;
    integer i;
    integer j;

    // Instantiate SPI Master
    spi_master #(
        .SPI_MODE(SPI_MODE),
        .CLK_HZ(CLK_HZ),
        .SCK_HZ(SCK_HZ)
    ) uut_master (
        .i_rst_n(tb_rst_n),
        .i_clk(tb_clk),
        .i_tx_data(tb_tx_data),
        .i_tx_valid(tb_tx_valid),
        .o_tx_ready(tb_tx_ready),
        .o_rx_valid(tb_rx_valid),
        .o_rx_data(tb_rx_data),
        .o_sclk(tb_sclk),
        .i_miso(tb_miso),
        .o_mosi(tb_mosi)
    );

    // Instantiate SPI to HLS
    spi_to_hls #(
        .SPI_MODE(SPI_MODE),
        .BRAM_WIDTH(BRAM_WIDTH),
        .BRAM_DEPTH(BRAM_DEPTH)
    ) uut_spi_to_hls (
        .i_clk(tb_clk),
        .i_rst_n(tb_rst_n),
        .i_sclk(tb_sclk),
        .o_miso(tb_miso),
        .i_mosi(tb_mosi),
        .i_ss_n(tb_ss_n)
    );

    // Clock generation
    always #(CLK_PERIOD/2) tb_clk = ~tb_clk;

    initial begin
        // Initialize signals
        tb_clk = 0;
        tb_ss_n = 1;
        tb_tx_data = 8'h00;
        tb_tx_valid = 0;

        // Reset
        tb_rst_n = 0;
        #(CLK_PERIOD*10);
        tb_rst_n = 1;
        #(CLK_PERIOD*10);

        #(CLK_PERIOD*100);

        // Initialize test data
        test_data[0]  = 32'd1;    test_data[1]  = 32'd10;
        test_data[2]  = 32'd2;    test_data[3]  = 32'd20;
        test_data[4]  = 32'd3;    test_data[5]  = 32'd30;
        test_data[6]  = 32'd4;    test_data[7]  = 32'd40;
        test_data[8]  = 32'd5;    test_data[9]  = 32'd50;
        test_data[10] = 32'd60;   test_data[11] = 32'd6;
        test_data[12] = 32'd70;   test_data[13] = 32'd7;
        test_data[14] = 32'd80;   test_data[15] = 32'd8;
        test_data[16] = 32'd90;   test_data[17] = 32'd9;
        test_data[18] = 32'd100;  test_data[19] = 32'd10;

        // Write data to BRAM
        $display("Writing data to BRAM");
        spi_byte_transaction(CMD_WRITE_VALS, dummy_byte); // Write command
        for (i = 0; i < 20; i = i + 1) begin
            spi_word_transaction(test_data[i], dummy_word); // Write word
            $display("Writing word %d: %d", i, test_data[i]);
        end
        
        #(CLK_PERIOD*100);

        // Check if HLS is done
        $display("Checking if HLS is done");
        spi_byte_transaction(CMD_CHECK_DONE, dummy_byte); // Check done command
        while (dummy_byte[0] == 1'b0) begin
            #(CLK_PERIOD*100);
            spi_byte_transaction(CMD_CHECK_DONE, dummy_byte); // Check done command
        end
        $display("HLS computation completed");

        // Read result1
        $display("Reading Result 1");
        spi_byte_transaction(CMD_READ_RESULT1, dummy_byte); // Read result1 command
        spi_word_transaction(32'h00000000, received_word); // Read word
        $display("Result 1 (cumulative sum of divisions): %d", received_word);

        // Read result2
        $display("Reading Result 2");
        spi_byte_transaction(CMD_READ_RESULT2, dummy_byte); // Read result2 command
        spi_word_transaction(32'h00000000, received_word); // Read word
        $display("Result 2 (cumulative sum of inverse divisions): %d", received_word);

        // Read back original data for verification
        $display("Reading back original data");
        spi_byte_transaction(CMD_READ_VALS, dummy_byte); // Read command
        for (i = 0; i < 20; i = i + 1) begin
            spi_word_transaction(32'h00000000, received_word); // Read word
            if (received_word === test_data[i])
                $display("Word %0d read correctly: %d", i, received_word);
            else
                $display("Word %0d read incorrectly. Expected: %d, Got: %d", i, test_data[i], received_word);
        end

        #(CLK_PERIOD*100);

        for (i = 0; i < 5; i = i + 1) begin

            for (j = 0; j < 20; j = j + 1) begin
                test_data[j] = $urandom_range(-1000, 1000);
            end

            // Write data to BRAM
            $display("Writing data to BRAM");
            spi_byte_transaction(CMD_WRITE_VALS, dummy_byte); // Write command
            for (j = 0; j < 20; j = j + 1) begin
                spi_word_transaction(test_data[j], dummy_word); // Write word
                $display("Writing word %d: %d", j, test_data[j]);
            end
            
            // Check if HLS is done
            $display("Checking if HLS is done");
            spi_byte_transaction(CMD_CHECK_DONE, dummy_byte); // Check done command
            while (dummy_byte[0] == 1'b0) begin
                #(CLK_PERIOD*100);
                spi_byte_transaction(CMD_CHECK_DONE, dummy_byte); // Check done command
            end
            $display("HLS computation completed");

            // Read result1
            $display("Reading Result 1");
            spi_byte_transaction(CMD_READ_RESULT1, dummy_byte); // Read result1 command
            spi_word_transaction(32'h00000000, received_word); // Read word
            $display("Result 1 (cumulative sum of divisions): %d", received_word);

            // Read result2
            $display("Reading Result 2");
            spi_byte_transaction(CMD_READ_RESULT2, dummy_byte); // Read result2 command
            spi_word_transaction(32'h00000000, received_word); // Read word
            $display("Result 2 (cumulative sum of inverse divisions): %d", received_word);

            // Read back original data for verification
            $display("Reading back original data");
            spi_byte_transaction(CMD_READ_VALS, dummy_byte); // Read command
            for (j = 0; j < 20; j = j + 1) begin
                spi_word_transaction(32'h00000000, received_word); // Read word
                if (received_word === test_data[j])
                    $display("Word %0d read correctly: %d", j, received_word);
                else
                    $display("Word %0d read incorrectly. Expected: %d, Got: %d", j, test_data[j], received_word);
            end

            #(CLK_PERIOD*100);
        end

        for (i = 0; i < 5; i = i + 1) begin

            for (j = 0; j < 20; j = j + 1) begin
                test_data[j] = $random;
            end

            // Write data to BRAM
            $display("Writing data to BRAM");
            spi_byte_transaction(CMD_WRITE_VALS, dummy_byte); // Write command
            for (j = 0; j < 20; j = j + 1) begin
                spi_word_transaction(test_data[j], dummy_word); // Write word
                $display("Writing word %d: %d", j, test_data[j]);
            end
            
            // Check if HLS is done
            $display("Checking if HLS is done");
            spi_byte_transaction(CMD_CHECK_DONE, dummy_byte); // Check done command
            while (dummy_byte[0] == 1'b0) begin
                #(CLK_PERIOD*100);
                spi_byte_transaction(CMD_CHECK_DONE, dummy_byte); // Check done command
            end
            $display("HLS computation completed");

            // Read result1
            $display("Reading Result 1");
            spi_byte_transaction(CMD_READ_RESULT1, dummy_byte); // Read result1 command
            spi_word_transaction(32'h00000000, received_word); // Read word
            $display("Result 1 (cumulative sum of divisions): %d", received_word);

            // Read result2
            $display("Reading Result 2");
            spi_byte_transaction(CMD_READ_RESULT2, dummy_byte); // Read result2 command
            spi_word_transaction(32'h00000000, received_word); // Read word
            $display("Result 2 (cumulative sum of inverse divisions): %d", received_word);

            // Read back original data for verification
            $display("Reading back original data");
            spi_byte_transaction(CMD_READ_VALS, dummy_byte); // Read command
            for (j = 0; j < 20; j = j + 1) begin
                spi_word_transaction(32'h00000000, received_word); // Read word
                if (received_word === test_data[j])
                    $display("Word %0d read correctly: %d", j, received_word);
                else
                    $display("Word %0d read incorrectly. Expected: %d, Got: %d", j, test_data[j], received_word);
            end

            #(CLK_PERIOD*100);
        end

        $display("Simulation completed");
        $finish;
    end

    // Task for SPI byte transaction
    task spi_byte_transaction;
        input [7:0] byte_to_send;
        output [7:0] byte_to_receive;
        begin
            tb_ss_n = 0;
            #(CLK_PERIOD*10);
            wait (tb_tx_ready);
            tb_tx_data = byte_to_send;
            tb_tx_valid = 1;
            #(CLK_PERIOD);
            tb_tx_valid = 0;
            wait (tb_rx_valid);
            byte_to_receive = tb_rx_data;
            wait (tb_tx_ready);
            tb_ss_n = 1;
            #(CLK_PERIOD*10);
        end
    endtask

    // Task for SPI word transaction
    task spi_word_transaction;
        input [31:0] word_to_send;
        output [31:0] word_to_receive;
        begin
            spi_byte_transaction(word_to_send[7:0],   word_to_receive[7:0]);
            spi_byte_transaction(word_to_send[15:8],  word_to_receive[15:8]);
            spi_byte_transaction(word_to_send[23:16], word_to_receive[23:16]);   
            spi_byte_transaction(word_to_send[31:24], word_to_receive[31:24]);
        end
    endtask

endmodule
