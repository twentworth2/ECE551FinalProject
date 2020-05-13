module SPI_mstr_tb();
	reg clk, rst_n, wrt;
	wire SS_n, SCLK, MISO, MOSI, done;
	reg[15:0] cmd;
	wire[15:0] rd_data;

	SPI_mstr iDUT(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .wrt(wrt), .cmd(cmd), .done(done), .rd_data(rd_data));
	ADC128S slave(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));
	
	initial begin
		clk = 1'b0;
		//bits [13:11] tell which channel to request
		//request channel 1
		cmd = {2'b0, 3'b001, 11'h0};
		rst_n = 1'b0;
		
		@(posedge clk)
		rst_n = 1'b1;
		wrt = 1'b1;
		@(posedge clk)
		wrt = 1'b0;
		
		//expect defalut output as slave hasn't had time to send back meaningful output yet
		@(posedge done)
		if(rd_data !== 12'hC00)begin
			$display("read data should have been 0xC00");
			$stop;
		end
		for(int i = 0; i<100; i++)begin
			@(posedge clk);
		end
		
		@(posedge clk)
		wrt = 1'b1;
		@(posedge clk)
		wrt = 1'b0;
		
		//expect slave to return channel 1
		@(posedge done)
		if(rd_data !== 12'hC01)begin
			$display("read data should have been 0xC01");
			$stop;
		end
		for(int i = 0; i<100; i++)begin
			@(posedge clk);
		end
		
		@(posedge clk)
		//change request to chennel 4
		cmd = {2'b0, 3'b100, 11'h0};
		wrt = 1'b1;
		@(posedge clk)
		wrt = 1'b0;
		
		//slave decrements value by 0x01 every two requests
		//expect output to be {0xC0 - 0x01 = 0xBF, previous requested channel = 0x1} 
		@(posedge done)
		if(rd_data !== 12'hBF1)begin
			$display("read data should have been 0xBF1");
			$stop;
		end
		
		for(int i = 0; i<100; i++)begin
			@(posedge clk);
		end
		
		@(posedge clk)
		wrt = 1'b1;
		@(posedge clk)
		wrt = 1'b0;
		
		//output should now return channel 4 per the previous request 
		@(posedge done)
		if(rd_data !== 12'hBF4)begin
			$display("read data should have been 0xBF4");
			$stop;
		end
		
		for(int i = 0; i<100; i++)begin
			@(posedge clk);
		end
		
		$display("All Tests Passed");
		$stop();
	end
	
	always
		#5 clk = !clk;
endmodule
