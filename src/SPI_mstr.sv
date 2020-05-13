module SPI_mstr(clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, cmd, done, rd_data);
	input[15:0] cmd;
	output[15:0] rd_data;
	input clk, rst_n, MISO, wrt;
	output SCLK, MOSI;
	output reg SS_n, done;
	reg shift, init, load_SCLK, sample, MISO_smpl, setDone;
	reg[3:0] bit_count;
	reg[5:0] sclk_div;
	reg[15:0] shift_reg;
	wire count, done15, posSCLK, negSCLK;
	typedef enum reg[2:0]{IDLE, FRONT_PORCH, SHIFT, SAMPLE, BACK_PORCH} stateType;
	stateType state, nextState;
	
	//counts15 shifts of the shift register
	always_ff @(posedge clk)begin
		if(init)
			bit_count <= 4'b0000;
		else if(shift)
			bit_count <= bit_count + 1;
	end
	assign done15 = &bit_count;
	
	//SCLK is 1/64th the system clock
	always_ff @(posedge clk)begin
		if (load_SCLK)
			sclk_div <= 6'b110000;
		else
			sclk_div <= 1 + sclk_div;
	end
	assign SCLK = sclk_div[5];
	//rising edge coming next
	assign posSCLK = !sclk_div[5] && &sclk_div[4:0];
	//falling edge coming next
	assign negSCLK = &sclk_div;
	
	
	always_ff @(posedge clk)begin
		if(sample)
			MISO_smpl <= MISO;	
	end
	always_ff @(posedge clk)begin
		if(init)
			shift_reg <= cmd;
		else if(shift)
			shift_reg <= {shift_reg[14:0], MISO_smpl};
	end
	assign MOSI = shift_reg[15];
	assign rd_data = shift_reg;
	
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nextState;
	end
	
	//state machine waits for write signal, samples, then shifts and samples 
	//for 15 iterations of SCLCK before shifting once more and asserting done
	always_comb begin
		nextState = IDLE;
		sample = 1'b0;
		shift = 1'b0;
		load_SCLK = 1'b0;
		init = 1'b0;
		setDone = 1'b0;
		
		case (state)
			IDLE: begin 
					load_SCLK = 1'b1;
					if(wrt) begin
						init = 1'b1;
						nextState = FRONT_PORCH;
					end
				end
			FRONT_PORCH: if(negSCLK)
							nextState = SHIFT;
						 else
							nextState = FRONT_PORCH;
			SHIFT: if(posSCLK) begin
						nextState = SAMPLE;
						sample = 1'b1;
					end else
						nextState = SHIFT;
			SAMPLE: if(done15)begin
						nextState = BACK_PORCH;
					end else if(negSCLK)begin
						nextState = SHIFT;
						shift = 1'b1;
					end else
						nextState = SAMPLE;
			BACK_PORCH: if(negSCLK)begin 
							nextState = IDLE;
							load_SCLK = 1'b1;
							shift = 1'b1;
							setDone = 1'b1;
						end else
							nextState = BACK_PORCH;
			default: begin
						nextState = IDLE;
						load_SCLK = 1'b1;
					end
		endcase					
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			done <= 1'b0;
		else 
			done <= setDone ? 1'b1 : init ? 1'b0 : done;
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			SS_n <= 1'b1;
		else 
			SS_n <= setDone ? 1'b1 : init ? 1'b0 : done;
	end
	
endmodule
