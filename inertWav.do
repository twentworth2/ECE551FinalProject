onerror {resume}
quietly set dataset_list [list sim vsim]
if {[catch {datasetcheck $dataset_list}]} {abort}
quietly WaveActivateNextPane {} 0
add wave -noupdate sim:/eBike_tb/BATT
add wave -noupdate sim:/eBike_tb/BRAKE
add wave -noupdate sim:/eBike_tb/TORQUE
add wave -noupdate sim:/eBike_tb/YAW_RT
add wave -noupdate -radix hexadecimal sim:/eBike_tb/old_omega
add wave -noupdate -format Analog-Step -height 74 -max 22423.0 sim:/eBike_tb/iPHYS/omega
add wave -noupdate -format Analog-Step -height 74 -max 2976.0 -min -2912.0 -radix decimal sim:/eBike_tb/iPHYS/incline
add wave -noupdate -format Analog-Step -height 74 -max 3276.0 -min -3348.0 -radix decimal sim:/eBike_tb/iPHYS/ay
add wave -noupdate sim:/eBike_tb/iDUT/inert_intf/sm_cmd
add wave -noupdate -radix decimal sim:/eBike_tb/iDUT/inert_intf/inert_integ/yaw_rt
add wave -noupdate sim:/eBike_tb/iDUT/inert_intf/spi/state
add wave -noupdate -divider CURR
add wave -noupdate sim:/eBike_tb/iDUT/inert_intf/spi/shift
add wave -noupdate sim:/eBike_tb/iDUT/inert_intf/spi/setDone
add wave -noupdate sim:/eBike_tb/iDUT/inert_intf/spi/negSCLK
add wave -noupdate -format Analog-Step -height 74 -max 870.99999999999989 sim:/eBike_tb/iDUT/sensorCondition/curr
add wave -noupdate -format Analog-Step -height 74 -max 628.99999999999989 -min -719.0 -radix decimal sim:/eBike_tb/iDUT/sensorCondition/error
add wave -noupdate -format Analog-Step -height 74 -max 1146.0 -radix hexadecimal sim:/eBike_tb/iDUT/sensorCondition/target_curr
add wave -noupdate -format Analog-Step -height 74 -max 477.00000000000006 -min -1.0 -radix decimal sim:/eBike_tb/iDUT/sensorCondition/dDrive/incline
add wave -noupdate -format Analog-Step -height 74 -max 60.0 -min -49.0 -radix decimal sim:/eBike_tb/iDUT/sensorCondition/dDrive/incline_sat
add wave -noupdate -format Analog-Step -height 74 -max 316.0 -min 207.0 -radix decimal sim:/eBike_tb/iDUT/sensorCondition/dDrive/incline_factor
add wave -noupdate -format Analog-Step -height 74 -max 511.0 -radix unsigned sim:/eBike_tb/iDUT/sensorCondition/dDrive/incline_lim
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {25808870 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 214
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 2
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {105000011 ns}
