module nonoverlap(clk, rst_n, highIn, lowIn, highOut, lowOut);
	input clk, rst_n, highIn, lowIn;
	output reg highOut, lowOut;
	reg highOutFF, lowOutFF;
	reg oldHI, oldLI, resetCount_n;
	reg[4:0] count;
	wire changed, doneCounting;
	
	typedef enum reg{IDLE, COUNT}states; 
	states state, nextState;
	
	
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nextState;
	end
	
	//uses flip flops to detect if one of the inputs has
	//changed in the last clock cycle
	always_ff @(posedge clk)begin
		if(!rst_n) begin
			oldHI <= 1'b0;
			oldLI <= 1'b0;
		end
		else begin
			oldHI <= highIn;
			oldLI <= lowIn;
		end
	end
	assign changed = (oldHI ^ highIn) || (oldLI ^ lowIn);
	
	//count for 32 clock cycles
	always @(posedge clk, negedge resetCount_n) begin
		if(!resetCount_n)
			count <= 5'b00000;
		else
			count <= count + 1'b1;
	end
	assign doneCounting = &count;
	
	//SM should detect a change in input and then force outputs low
	//for 32 clock cylces
	always_comb begin
		lowOutFF = lowIn;
		highOutFF = highIn;
		resetCount_n = 1'b1;
		nextState = IDLE;
		case(state)
			IDLE : if(changed) begin
				highOutFF = 1'b0;
				lowOutFF = 1'b0;
				resetCount_n = 1'b0;
				nextState = COUNT;
				end
			COUNT : if(!doneCounting) begin
				nextState = COUNT; 
				highOutFF = 1'b0;
				lowOutFF = 1'b0;
				end 
		endcase		
	end
	
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)begin
			highOut <= 1'b0;
			lowOut <= 1'b0;
		end
		else begin
			highOut <= highOutFF;
			lowOut <= lowOutFF;
		end
	end
		
endmodule
