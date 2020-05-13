module telemetry(batt_v, avg_curr, avg_torque, clk, rst_n, TX);
	typedef enum reg[3:0] {IDLE, D1, D2, P1, P2, P3, P4, P5, P6} states;
	states state, nextState;
	input[11:0] batt_v, avg_curr, avg_torque;
	input clk, rst_n;
	output TX;
	
	reg[7:0] tx_data;
	reg trmt;
	wire tx_done;
	
	reg[19:0] count;
	wire active;
	
	UART_tx UART(.clk(clk), .rst_n(rst_n), .tx_data(tx_data), .trmt(trmt), .tx_done(tx_done), .TX(TX));
	
	//cout to send payload 47.68 times per second
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)
			count <= 20'h0;
		else
			count <= count + 1'b1;
	end
	assign active = &count;
	
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nextState;
	end
	
	//state machine rotates through delimeter and payload bytes as they are transmitted
	always_comb begin
		nextState = IDLE;
		tx_data = 8'h0;
		trmt = 1'b0;
		
		case(state)
			IDLE: if (active) begin
					nextState = D1;
					tx_data = 8'hAA;
					trmt = 1'b1;
				end
			D1: if(tx_done) begin
					nextState = D2;
					tx_data = 8'h55;
					trmt = 1'b1;
				end
				else begin
					nextState = D1;
					tx_data = 8'hAA;
				end
			D2: if(tx_done) begin
					nextState = P1;
					tx_data = {4'h0, batt_v[11:8]};
					trmt = 1'b1;
				end
				else begin
					nextState = D2;
					tx_data = 8'h55;
				end
			P1: if(tx_done) begin
					nextState = P2;
					tx_data = batt_v[7:0];
					trmt = 1'b1;
				end
				else begin
					nextState = P1;
					tx_data = {4'h0, batt_v[11:8]};
				end
			P2: if(tx_done) begin
					nextState = P3;
					tx_data = {4'h0,avg_curr[11:8]};
					trmt = 1'b1;
				end
				else begin
					nextState = P2;
					tx_data = batt_v[7:0];
				end
			P3: if(tx_done) begin
					nextState = P4;
					tx_data = avg_curr[7:0];
					trmt = 1'b1;
				end
				else begin
					nextState = P3;
					tx_data = {4'h0,avg_curr[11:8]};
				end
			P4: if(tx_done) begin
				nextState = P5;
				tx_data = {4'h0,avg_torque[11:8]};
				trmt = 1'b1;
				end
				else begin
					nextState = P4;
					tx_data = avg_curr[7:0];
				end
			P5: if(tx_done) begin
				nextState = P6;
				tx_data = avg_torque[7:0];
				trmt = 1'b1;
				end
				else begin
					nextState = P5;
					tx_data = {4'h0,avg_torque[11:8]};
				end
			P6: if(!tx_done) begin
					nextState = P6;
					tx_data = avg_torque[7:0];
				end
			default: 
				nextState = IDLE;
		endcase
	end
endmodule
