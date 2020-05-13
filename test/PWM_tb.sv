module PWM_tb();
	reg clk, rst_n;
	reg[10:0] duty;
	wire PWM_sig;
	
	PWM iDUT(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_sig(PWM_sig));
	
	initial begin
		clk = 1'b0;
		rst_n = 1'b0;
		@(posedge clk);
		
		//tests an empty duty cycle,
		//due to the logic of the PWM we expect the duty to be high for 1 cylce (0 <= 0)
		// and low for the other 2047
		rst_n = 1'b1;
		duty = 11'h000;
		@(posedge clk)
		#1
		if(PWM_sig !== 1'b1)begin
			$display("pwm should have been 1");
			$stop();
		end
		for(int i = 1; i <= 11'h7FF; i++) begin
			@(posedge clk);
			#1
			if(PWM_sig !== 1'b0)begin
				$display("pwm should have been 0");
				$stop();
			end
		end
		//check if cycle repeats
		@(posedge clk)
		#1
		if(PWM_sig !== 1'b1)begin
			$display("pwm should have been 1");
			$stop();
		end
		
		#1
		rst_n = 1'b0;
		@(posedge clk)
		rst_n = 1'b1;
		
		//test of a full duty cycle
		//duty should by high for all clock cycles
		duty = 11'h7FF;
		for(int i = 0; i <= 11'h7FF; i++) begin
			@(posedge clk);
			#1
			if(PWM_sig !== 1'b1) begin
				$display("pwm should have been 1");
				$stop();
			end
		end
		//check if cycle repeats
		@(posedge clk)
		#1
		if(PWM_sig !== 1'b1)begin
			$display("pwm should have been 1");
			$stop();
		end
		
		#1
		rst_n = 1'b0;
		@(posedge clk);
		rst_n = 1'b1;
		
		//tests arbitrary duty ammount
		//expect duty to be high for 0x0FF clocks, low otherwise
		duty = 11'h0FF;
		for(int i = 0; i <= 11'h0FF; i++) begin
			@(posedge clk);
			#1
			if(PWM_sig !== 1'b1) begin
				$display("pwm should have been 1");
				$stop();
			end
		end
		
		for(int i = 11'h100; i <= 11'h7FF; i++) begin
			@(posedge clk);
			#1
			if(PWM_sig !== 1'b0) begin
				$display("pwm should have been 0");
				$stop();
			end
		end
		//check if cycle repeats
		@(posedge clk)
		#1
		if(PWM_sig !== 1'b1)begin
			$display("pwm should have been 1");
			$stop();
		end
		
		$display("Passed all tests");
		$stop();
	end
	
	always begin
		#5 
		clk = ~clk;
	end
endmodule
