module PB_rise(PB, clk, rst_n, rise);
	input PB, clk, rst_n;
	reg PBFF1, PBStable, PBOld;
	output rise;
	
	always @(posedge clk, negedge rst_n)begin
		if (!rst_n) begin
			PBFF1 <= 1'b1;
			PBStable <= 1'b1;
			PBOld <= 1'b1;
		end
		else begin
			PBFF1 <= PB;
			PBStable <= PBFF1;
			PBOld <= PBStable;
		end
	end
	assign rise = ~PBOld & PBStable;
endmodule
