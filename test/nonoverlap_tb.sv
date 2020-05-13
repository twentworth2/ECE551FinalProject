module nonoverlap_tb();
	reg high, clk, rst_n;
	wire highOut, lowOut;
	
	nonoverlap iDUT (.clk(clk), .rst_n(rst_n), .highIn(high), .lowIn(!high), .highOut(highOut), .lowOut(lowOut));
	
	initial begin
		clk = 1'b0;
		high = 1'b1;
		rst_n = 1'b0;
		@(posedge clk);
		rst_n = 1'b1;
		high = 1'b0;
		
		//test that on an input change both outputs are low
		@(posedge clk);
		if(highOut !== 1'b0 || lowOut !== 1'b0)begin
			$display("failed: outputs should have been low");
			$stop();
		end
		//test that the outputs are next held low for 32 clock cycles
		for(int i = 0; i < 32; i++)begin
			@(posedge clk);
			if(highOut !== 1'b0 || lowOut !== 1'b0)begin
				$display("failed: outputs should have been low");
				$stop();
			end
		end
		//finally test that after the 32 clock cycles, output takes input value.
		@(posedge clk);
		if(highOut !== 1'b0 || lowOut !== 1'b1)begin
			$display("failed: outputs should have been taken input values");
			$stop();
		end
		
		// repeat above tests for a low to high input change
		@(posedge clk);
		high = 1'b1;
		
		@(posedge clk);
		#1
		if(highOut !== 1'b0 || lowOut !== 1'b0)begin
			$display("failed: outputs should have been low");
			$stop();
		end
		for(int i = 0; i < 32; i++)begin
			@(posedge clk);
			if(highOut !== 1'b0 || lowOut !== 1'b0)begin
				$display("failed: outputs should have been low");
				$stop();
			end
		end
		@(posedge clk);
		if(highOut !== 1'b1 || lowOut !== 1'b0)begin
			$display("failed: outputs should have been taken input values");
			$stop();
		end
		
		$display("All tests passed");
		$stop();
		
	end
	
	always
		#20 clk = !clk;

endmodule
