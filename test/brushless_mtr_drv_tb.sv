module brushless_mtr_drv_tb();

	localparam GreenBlue = 3'b101;
	localparam Green = 3'b100;
	localparam GreenYellow = 3'b110;
	localparam Yellow = 3'b010;
	localparam YellowBlue = 3'b011;
	localparam Blue = 3'b001;
	
	localparam OFF = 2'b00;

	reg clk, rst_n, brake_n;
	wire hallGrn, hallYlw, hallBlu;
	reg[2:0] hallSelect;
	reg[11:0] drv_mag;
	wire[10:0] duty;
	wire[1:0] selGrn, selYlw, selBlu;
	wire highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu;
	wire PWM_sig;
	
	wire[1:0] forward, reverse, brake, green, yellow, blue;

	
	brushless iDutBrush(.clk(clk), .drv_mag(drv_mag), .hallGrn(hallGrn), .hallYlw(hallYlw), .hallBlu(hallBlu), .brake_n(brake_n), .duty(duty), .selGrn(selGrn), .selYlw(selYlw), .selBlu(selBlu));
	mtr_drv iDutDrv(.selGrn(selGrn), .selYlw(selYlw), .selBlu(selBlu), .clk(clk), .rst_n(rst_n), .duty(duty), .highGrn(highGrn), .lowGrn(lowGrn), .highYlw(highYlw), .lowYlw(lowYlw), .highBlu(highBlu), .lowBlu(lowBlu));
	PWM11 pwm(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_sig(PWM_sig));

	assign {hallGrn, hallYlw, hallBlu} = hallSelect;
	
	assign forward = {PWM_sig, ~PWM_sig};
	assign reverse = {~PWM_sig, PWM_sig};
	assign brake = {1'b0, ~PWM_sig};
	
	assign green = {highGrn, lowGrn};
	assign yellow = {highYlw, lowYlw};
	assign blue = {highBlu, lowBlu};

	initial begin
		drv_mag = 12'h0FF;
		hallSelect = 3'b000;
		
		@(posedge clk)
		rst_n = 1'b1;
		brake_n = 1'b1;
		
		//test that an invalid hall input (000) turns off all signals;
		assert( green == OFF && yellow == OFF && blue == OFF)
		else begin
			$error("ERR: All signals should have been off");
			$stop();
		end
		
		//next tests assert that the correct output is generated for the six valid hall inputs
		//as defined by the local params above
		hallSelect = GreenBlue;
		//waits for the nonoverlap block to read a change, wait 32 cycles, and update output value.
		repeat(36) @(posedge clk);
		
		assert( green == forward && yellow == reverse && blue == OFF)
		else begin
			$error("ERR: signals should have been:\ngreen: forward\nyellow: reverse\nblue: OFF");
			$stop();
		end
		
		hallSelect = Green;
		repeat(36) @(posedge clk);
		
		assert( green == forward && yellow == OFF && blue == reverse)
		else begin
			$error("ERR: signals should have been:\ngreen: forward\nyellow: OFF\nblue: reverse");
			$stop();
		end
		
		hallSelect = GreenYellow;
		repeat(36) @(posedge clk);
		
		assert( green == OFF && yellow == forward && blue == reverse)
		else begin
			$error("ERR: signals should have been:\ngreen: OFF\nyellow: forward\nblue: reverse");
			$stop();
		end
		
		hallSelect = Yellow;
		repeat(36) @(posedge clk);
		
		assert( green == reverse && yellow == forward && blue == OFF)
		else begin
			$error("ERR: signals should have been:\ngreen: reverse\nyellow: forward\nblue: OFF");
			$stop();
		end
		
		hallSelect = YellowBlue;
		repeat(36) @(posedge clk);
		
		assert( green == reverse && yellow == OFF && blue == forward)
		else begin
			$error("ERR: signals should have been:\ngreen: reverse\nyellow: OFF\nblue: forward");
			$stop();
		end
		
		hallSelect = Blue;
		repeat(36) @(posedge clk);
		
		assert( green == OFF && yellow == reverse && blue == forward)
		else begin
			$error("ERR: signals should have been:\ngreen: OFF\nyellow: reverse\nblue: forward");
			$stop();
		end
		
		//tests that the other invalid hall input, 111, also turns all signals off
		hallSelect = 3'b111;
		repeat(36) @(posedge clk);
		
		assert( green == OFF && yellow == OFF && blue == OFF)
		else begin
			$error("ERR: All signals should have been off");
			$stop();
		end
		
		//tests that the brake signal causes all signals to break
		brake_n = 1'b0;
		assert( green == brake && yellow == brake && blue == brake)
		else begin
			$error("ERR: All signals should have been braking");
			$stop();
		end
		
		$display("All tests passed");
		$stop();
	end
	
	initial begin
		clk = 1'b0;
		rst_n = 1'b0;
		brake_n = 1'b0;
	end
	always
		#5 clk = ~clk;
endmodule
