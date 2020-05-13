module PWM11(clk, rst_n, duty, PWM_sig);
	input clk, rst_n;
	input[10:0] duty;
	output reg PWM_sig;
	
	reg[10:0] count;
	
	//period is 2048 clocks
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			count <= 11'h000;
		else
			count <= count + 1'b1;
	end

	//duty cylcle is active is the current count is less than the duty input
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			PWM_sig <= 1'b0;
		else
			PWM_sig <= (count <= duty);
	end

endmodule
