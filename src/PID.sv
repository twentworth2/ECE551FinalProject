module PID(clk, rst_n, error, not_pedaling, drv_mag);

//module inputs and outputs
input [12:0] error;
input clk, rst_n, not_pedaling;
output reg[11:0] drv_mag;

wire[11:0] drv_mag_internal;
reg [11:0] drv_mag_ff1;


logic [19:0] decimator; //decimators to determine decimator_full
logic decimator_full; //determines every 1/48th clock cycle

//PARAM for testing
parameter FAST_SIM = 0;

//generate logic based on simulation mode
generate if(FAST_SIM)
	assign decimator_full = &decimator[14:0];
else
	assign decimator_full = &decimator;
endgenerate

//sequential logic to determine decimator and decimator_full
always @(posedge clk, negedge rst_n)begin
	if(!rst_n)
		decimator <= 0;
	else 
		decimator <= decimator + 1;
end
 
////////////////////////////////////////////////////////////////
// D TERM
///////////////////////////////////////////////////////////////
//local signals
logic [12:0] D_diff; 
logic [8:0] D_diff_sat;
logic [9:0] D_term;

//instaniate wires for D_term logic
logic [12:0] muxOut1, muxOut2, muxOut3;
logic [12:0] flopOut1, flopOut2, prev_err;

assign muxOut1 = (decimator_full) ? error : flopOut1;
assign muxOut2 = (decimator_full) ? flopOut1 : flopOut2;
assign muxOut3 = (decimator_full) ? flopOut2 : prev_err;

//flopping mux signal
always @(posedge clk, negedge rst_n)begin
	if(!rst_n)begin
		flopOut1 <= 0;
		flopOut2 <= 0;
		prev_err <= 0;
	end else begin
		flopOut1 <= muxOut1;
		flopOut2 <= muxOut2;
		prev_err <= muxOut3;
	end
end

//derivative term
assign D_diff = error - prev_err;

//saturate D_diff to 9 bits
assign D_diff_sat = (D_diff[12] && ~(&D_diff[11:8])) ? 9'h100 :
					(!(D_diff[12]) && (|D_diff[11:8])) ? 9'h0FF :
					D_diff[8:0];
					
//signed multiply
assign D_term = {D_diff_sat, 1'b0};

////////////////////////////////////////////////////////////////
// I TERM
////////////////////////////////////////////////////////////////
//singals local to the I term
logic [17:0] integrator;
logic [17:0] totalNonNegative, totalOverflowChecked, muxAllow, muxSupport, error_sign_extended, newIntegratorTotal;
logic [11:0] ITerm;
logic [11:0] capPID;

//combinational I Term logic
assign error_sign_extended = {{5{error[12]}},error[12:0]};
assign newIntegratorTotal = error_sign_extended + integrator;
assign totalNonNegative = (newIntegratorTotal[17]) ? 18'h00000 : newIntegratorTotal;
assign totalOverflowChecked = (newIntegratorTotal[17] && integrator[16]) ? 18'h1FFFF : totalNonNegative;
assign muxAllow = (decimator_full) ? totalOverflowChecked : integrator;
assign muxSupport = (not_pedaling) ? 18'h00000 : muxAllow;

//sequential flop for integrator output
always @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		integrator <= 18'h00000;
	else 
		integrator <= muxSupport;
end
assign ITerm = integrator[16:5];

////////////////////////////////////////////////////////////////
// PID CONTROLLER
////////////////////////////////////////////////////////////////
logic [13:0] P_term, extendedDTerm, extendedITerm, PID;
assign P_term = {error[12], error};

assign extendedITerm = {2'b00, ITerm};
assign extendedDTerm = {{4{D_term[9]}}, D_term};

assign PID = P_term + extendedITerm + extendedDTerm;
assign capPID = (PID[12]) ? 12'hFFF : PID[11:0];
assign drv_mag_internal = (PID[13]) ? 12'h000 : capPID;

//pipelining flops
always_ff @(posedge clk)begin
	drv_mag_ff1 <= drv_mag_internal;
	drv_mag <= drv_mag_ff1;
end






endmodule