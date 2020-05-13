module brushless(clk, drv_mag, hallGrn, hallYlw, hallBlu, brake_n, duty, selGrn, selYlw, selBlu);
	localparam GreenBlue = 3'b101;
	localparam Green = 3'b100;
	localparam GreenYellow = 3'b110;
	localparam Yellow = 3'b010;
	localparam YellowBlue = 3'b011;
	localparam Blue = 3'b001;

	localparam HIGH_Z = 2'b00;
	localparam FORWARD = 2'b01;
	localparam REVERSE = 2'b10;
	localparam BRAKE = 2'b11;

	input clk, hallGrn, hallYlw, hallBlu, brake_n;
	input[11:0] drv_mag;
	output[10:0] duty;
	output reg[1:0] selGrn, selYlw, selBlu;

	reg[2:0] rotation_state_in, rotation_state_sync;

	//double flop async inputs for syncronization
	assign rotation_state_in = {hallGrn, hallYlw, hallBlu};
	always @(posedge clk)begin

		rotation_state_sync <= rotation_state_in;
		
	end

	always_comb begin
		//defaulting to avoid latching
		selGrn[1:0] = HIGH_Z;
		selYlw[1:0] = HIGH_Z;
		selBlu[1:0] = HIGH_Z;
		if(!brake_n)begin
			selGrn[1:0] = BRAKE;
			selYlw[1:0] = BRAKE;
			selBlu[1:0] = BRAKE;
		end
		else begin
			case(rotation_state_sync)
				GreenBlue: begin
					selGrn[1:0] = FORWARD;
					selYlw[1:0] = REVERSE;
					selBlu[1:0] = HIGH_Z;
				end
				Green: begin
					selGrn[1:0] = FORWARD;
					selYlw[1:0] = HIGH_Z;
					selBlu[1:0] = REVERSE;
				end
				GreenYellow: begin
					selGrn[1:0] = HIGH_Z;
					selYlw[1:0] = FORWARD;
					selBlu[1:0] = REVERSE;
				end
				Yellow: begin
					selGrn[1:0] = REVERSE;
					selYlw[1:0] = FORWARD;
					selBlu[1:0] = HIGH_Z;
				end
				YellowBlue: begin
					selGrn[1:0] = REVERSE;
					selYlw[1:0] = HIGH_Z;
					selBlu[1:0] = FORWARD;
				end
				Blue: begin
					selGrn[1:0] = HIGH_Z;
					selYlw[1:0] = REVERSE;
					selBlu[1:0] = FORWARD;
				end
				default: begin
					selGrn[1:0] = HIGH_Z;
					selYlw[1:0] = HIGH_Z;
					selBlu[1:0] = HIGH_Z;
				end
			endcase
		end
	end
	assign duty = !brake_n ? 11'h600 : 11'h400 + drv_mag[11:2];
endmodule
