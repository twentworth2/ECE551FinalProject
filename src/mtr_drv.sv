module mtr_drv(selGrn, selYlw, selBlu, clk, rst_n, duty, highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu);

	localparam HIGH_Z = 2'b00;
	localparam FORWARD = 2'b01;
	localparam REVERSE = 2'b10;
	localparam BRAKE = 2'b11;
	
	input [1:0] selGrn, selYlw, selBlu;
	input clk, rst_n;
	input[10:0] duty;
	
	output highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu;
	
	reg overlapHighGreen, overlapLowGreen, overlapHighYellow, overlapLowYellow, overlapHighBlue, overlapLowBlue;
	
	nonoverlap green(.clk(clk), .rst_n(rst_n), .highIn(overlapHighGreen), .lowIn(overlapLowGreen), .highOut(highGrn), .lowOut(lowGrn));
	nonoverlap Yellow(.clk(clk), .rst_n(rst_n), .highIn(overlapHighYellow), .lowIn(overlapLowYellow), .highOut(highYlw), .lowOut(lowYlw));
	nonoverlap Blue(.clk(clk), .rst_n(rst_n), .highIn(overlapHighBlue), .lowIn(overlapLowBlue), .highOut(highBlu), .lowOut(lowBlu));
	
	wire PWM_sig;
	
	PWM11 pwm(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_sig(PWM_sig));
	
	always_comb begin
		//all 4 possible cases covered so default not needed
		case (selGrn)
			HIGH_Z: begin
				overlapHighGreen = 1'b0;
				overlapLowGreen = 1'b0;
			end
			FORWARD: begin
				overlapHighGreen = PWM_sig;
				overlapLowGreen = ~PWM_sig;
			end
			REVERSE: begin
				overlapHighGreen = ~PWM_sig;
				overlapLowGreen = PWM_sig;
			end
			BRAKE: begin
				overlapHighGreen = 1'b0;
				overlapLowGreen = PWM_sig;
			end
		endcase
	end
	
	always_comb begin
		//all 4 possible cases covered so default not needed
		case (selYlw)
			HIGH_Z: begin
				overlapHighYellow = 1'b0;
				overlapLowYellow = 1'b0;
			end
			FORWARD: begin
				overlapHighYellow = PWM_sig;
				overlapLowYellow = ~PWM_sig;
			end
			REVERSE: begin
				overlapHighYellow = ~PWM_sig;
				overlapLowYellow = PWM_sig;
			end
			BRAKE: begin
				overlapHighYellow = 1'b0;
				overlapLowYellow = PWM_sig;
			end
		endcase
	end
	
	always_comb begin
		//all 4 possible cases covered so default not needed
		case (selBlu)
			HIGH_Z: begin
				overlapHighBlue = 1'b0;
				overlapLowBlue = 1'b0;
			end
			FORWARD: begin
				overlapHighBlue = PWM_sig;
				overlapLowBlue = ~PWM_sig;
			end
			REVERSE: begin
				overlapHighBlue = ~PWM_sig;
				overlapLowBlue = PWM_sig;
			end
			BRAKE: begin
				overlapHighBlue = 1'b0;
				overlapLowBlue = PWM_sig;
			end
		endcase
	end
	
endmodule
