module PB_intf(clk, rst_n, tggleMd, setting);
	input wire clk, rst_n, tggleMd;
	output reg [1:0] setting;
	
	wire rise;
	
	//edge detector
	PB_rise PB_rise(.PB(tggleMd), .clk(clk), .rst_n(rst_n), .rise(rise));
	
	always_ff @(posedge clk, negedge rst_n) begin
		//default medium assist
		if(!rst_n)
			setting <= 2'b10;
		//increment setting, will roll over 
		else if (rise)
			setting <= setting + 1;
	end
	
endmodule