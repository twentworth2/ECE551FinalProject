module rst_synch(RST_n, rst_n, clk);
	input RST_n, clk;
	output reg rst_n;
	reg ff1;
	
	always @(negedge clk, negedge RST_n)begin
		if(!RST_n) begin
			ff1 <= 1'b0;
			rst_n <= 1'b0;
		end
		else begin
			ff1 <= 1'b1;
			rst_n <= ff1;
		end
	end
endmodule
