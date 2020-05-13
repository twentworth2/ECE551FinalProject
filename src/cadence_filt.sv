module cadence_filt(input clk, input rst_n, input cadence, output reg cadence_filt);
	parameter FAST_SIM = 0;
	reg ff1, metaStable, oldSignal;
	wire changed_n, stable;
	//clk is 50Mhz so 50,000 cycles/ms. max value for 16 bits is 65535
	reg [15:0] stableCount;
	wire [15:0] newCount;
	
	generate if(FAST_SIM)
		assign stable = &stableCount[8:0];
	else
		assign stable = &stableCount;
	endgenerate
	
	//double flop for meta-stability
	//third flop for change detection
	always @(posedge clk) begin
		ff1 <= cadence;
		metaStable <= ff1;
		oldSignal <= metaStable;
	end
	
	//count will increment unless the cadence has changed 
	assign changed_n = ~(metaStable ^ oldSignal);
	assign newCount = {16{changed_n}} & (stableCount + 1);
	
	always @(posedge clk, negedge rst_n)begin
		if(!rst_n)
			stableCount <= 16'h0000;
		else
			stableCount <= newCount;
	end
	
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			cadence_filt <= 0;
		else if(stable)
			cadence_filt <= oldSignal;
	end
endmodule
