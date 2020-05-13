module desiredDrive(input clk, input[11:0] avg_torque, input[4:0]cadence_vec, input[12:0] incline, input[1:0] setting, output reg[11:0] target_curr);
	localparam TORQUE_MIN = 12'h380;
	wire[9:0] incline_sat;
	wire[10:0] incline_factor;
	
	wire[8:0] incline_lim;
	reg[8:0] incline_lim_ff1;
	
	wire notPedaling;
	
	wire[5:0] cadence_factor;
	reg[5:0] cadence_factor_ff1;
	
	wire[12:0] torque_off;
	
	wire[11:0] torque_pos;
	reg[11:0] torque_pos_ff1;
	
	wire[28:0] assist_prod;
	reg[28:0] assist_prod_ff1;
	
	wire [11:0] target_curr_sat;
	reg [11:0] target_curr_ff;
	
	reg[1:0] setting_ff1, setting_ff2;
	
	wire[26:0] assist_prod_operand1;
	wire[14:0] assist_prod_operand2;
	reg [26:0] assist_prod_operand1_ff;
	reg[14:0] assist_prod_operand2_ff;
	
	
	incline_sat saturateIncline(.incline(incline), .incline_sat(incline_sat));
	
	
	assign incline_factor = {incline_sat[9], incline_sat} + 9'b100000000;
	assign incline_lim = 	incline_factor[10] 		? 	9'h000 			: 		//saturate to 0 if negative
							incline_factor[9] 		? 	9'h1FF 			:		//greater than 511 => saturate to 511
													incline_factor[8:0]	;
														
	assign notPedaling = !(|cadence_vec[4:1]);
	assign cadence_factor = notPedaling ? 6'b000000 : cadence_vec + 6'b100000;
	
	assign torque_off = avg_torque - TORQUE_MIN;
	assign torque_pos = torque_off[12] ? 12'h000 : torque_off[11:0];
	
	assign assist_prod_operand2 = cadence_factor_ff1 * incline_lim_ff1;
	assign assist_prod_operand1 = torque_pos_ff1 * assist_prod_operand2_ff;
	assign assist_prod = assist_prod_operand1_ff * setting_ff1;

	assign target_curr_sat = |assist_prod_ff1[28:26] ? 12'hFFF : assist_prod_ff1[25:14];
	
	//pipelining flops
	always_ff @(posedge clk) begin
		target_curr_ff <= target_curr_sat;
		target_curr <= target_curr_ff;
		
		assist_prod_ff1 <= assist_prod;
		
		torque_pos_ff1 <= torque_pos;
		
		incline_lim_ff1 <= incline_lim;
		
		cadence_factor_ff1 <= cadence_factor;
		
		setting_ff1 <= setting;
		
		assist_prod_operand1_ff <= assist_prod_operand1;
		assist_prod_operand2_ff <= assist_prod_operand2;
	end
	
	
endmodule
