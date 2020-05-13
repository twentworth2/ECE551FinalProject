module eBike_tb();

  reg clk,RST_n;
  reg [11:0] BATT;				// analog values you apply to AnalogModel
  reg [11:0] BRAKE,TORQUE;		// analog values
  reg cadence;					// you have to have some way of applying a cadence signal
  reg tgglMd;	
  reg [15:0] YAW_RT;			// models angular rate of incline
  
  wire A2D_SS_n,A2D_MOSI,A2D_SCLK,A2D_MISO;		// A2D SPI interface
  wire highGrn,lowGrn,highYlw;					// FET control
  wire lowYlw,highBlu,lowBlu;					//   PWM signals
  wire hallGrn,hallBlu,hallYlw;					// hall sensor outputs
  wire inertSS_n,inertSCLK,inertMISO,inertMOSI,inertINT;	// Inert sensor SPI bus
  
  wire [1:0] setting;		// drive LEDs on real design
  wire [11:0] curr;			// comes from eBikePhysics back to AnalogModel
  
  reg [19:0] old_omega;
  int CADENCE_PER = 4096;
  localparam clockWaits = 1500000;
  int thetaMod;
  
  //////////////////////////////////////////////////
  // Instantiate model of analog input circuitry //
  ////////////////////////////////////////////////
  AnalogModel iANLG(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
                    .MISO(A2D_MISO),.MOSI(A2D_MOSI),.BATT(BATT),
		            .CURR(curr),.BRAKE(BRAKE),.TORQUE(TORQUE));

  ////////////////////////////////////////////////////////////////
  // Instantiate model inertial sensor used to measure incline //
  //////////////////////////////////////////////////////////////
  eBikePhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(inertSS_n),.SCLK(inertSCLK),
	             .MISO(inertMISO),.MOSI(inertMOSI),.INT(inertINT),
		     .yaw_rt(YAW_RT),.highGrn(highGrn),.lowGrn(lowGrn),
		     .highYlw(highYlw),.lowYlw(lowYlw),.highBlu(highBlu),
		     .lowBlu(lowBlu),.hallGrn(hallGrn),.hallYlw(hallYlw),
		     .hallBlu(hallBlu),.avg_curr(curr));

  //////////////////////
  // Instantiate DUT //
  ////////////////////
  eBike iDUT(.clk(clk),.RST_n(RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
             .A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
			 .hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
			 .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
			 .highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
			 .inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
			 .inertMISO(inertMISO),.inertINT(inertINT),
			 .cadence(cadence),.tgglMd(tgglMd),.TX(TX),
			 .setting(setting));
	
  ///////////////////////////////////////////////////////////
  // Instantiate Something to monitor telemetry output??? //
  /////////////////////////////////////////////////////////
			 
	
		assign thetaMod = iPHYS.theta % 360;
  initial begin
      //This is where your magic occurs
	  RST_n = 0;
	  BATT = 12'hFF0;
	  TORQUE = 0;
	  BRAKE = 12'hFF0;
	  YAW_RT = 0;
	  cadence = 0;
	  clk = 0;
	  tgglMd = 0;
	  @(posedge clk);
	  RST_n = 1;
	  TORQUE = 12'h500;  //this is a good mid torque value, allows room to move without saturating target current
	  
	  
	  //allow time for motor speed to stabalize
	  repeat(clockWaits)@(posedge clk);
	  
	  
	  
	  //decrease batt below threshold, should force error to zero
	  BATT = 12'h000;
	  repeat(clockWaits/10)@(posedge clk);
	  if(iDUT.iSensor.error != 0) begin
	 	$display("Test FAILED - low Batt did not force error to 0");
		$stop();
	  end
	  
	  //inrease batt above threshold, should result in non zero error
	  old_omega = iPHYS.omega;
	  BATT = 12'hCAA;
	  repeat(clockWaits/10)@(posedge clk);
	  if(iDUT.iSensor.error == 0) begin
	 	$display("Test FAILED - increasing battery still resulted in zero error");
		$stop();
	  end
	  
	  //increasing torque increases motor speed
	  TORQUE = 12'h7FF;
	  checkOmegaIncrease(clockWaits, "Test FAILED - omega did not increase when increasing incline");
	  
	  //decreasing torque decrease motor 
	  TORQUE = 12'h500;
	  checkOmegaDecrease(clockWaits, "Test FAILED - omega did not decrease when decreasing incline");
	  
	  
	  //checks that omega(motor speed) would decrease as incline does
	  YAW_RT = 16'hC000;
	  checkOmegaDecrease(clockWaits, "Test FAILED - omega did not decrease when decreasing incline");
		
	  //checks that omega(motor speed) would increase as incline does
	  YAW_RT = 16'h4000;
	  checkOmegaIncrease(clockWaits, "Test FAILED - omega did not increase when increasing incline");
	  
	  
	  
	  //speed up cadence should see increase in omega 
	  CADENCE_PER = 1024;
	  checkOmegaIncrease(clockWaits, "Test FAILED - omega did not increase when increasing cadence");
	  
	  //slow down cadence should see decrease in omega
	  CADENCE_PER = 8000;
	  checkOmegaDecrease(clockWaits, "Test FAILED - omega did not decrease when decreasing cadence");
	  
	  
	  
	  //assert brake lower than threshold, should slow motor
	  BRAKE = 12'h000;
	  checkOmegaDecrease(clockWaits, "Test FAILED - omega did not decrease, when braking");
	  
	  //remove braking, should accelerate motor
	  BRAKE = 12'hFF0;
	  checkOmegaIncrease(clockWaits, "Test FAILED - omega did not increase, when releasing brake");
	  
	  
	  
	  //increase assistance level to high assist, should see increase in motor speed
	  toggleSetting();
	  checkOmegaIncrease(clockWaits, "Test FAILED - omega did not increase, from mid assist to high");
	  
	  //decrease assistance level to no assist, should see decrease in motor speed
	  toggleSetting();
	  checkOmegaDecrease(clockWaits, "Test FAILED - omega did not decrease from high assist to none");
	  
	  //increase assistance level to low assist, should see increase in motor speed
	  toggleSetting();
	  checkOmegaIncrease(clockWaits, "Test FAILED - omega did not increase from no assist to low");
	  
	  //increase assistance level to med assist, should see increase in motor speed
	  toggleSetting();
	  checkOmegaIncrease(clockWaits, "Test FAILED - omega did not increase from low assist to mid");
	  
	  
	  
	  $display("All tests Passed");
	  $stop();
  end
	  
  //constant test fet controls
  assert property(@(posedge clk) !(highBlu && lowBlu))
  else $error("ERROR: both highBlu and lowBlu asserted");
  assert property(@(posedge clk) !(highGrn && lowGrn))
  else $error("ERROR: both highGrn and lowGrn asserted");
  assert property(@(posedge clk) !(highYlw && lowYlw))
  else $error("ERROR: both highYlw and lowYlw asserted");
  
  task toggleSetting();
	  tgglMd = 1'b0;
	  @(posedge clk)
	  tgglMd = 1'b1;
	  @(posedge clk)
	  tgglMd = 1'b0;
  endtask
  
  task checkOmegaIncrease(input int waitTime, input string errorMessage);
	  old_omega = iPHYS.omega;
	  repeat(waitTime)@(posedge clk);
	  assert(iPHYS.omega >= old_omega)
	  else $error(errorMessage);
  endtask
  
  task checkOmegaDecrease(input int waitTime, input string errorMessage);
	  old_omega = iPHYS.omega;
	  repeat(waitTime)@(posedge clk);
	  assert(iPHYS.omega <= old_omega)
	  else $error(errorMessage);
  endtask
  
  always begin
	repeat(CADENCE_PER/2)@(posedge clk);
	cadence = ~cadence;
  end
	
  
  always
    #2 clk = ~clk;

	
endmodule
