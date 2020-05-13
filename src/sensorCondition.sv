module sensorCondition(clk, rst_n, torque, cadence, curr, incline, setting, batt, error, not_pedaling, TX);
	input wire clk, rst_n, cadence;
	input wire [11:0] torque, batt, curr;
	input wire [12:0] incline;
	input wire [1:0] setting;
	
	output wire not_pedaling, TX;
	output wire[12:0] error;
	
	reg[4:0] cadence_vec, cadence_cnt;
	wire period, cadence_rise, cadence_filt, not_pedaling_fall, include_smpl_curr;
	reg last_cadence_filt, last_not_pedaling;
	
	localparam LOW_BATT_THRES = 12'hA98;
	parameter FAST_SIM = 0;
	
	//signals for exponential average
	wire [11:0] avg_curr, avg_torque;
	reg [13:0] accum_curr;
	reg [15:0] accum_curr_mult;
	reg [16:0] accum_torque;
	wire [21:0] accum_torque_mult;
	 
	//counters for sample rate of averages
	reg [24:0] cadence_per;
	reg [21:0] avg_count;
	
	
	//instantiation of blocks
	wire [11:0] target_curr; //output of desiredDrive
	cadence_filt #(FAST_SIM)cadenceF(.clk(clk), .rst_n(rst_n), .cadence(cadence), .cadence_filt(cadence_filt));
	desiredDrive dDrive(.clk(clk), .avg_torque(avg_torque), .cadence_vec(cadence_vec), .incline(incline), .setting(setting), .target_curr(target_curr));
	telemetry telemetry(.avg_curr(avg_curr), .avg_torque(avg_torque), .clk(clk), .rst_n(rst_n), .batt_v(batt), .TX(TX));
	
	//optional speed up for testing purposes
	generate 
		if(FAST_SIM)begin
			assign period = &cadence_per[15:0];
			assign include_smpl_curr = &avg_count[15:0];
		end else begin
			assign period = &cadence_per;
			assign include_smpl_curr = &avg_count;
		end
	endgenerate
	
	////////////////////////////////////////////////CADENCE////////////////////////////////////////////////////////
	//track previous value of cadence_filt for rising edge detection;
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)
			last_cadence_filt <= 0;
		else
			last_cadence_filt <= cadence_filt;
	end
	
	//counter for cadence period sample
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			cadence_per <= 0;
		else
			cadence_per <= cadence_per + 1;
	end
	
	//rising edge detection
	assign cadence_rise = !last_cadence_filt && cadence_filt;
	
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)
			cadence_cnt <= 0;
		else if(period)
			cadence_cnt <=0;
		//increment cadence, saturate to positive value if about to overflow
		else if(cadence_rise)
			cadence_cnt <= cadence_cnt == 5'h1F ? 5'h1F : cadence_cnt + 1;
	end
	
	//sample the cadence count at the specified period
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)
			cadence_vec <= 0;
		else if (period)
			cadence_vec <= cadence_cnt;
	end
	
	assign not_pedaling = cadence_vec < 5'h02;
	
	//track previous value of not_pedaling for falling edge detection;
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)
			last_not_pedaling <= 0;
		else
			last_not_pedaling <= not_pedaling;
	end
	
	//falling edge detection to re seed torque average
	assign not_pedaling_fall = last_not_pedaling && !not_pedaling;
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////EXPONENTIAL AVERAGING////////////////////////////////////////////////
	
	
	//counter for sampling current in averager
	always @(posedge clk, negedge rst_n)begin
		if (!rst_n)
			avg_count <= 0;
		else
			avg_count <= avg_count + 1;
	end
	
	//accumulate current
	always_ff @(posedge clk, negedge rst_n)begin
		if (!rst_n)
			accum_curr <= 14'b0;
		else if (include_smpl_curr)
			accum_curr <= accum_curr_mult[15:2] + curr;
	end
	//multiply accum by 3
	assign accum_curr_mult = {accum_curr , 2'b00} - accum_curr;
	//shift for average
	assign avg_curr = accum_curr[13:2];

	
	//accumulate torque
	always @(posedge clk, negedge rst_n)begin
		if(!rst_n)begin
			accum_torque <= 17'b0;
		//wind acummulator if starting to pedal again
		end else if(not_pedaling_fall)
			accum_torque <= {1'b0, torque, 4'b0000};
		else if (cadence_rise)
			accum_torque <= accum_torque_mult[21:5] + torque;
	end
	//multiplys accum torque by 32 using shifting and one adder
	assign accum_torque_mult = {accum_torque, 5'h00} - accum_torque;
	
	//shift for average
	assign avg_torque = accum_torque[16:5];
	
	
	
	//Creating error to go to PID
	assign error = (not_pedaling || (batt < LOW_BATT_THRES)) ? 0 : (target_curr - avg_curr);
	
	

endmodule