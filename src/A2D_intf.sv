module A2D_intf(input MISO, input clk, input rst_n, output reg [11:0] batt, output reg[11:0] curr, output reg[11:0] brake, output reg[11:0] torque, output reg a2d_SS_n, output SCLK, output MOSI);

reg [13:0] cntr;
reg [1:0] round_robin_cntr;
reg cnv_init;
reg cnv_cmplt;

wire [2:0] round_robin_out;

reg [15:0] spi_data;
wire [15:0] a2d_cmd;
reg sm_wrt, spi_done;

typedef enum reg[2:0]{START, CNV, CNV2, WAIT, CMPLT, WAIT2} stateType;
stateType state, nxt_state;


//instantiate spi_mstr
SPI_mstr spi (.cmd(a2d_cmd), .wrt(sm_wrt), .rd_data(spi_data), .done(spi_done), .SS_n(a2d_SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .clk(clk), .rst_n(rst_n));

assign round_robin_out = round_robin_cntr == 2'b10 ? 3'b011 :
			 round_robin_cntr == 2'b11 ? 3'b100 : {1'b0,round_robin_cntr[1:0]};

assign a2d_cmd = {2'b00, round_robin_out, 11'h000};

//14 bit counter, will send conversion init signal to start the conversion rounds
always @ (posedge clk or negedge rst_n)begin
	if (!rst_n) 
		cntr <= 0;
	else begin
		cntr <= cntr + 1;
	end
end
assign cnv_init = &cntr;

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= START;
	else
		state <= nxt_state;
end

//changes the conversion channel after each one completes - moved to state machine logic
always_ff @ (posedge clk or negedge rst_n)
begin
	if (!rst_n)
		round_robin_cntr <= 2'b00;
	else if (cnv_cmplt)
		round_robin_cntr <= round_robin_cntr + 1;
end


//four flops that hold data from spi
always_ff @ (posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		brake <= 0;
		batt <= 0;
		curr <= 0;
		torque <= 0;
	end
	
	else if (cnv_cmplt)
	begin
		if (round_robin_out == 0)
			batt <= spi_data;
		else if (round_robin_out == 1)
			curr <= spi_data;
		else if (round_robin_out == 3)
			brake <= spi_data;
		else if (round_robin_out == 4)
			torque <= spi_data;
	end
end


//state machine logic
always_comb
begin
	cnv_cmplt = 0;
	sm_wrt = 0;
	nxt_state = state;

	case(state)

		START: begin
			if (cnv_init == 1) 
			begin
				nxt_state = CNV;
				sm_wrt = 1;
			end
		end

		CNV: begin
			if (spi_done)
				nxt_state = WAIT;
		end
		
		WAIT: begin //this state will make it wait a cycle
			nxt_state = CNV2; 
			sm_wrt = 1;
		end
		CNV2:begin
			if(spi_done)
				nxt_state = CMPLT;
		end

		CMPLT: begin
			if (spi_done)
			begin
				cnv_cmplt = 1;
				nxt_state = WAIT2;
			end
		end
		
		WAIT2: begin // this state makes the system wait for a full cycle to give a chance for a2d_cmd to update to be loaded into the SPI
			nxt_state = START;
		end
		
		default: nxt_state = START;

	endcase
end
endmodule

