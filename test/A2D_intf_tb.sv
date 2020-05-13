module A2D_intf_tb();

reg clk, rst_n;
wire [11:0] batt, curr, brake, torque;
wire a2d_SS_n, SCLK, MOSI, MISO;

A2D_intf DUT(.MISO(MISO), .clk(clk), .rst_n(rst_n), .batt(batt), .curr(curr), .brake(brake), .torque(torque), .a2d_SS_n(a2d_SS_n), .SCLK(SCLK), .MOSI(MOSI));

ADC128S bDUT(.clk(clk), .rst_n(rst_n), .MOSI(MOSI), .MISO(MISO), .SCLK(SCLK), .SS_n(a2d_SS_n));

initial begin
  clk = 0;
  rst_n = 0;
  @(posedge clk);
  rst_n = 1;
  repeat(35000)
    @(posedge clk);
  $stop();
end

always begin
#10
clk <= ~clk;
end
endmodule 