module inert_intf_test_tb ();

reg clk, RST_n, INT, MISO;
wire SS_n, SCLK, MOSI;
reg [7:0] LED;

inert_intf_test iDUT (.clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .INT(INT), .LED(LED));

initial begin
  clk = 0;
  RST_n = 0;
  @(posedge clk);
  RST_n = 1;
  repeat(75000)
    @(posedge clk);
  INT = 1;
  @(posedge clk);
  @(posedge clk);
  @(posedge clk);
  INT = 0;
  MISO = 16'b1010101010101010;
  repeat (75000)
    @ (posedge clk);
  $stop();
end

always begin
#10
clk <= ~clk;
end
endmodule 