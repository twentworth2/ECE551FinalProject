module incline_sat(input[12:0] incline, output[9:0] incline_sat);
	wire containsOnes, allOnes, negative;
	assign containsOnes = |incline[11:9];
	assign allOnes = &incline[11:9];
	assign negative = incline[12];
	
	assign incline_sat = 	(negative  && !allOnes) ? 10'b1000000000 :
							(!negative &&  containsOnes) ? 10'b0111111111 :
							incline[9:0];
	
endmodule
