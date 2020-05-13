module sensorCondition_tb();

	localparam FAST_SIM = 1;
	localparam CADENCE_PER = 4096;

	logic clk, rst_n, cadence;
	logic [11:0] torque, curr;
	
	reg[11:0] pastTorque, pastCurrent;
	
	
	sensorCondition #(FAST_SIM)iDUT(.clk(clk), .rst_n(rst_n), .torque(torque), .cadence(cadence), .curr(curr));
	initial begin
		//reset values 
		clk = 0;
		cadence = 0;
		rst_n = 0;
		torque = 12'h00;
		curr = 12'h00;
		@(posedge clk)
		rst_n = 1;
		
		//////////////////////////////////////Cadence vector tests///////////////////////////////////////////////////
		//Test one checks that the cadence vector field of the Dut is reporting correctly
		//wait for first report of a completed period
		@(posedge iDUT.period);
		//wait for second period to complete to ensure that an entire period of cadence has been sampled
		@(posedge iDUT.period);
		//wait for next clock edge so that cadence vec has a chance to update
		@(posedge clk)
		@(posedge clk)
		//the cadence vec is sampled over 65536 rising clock edges if FAST_SIM is enabled
		if(iDUT.cadence_vec != 65536 / CADENCE_PER)begin
			$display("cadence_vec wrong\nexpected: %d\n actual: %d", 65536 / CADENCE_PER, iDUT.cadence_vec);
			$stop();
		end
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		///////////////////////////////////////Torque averaging tests//////////////////////////////////////////////////
		pastTorque = 0;
		torque = 12'hFF;
		//test that average rises from zero towards new torque
		repeat(10) begin
			repeat(5)@(posedge cadence);
			if(!(iDUT.avg_torque <= torque && iDUT.avg_torque > pastTorque))begin
				$display("avg_torque wrong\nexpected range: (%d - %d]\n actual: %d", pastTorque, torque, iDUT.avg_torque);
				$stop();
			end
			pastTorque = iDUT.avg_torque;
		end
		
		
		//test that average after long period of time rests near constant torque applied
		repeat(100)@(posedge cadence);
		if(!($signed(torque - iDUT.avg_torque) <= 10 && $signed(iDUT.avg_torque - torque) <= 10 ))begin
			$display("avg_torque wrong\nexpected (+-10): %d\n actual: %d", torque, iDUT.avg_torque );
			$stop();
		end
		pastTorque = iDUT.avg_torque;
		
		
		torque = 12'h06;
		//test that average falls towards new torque
		repeat(10) begin
			repeat(5)@(posedge cadence);
			if(!(iDUT.avg_torque >= torque && iDUT.avg_torque < pastTorque))begin
				$display("avg_torque wrong\nexpected range: (%d - %d]\n actual: %d", pastTorque, torque, iDUT.avg_torque);
				$stop();
			end
			pastTorque = iDUT.avg_torque;
		end
		
		
		//test that average after long period of time rests near constant torque applied
		repeat(100)@(posedge cadence);
		if(!($signed(torque - iDUT.avg_torque) <= 10 && $signed(iDUT.avg_torque - torque) <= 10 ))begin
			$display("avg_torque wrong\nexpected (+-10): %d\n actual: %d", torque, iDUT.avg_torque);
			$stop();
		end
		
		//test if not pedaling signal is generated
		torque = 12'hF5;
		force cadence = 0;
		@(posedge iDUT.not_pedaling)
		@(posedge clk)
		release cadence;
		//test if not pedaling fall is generated
		@(posedge iDUT.not_pedaling_fall)
		//test winding of average
		@(posedge clk)
		@(posedge clk)
		if(iDUT.avg_torque != torque[11:1])begin
			$display("avg_torque wind wrong\nexpected: %d\n actual: %d", torque[11:1], iDUT.avg_torque);
			$stop();
		end
		
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////Current Averaging Tests///////////////////////////////////////////////////////
		pastCurrent = 0;
		curr = 12'hFF;
		//test that average rises from zero towards new curr
		repeat(5) begin
			@(posedge iDUT.include_smpl_curr);
			@(posedge clk)
			@(posedge clk)
			if(!(iDUT.avg_curr <= curr && iDUT.avg_curr > pastCurrent))begin
				$display("avg_curr wrong\nexpected range: (%d - %d]\n actual: %d", pastCurrent, curr, iDUT.avg_curr);
				$stop();
			end
			pastCurrent = iDUT.avg_curr;
		end
		
		
		//test that average after long period of time rests near constant curr applied
		repeat(10)@(posedge iDUT.include_smpl_curr);
		if(!($signed(curr - iDUT.avg_curr) <= 10 && $signed(iDUT.avg_curr - curr) <= 10 ))begin
			$display("avg_curr wrong\nexpected (+-10): %d\n actual: %d", curr, iDUT.avg_curr );
			$stop();
		end
		pastCurrent = iDUT.avg_curr;
		
		
		curr = 12'h06;
		//test that average falls towards new curr
		repeat(5) begin
			@(posedge iDUT.include_smpl_curr);
			@(posedge clk)
			@(posedge clk)
			if(!(iDUT.avg_curr >= curr && iDUT.avg_curr < pastCurrent))begin
				$display("avg_curr wrong\nexpected range: (%d - %d]\n actual: %d", pastCurrent, curr, iDUT.avg_curr);
				$stop();
			end
			pastCurrent = iDUT.avg_curr;
		end
		
		
		//test that average after long period of time rests near constant curr applied
		repeat(10)@(posedge iDUT.include_smpl_curr);
		if(!($signed(curr - iDUT.avg_curr) <= 10 && $signed(iDUT.avg_curr - curr) <= 10 ))begin
			$display("avg_curr wrong\nexpected (+-10): %d\n actual: %d", curr, iDUT.avg_curr);
			$stop();
		end
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		$display("all tests Passed");
		$stop();
	end
	always
		#5	clk = ~clk;
		
	always begin
		repeat(CADENCE_PER/2)@(posedge clk);
		cadence = ~cadence;
	end
	
endmodule