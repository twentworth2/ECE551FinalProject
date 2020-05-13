module inert_intf (input clk, input rst_n, input MISO, input INT, output [12:0] incline, output SS_n, output SCLK, output MOSI, output reg vld_ff);

//16 bit counter
reg [15:0] cntr_16;
wire cntr_ovr;

typedef enum reg[3:0]{INIT, CONFIG_INT, CONFIG_ACCEL, CONFIG_GYRO, CONFIG_ROUNDING, WAIT, READY, READ_ROLLL, READ_ROLLH, READ_YAWL, READ_YAWH, READ_AYL, READ_AYH, READ_AZL, READ_AZH} stateType;
stateType state, next_state;

//holding regs
reg C_R_H, C_R_L, C_Y_H, C_Y_L, C_AY_H, C_AY_L, C_AZ_H, C_AZ_L;
reg [15:0] roll_rt_reg, yaw_rt_reg, AY_reg, AZ_reg;

//INT ff
reg INT_ff2;
reg spi_done_ff;
reg vld;


//wire [12:0] incline_out;
//assign incline[12:0] = incline_out[12:0];

//state machine vars
wire en_int, set_acc, set_gyro, round;
reg sm_wrt, read_inc, read_rst;
reg [15:0] sm_cmd;

//SM peripheral signals

reg wrt;
wire spi_done_pos;

//instantiate spi_mstr
wire [15:0] spi_rd_data;
wire spi_done;
SPI_mstr spi (.cmd(sm_cmd), .wrt(sm_wrt), .rd_data(spi_rd_data), .done(spi_done), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .clk(clk), .rst_n(rst_n));

//instantiate intertial integrator
inertial_integrator inert_integ (.clk(clk), .rst_n(rst_n), .vld(vld), .roll_rt(roll_rt_reg), .yaw_rt(yaw_rt_reg), .AY(AY_reg), .AZ(AZ_reg), .incline(incline));

assign spi_done_pos = spi_done && !spi_done_ff ? 1 : 0; // signal checks for positive edge of spi_done

//state machine transitions
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		state <= INIT;
	else
		state <= next_state;
end

//16 bit counter
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		cntr_16 <= 0;
	
	else
		cntr_16 <= cntr_16 + 1;
end
assign cntr_ovr = &cntr_16;

//INT flip flip to provide metastability to the signal
always_ff @ (posedge clk, negedge rst_n)
begin
	if (!rst_n) begin
		INT_ff2 <= 0;
		spi_done_ff <= 0;
		vld_ff <= 0;
		
	end
	else begin
		INT_ff2 <= INT;
		spi_done_ff <= spi_done;
		vld_ff <= vld;
		
	end
end

//holding registers
always_ff @ (posedge clk, negedge rst_n)
begin

	if (!rst_n)
	begin	
		roll_rt_reg <= 0;
		yaw_rt_reg <= 0;
		AY_reg <= 0;
		AZ_reg <= 0;
	end
	
	else	
	begin 
		if(C_R_H)
			roll_rt_reg[15:8] <= spi_rd_data[7:0];
		else if(C_R_L)
			roll_rt_reg[7:0] <= spi_rd_data[7:0];
		else if(C_Y_H)
			yaw_rt_reg[15:8] <= spi_rd_data[7:0];
		else if(C_Y_L)
			yaw_rt_reg[7:0] <= spi_rd_data[7:0];
		else if(C_AY_H)
			AY_reg[15:8] <= spi_rd_data[7:0];
		else if(C_AY_L)
			AY_reg[7:0] <= spi_rd_data[7:0];
		else if(C_AZ_H)
			AZ_reg[15:8] <= spi_rd_data[7:0];
		else if(C_AZ_L)
			AZ_reg[7:0] <= spi_rd_data[7:0];
		
	end
end


always_comb
begin
	
	//default outputs
	sm_wrt = 0;
	vld = 0;
 	sm_cmd = 16'h0000;
	next_state = state; //default behavior to hold state
	
	read_inc = 0;
	read_rst = 0;
	C_R_H = 0;
	C_R_L = 0;
	C_Y_H = 0;
	C_Y_L = 0;
	C_AY_H = 0;
	C_AY_L = 0;
	C_AZ_H = 0;
	C_AZ_L = 0; 
	
	case (state)
		//when the 16 bit counter overflows the machine will move to config 
		INIT: begin
			if (cntr_ovr)
			begin
				next_state = CONFIG_INT;
				sm_wrt = 1;
			end
		end
		
		CONFIG_INT: begin
			sm_cmd = 16'h0D02;
			if(spi_done_pos)begin
				next_state = CONFIG_ACCEL;
				sm_wrt = 1'b1;
			end
		end
		
		CONFIG_ACCEL: begin
			sm_cmd = 16'h1053;
			if(spi_done_pos)begin
				next_state = CONFIG_GYRO;
				sm_wrt = 1'b1;
			end
		end
		
		CONFIG_GYRO: begin
			sm_cmd = 16'h1150;
			if(spi_done_pos)begin
				next_state = CONFIG_ROUNDING;
				sm_wrt = 1'b1;
			end
		end
		
		CONFIG_ROUNDING: begin
			sm_cmd = 16'h1460;
			if(spi_done_pos)begin
				next_state = READY;
			end
		end
		
		READY: begin
			
			if (INT_ff2)
			begin
				next_state = READ_ROLLL;
				sm_cmd = 16'hA4xx;
				sm_wrt = 1'b1;
			end
		end
		
		READ_ROLLL: begin
			sm_cmd = 16'hA4xx;
			if(spi_done) begin
				C_R_L = 1'b1;
				next_state = READ_ROLLH;
				sm_cmd = 16'hA5xx;
				sm_wrt = 1'b1;
			end
				
		end
		
		READ_ROLLH: begin
			sm_cmd = 16'hA5xx;
			if(spi_done) begin
				C_R_H = 1'b1;
				next_state = READ_YAWL;
				sm_cmd = 16'hA6xx;
				sm_wrt = 1'b1;
			end
				
		end
		
		READ_YAWL: begin
			sm_cmd = 16'hA6xx;
			if(spi_done) begin
				C_Y_L = 1'b1;
				next_state = READ_YAWH;
				sm_cmd = 16'hA7xx;
				sm_wrt = 1'b1;
			end
				
		end
		
		READ_YAWH: begin
			sm_cmd = 16'hA7xx;
			if(spi_done) begin
				C_Y_H = 1'b1;
				next_state = READ_AYL;
				sm_cmd = 16'hAAxx;
				sm_wrt = 1'b1;
			end
				
		end
		
		READ_AYL: begin
			sm_cmd = 16'hAAxx;
			if(spi_done) begin
				C_AY_L = 1'b1;
				next_state = READ_AYH;
				sm_cmd = 16'hABxx;
				sm_wrt = 1'b1;
			end
				
		end
		
		READ_AYH: begin
			sm_cmd = 16'hABxx;
			if(spi_done) begin
				C_AY_H = 1'b1;
				next_state = READ_AZL;
				sm_cmd = 16'hACxx;
				sm_wrt = 1'b1;
			end
				
		end
		
		READ_AZL: begin
			sm_cmd = 16'hACxx;
			if(spi_done) begin
				C_AZ_L = 1'b1;
				next_state = READ_AZH;
				sm_cmd = 16'hADxx;
				sm_wrt = 1'b1;
			end
				
		end
		
		READ_AZH: begin
			sm_cmd = 16'hADxx;
			if(spi_done) begin
				C_AZ_H = 1'b1;
				next_state = READY;
				vld = 1'b1;
			end
				
		end
	endcase
	
end
endmodule

		
			
			
	