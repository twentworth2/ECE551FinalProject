module PID_tb();

//signals for both DUT
logic clk, rst_n, not_pedaling, test_over;
logic [12:0] error;
logic [11:0] drv_mag;

localparam FAST_SIM = 1;

//DUTS
PID #(FAST_SIM)PID_DUT(.clk(clk), .rst_n(rst_n), .error(error), .not_pedaling(not_pedaling), .drv_mag(drv_mag));
plant_PID plant(.clk(clk), .rst_n(rst_n), .error(error), .not_pedaling(not_pedaling), .drv_mag(drv_mag), .test_over(test_over));

//begin testing
initial begin
clk = 0;
rst_n = 0;

@(posedge clk);
rst_n = 1;
	while(!test_over)begin
		@(posedge clk);
	end
$display("Test over");
$stop();

end

always
	#5 clk = ~ clk;

endmodule
