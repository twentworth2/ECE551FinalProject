module desiredDrive_tb();
	reg[11:0] avg_torque;
	reg[4:0] cadence_vec;
	reg[12:0] incline;
	reg[1:0] setting;
	wire[11:0] target_curr;
	desiredDrive iDUT(.avg_torque(avg_torque), .cadence_vec(cadence_vec), .incline(incline), .setting(setting), .target_curr(target_curr));
	
	initial begin
		avg_torque = 12'h800;
		cadence_vec = 5'h10;
		incline = 13'h0150;
		setting = 2'b10;
		#5
		if(target_curr !== 12'hD79)begin
			$display("Current should have been D79");
			$stop();
		end
		
		
		incline = 13'h1F22;
		setting = 2'b11;
		#5
		if(target_curr !== 12'h158)begin
			$display("Current should have been 158");
			$stop();
		end
		
		avg_torque = 12'h360;
		incline = 13'h0C0;
		#5
		if(target_curr !== 12'h000)begin
			$display("Current should have been 0");
			$stop();
		end
		
		avg_torque = 12'h800;
		cadence_vec = 5'h18;
		incline = 13'h1EF0;
		#5
		if(target_curr !== 12'h000)begin
			$display("Current should have been 0");
			$stop();
		end
		
		avg_torque = 12'h7E0;
		incline = 13'h0000;
		#5
		if(target_curr !== 12'hB7C)begin
			$display("Current should have been B7C");
			$stop();
		end
		
		incline = 13'h0080;
		#5
		if(target_curr !== 12'hFFF)begin
			$display("Current should have been FFF");
			$stop();
		end
	$display("Tests passed");
	$stop();
	end
endmodule
