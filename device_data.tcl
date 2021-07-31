#package provide DeviceData 1
namespace eval device_data {
	# pin dict is used to display the config pins state in the Configuration Diagnostic Tool.
	# It must match with the pins name in the JAM file
	set pin_28nm [dict create]
	dict set pin_28nm MSEL -1
	dict set pin_28nm CONF_DONE -1
	dict set pin_28nm nSTATUS -1
	dict set pin_28nm nCE -1
	dict set pin_28nm nCONFIG -1
	dict set pin_28nm DCLK -1
	
	set pin_20nm [dict create]
	dict set pin_20nm MSEL -1
	dict set pin_20nm CONF_DONE -1
	dict set pin_20nm nSTATUS -1
	dict set pin_20nm nCE -1
	dict set pin_20nm nCONFIG -1
	dict set pin_20nm DCLK -1
	
	set pin [dict create]
	dict set pin "28nm" $pin_28nm
	dict set pin "20nm" $pin_20nm
	
	set emr_28nm [dict create]
	dict set emr_28nm Full_EMR -1
	dict set emr_28nm Syndrome -1
	dict set emr_28nm Frame_Address -1
	dict set emr_28nm Double_Word -1
	dict set emr_28nm Byte -1
	dict set emr_28nm Bit_Location -1
	dict set emr_28nm Error_Type -1
	
	set emr_20nm [dict create]
	dict set emr_20nm Full_EMR -1
	dict set emr_20nm Frame_Address -1
	dict set emr_20nm Column_Based_Double_Word -1
	dict set emr_20nm Column_Based_Bit -1
	dict set emr_20nm Column_Based_Type -1
	dict set emr_20nm Frame_Based_Syndrome -1
	dict set emr_20nm Frame_Based_Double_Word -1
	dict set emr_20nm Frame_Based_Bit -1
	dict set emr_20nm Frame_Based_Type -1
	dict set emr_20nm Reserved -1
	dict set emr_20nm Column_Check_Bit_Update -1
	
	set emr [dict create]
	dict set emr "20nm" $emr_20nm
	dict set emr "28nm" $emr_28nm
	
	set emr_table_28nm [dict create]
	#						Field						{		MSB LSB		Number_Of_bit	Label			Description	}
	dict set emr_table_28nm "Full_EMR"					[list	66	0		67				"Full EMR"		""]
	dict set emr_table_28nm "Syndrome"					[list	66	35		32				"Syndrome"		""]
	dict set emr_table_28nm "Frame_Address"				[list	34	19		16				"Frame Address"	""]
	dict set emr_table_28nm "Double_Word"				[list	18	9		10				"Double Word"	""]
	dict set emr_table_28nm "Byte"						[list	8	7		2				"Byte"			""]
	dict set emr_table_28nm "Bit_Location"				[list	6	4		3				"Bit Location"	""]
	dict set emr_table_28nm "Error_Type"				[list	3	0		4				"Error Type"	""]
	
	
	set emr_table_20nm [dict create]
	#						Field						{ 		MSB	LSB		Number_Of_bit	Label						Description	}
	dict set emr_table_20nm "Full_EMR" 					[list	77	0		78				"Full EMR"					""]
	dict set emr_table_20nm "Frame_Address" 			[list	77	62		16				"Frame Address"				""]
	dict set emr_table_20nm "Column_Based_Double_Word" 	[list	61	60		2				"Column-Based Double Word"	""]
	dict set emr_table_20nm "Column_Based_Bit" 			[list	59	55		5				"Column-Based Bit"			""]
	dict set emr_table_20nm "Column_Based_Type"			[list	54	52		3				"Column-Based Type"			""]
	dict set emr_table_20nm "Frame_Based_Syndrome" 		[list	51	20		32				"Frame-Based Syndrome"		""]
	dict set emr_table_20nm "Frame_Based_Double_Word" 	[list	19	10		10				"Frame-Based Double Word"	""]
	dict set emr_table_20nm "Frame_Based_Bit" 			[list	9	5		5				"Frame-Based Bit"			""]
	dict set emr_table_20nm "Frame_Based_Type" 			[list	4	2		3				"Frame-Based Type"			""]
	dict set emr_table_20nm "Reserved" 					[list	1	1		1				"Reserved"					""]
	dict set emr_table_20nm "Column_Check_Bit_Update" 	[list	0	0		1				"Column-Check-Bit Update"	""]
		
	set emr_table [dict create]
	dict set emr_table "20nm" $emr_table_20nm
	dict set emr_table "28nm" $emr_table_28nm

	set emr_error_type_28nm [dict create]
	dict set emr_error_type_28nm "b0000" "No error"
	dict set emr_error_type_28nm "b0001" "Single-bit error"
	dict set emr_error_type_28nm "b0010" "Double-adjacent errors"
	dict set emr_error_type_28nm "b1111" "Uncorrectable errors"
	
	set emr_error_type_20nm [dict create]
	dict set emr_error_type_20nm "fb01" [list {Frame-based [2:0]} b000 "No error"]
	dict set emr_error_type_20nm "fb02" [list {Frame-based [2:0]} b001 "Single-bit error"]
	dict set emr_error_type_20nm "fb03" [list {Frame-based [2:0]} b01X "Double-adjacent error"]
	dict set emr_error_type_20nm "fb04" [list {Frame-based [2:0]} b111 "Uncorrectable error"]
	dict set emr_error_type_20nm "cb01" [list {Column-based [2:0]} b000 "No error"]
	dict set emr_error_type_20nm "cb02" [list {Column-based [2:0]} b001 "Single bit error"]
	dict set emr_error_type_20nm "cb03" [list {Column-based [2:0]} b01X "Double-adjacent error in a same frame"]
	dict set emr_error_type_20nm "cb04" [list {Column-based [2:0]} b10X "Double-adjacent error in a different frame"]
	dict set emr_error_type_20nm "cb05" [list {Column-based [2:0]} b110 "Double-adjacent error in a different frame"]
	dict set emr_error_type_20nm "cb06" [list {Column-based [2:0]} b111 "Uncorrectable error"]
		
	set emr_error_type [dict create]
	dict set emr_error_type "20nm" $emr_error_type_20nm
	dict set emr_error_type "28nm" $emr_error_type_28nm
		
	set key_verify_reg_28nm [dict create]
	set key_verify_reg_20nm [dict create]
	dict set key_verify_reg_20nm 0 -1
	dict set key_verify_reg_20nm 1 -1
	dict set key_verify_reg_20nm 2 -1
	dict set key_verify_reg_20nm 3 -1
	dict set key_verify_reg_20nm 4 -1
	dict set key_verify_reg_20nm 5 -1
	dict set key_verify_reg_20nm 6 -1
	dict set key_verify_reg_20nm 7 -1
	dict set key_verify_reg_20nm 8 -1
	dict set key_verify_reg_20nm 9 -1
	dict set key_verify_reg_20nm 10 -1
	dict set key_verify_reg_20nm 11 -1
	dict set key_verify_reg_20nm 12 -1
	dict set key_verify_reg_20nm 13 -1
	dict set key_verify_reg_20nm 14 -1
	dict set key_verify_reg_20nm 15 -1
	dict set key_verify_reg_20nm 16 -1
	dict set key_verify_reg_20nm 17 -1
	dict set key_verify_reg_20nm 18 -1
	dict set key_verify_reg_20nm 19 -1
	dict set key_verify_reg_20nm 20 -1
	
	set key_verify_reg [dict create]
	dict set key_verify_reg "20nm" $key_verify_reg_20nm
	dict set key_verify_reg "28nm" $key_verify_reg_28nm
	
	set key_verify_table_28nm [dict create]
	set key_verify_table_20nm [dict create]
	
	dict set key_verify_table_20nm 0 [list "Volatile Key" "This bit is set when a volatile key has been successfully programmed into the device."]
	dict set key_verify_table_20nm 1 [list "Attempt Non-volatile Key Programming" "This bit is set to indicate that someone attempted to burn a non-volatile key in the OTP fused."]
	dict set key_verify_table_20nm 2 [list "Disable Non-volatile Key" "This bit is set to disable use of the non-volatile key."]
	dict set key_verify_table_20nm 3 [list "Non-volatile Key" "This bit is set to indicate that someone has successfully burned a non-volatile key into the OTP fuses."]
	dict set key_verify_table_20nm 4 [list "Tamper Protection" "This bit is set when FPGA is in Tamper Protection mode with either Non-volatile or Volatile key."]
	dict set key_verify_table_20nm 6 [list "Volatile Key Lock" "This bit is set to prevent the volatile key from being reprogrammed from external JTAG."]
	dict set key_verify_table_20nm 11 [list "Force Configuration from HPS only" "This bit is set when configuration is allowed from HPS only."]
	dict set key_verify_table_20nm 12 [list "External JTAG Bypass" "This bit is set to indicate that external JTAG is disabled."]
	dict set key_verify_table_20nm 13 [list "HPS JTAG Bypass" "This bit is set to indicate that HPS JTAG is disabled."]
	dict set key_verify_table_20nm 14 [list "Disable Partial Reconfiguration and Scrubbing" "This bit is set to indicate that external PR and external scrubbing (including HPS PR and HPS scrubbing) are disabled."]
	dict set key_verify_table_20nm 15 [list "Disable Volatile Key" "This bit is set to indicate that the volatile key is disabled."]
	dict set key_verify_table_20nm 17 [list "Disable Key Related JTAG Instructions" "This bit is set to indicate that external JTAG access to all key-related JTAG instructions is disabled."]
	dict set key_verify_table_20nm 18 [list "JTAG Secure Mode" "This bit is set to indicate that only mandatory JTAG instructions are allowed to be externally accessed."]
	dict set key_verify_table_20nm 20 [list "Volatile Key Clear" "This bit is set when the volatile key is successfully cleared from the device."]
	
	set key_verify_table [dict create]
	dict set key_verify_table "20nm" $key_verify_table_20nm
	dict set key_verify_table "28nm" $key_verify_table_28nm
	
	
	
	#set config_pin [dict get $pin "28nm"]
	#puts [dict get $config_pin MSEL]
	
	# bsc dict is used as a database for boundary scan cell location of the pins,
	# they are used to compose the JAM file to read the pins state
	set bsc [dict create]
	# 				IDCODE => 	{		MSEL[4],	MSEL[3],	MSEL[2],	MSEL[1],	MSEL[0],	CONF_DONE,	nSTATUS,	nCE,	nCONFIG,	DCLK	}
	#Cyclone V
	dict set bsc 	"02B010DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02B020DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02B120DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02B220DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02B030DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02B130DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02B040DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02B140DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02B050DD" [list 	171			180			183	 		186	 		189			162			165			168		171			15	]
	dict set bsc 	"02B150DD" [list 	171			180			183	 		186	 		189			162			165			168		171			15	]
	dict set bsc 	"02D010DD" [list 	33			36			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02D110DD" [list 	33			36			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02D020DD" [list 	33			36			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02D120DD" [list 	33			36			39	 		42	 		45			18			21			24		27			15	]
	
	#Arria V
	dict set bsc 	"02A060DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02A160DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02A010DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02A110DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02A020DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02A120DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02A030DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02A130DD" [list 	33 			36 			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02D030DD" [list 	33			36			39	 		42	 		45			18			21			24		27			15	]
	dict set bsc 	"02D130DD" [list 	33			36			39	 		42	 		45			18			21			24		27			15	]
	
	#Stratix V
	dict set bsc	"029030DD" [list	1565		1562		1559		1556		1553		1571		1574		1577	18			0	]
	dict set bsc	"029130DD" [list	1565		1562		1559		1556		1553		1571		1574		1577	18			0	]
	dict set bsc	"029430DD" [list	1565		1562		1559		1556		1553		1571		1574		1577	18			0	]
	dict set bsc	"029230DD" [list	1565		1562		1559		1556		1553		1571		1574		1577	18			0	]
	dict set bsc	"029020DD" [list	1307		1304		1301		1298		1295		1313		1316		1319	18			0	]
	dict set bsc	"029120DD" [list	1307		1304		1301		1298		1295		1313		1316		1319	18			0	]
	dict set bsc	"029070DD" [list	1497		1494		1491		1488		1485		1503		1506		1509	18			0	]
	dict set bsc	"029170DD" [list	1497		1494		1491		1488		1485		1503		1506		1509	18			0	]
	dict set bsc	"029270DD" [list	1497		1494		1491		1488		1485		1503		1506		1509	18			0	]
	dict set bsc	"029470DD" [list	1497		1494		1491		1488		1485		1503		1506		1509	18			0	]
	dict set bsc	"029010DD" [list	1141		1138		1135		1132		1129		1147		1150		1153	18			0	]
	dict set bsc	"029110DD" [list	1141		1138		1135		1132		1129		1147		1150		1153	18			0	]
	dict set bsc	"029210DD" [list	1141		1138		1135		1132		1129		1147		1150		1153	18			0	]
	dict set bsc	"029040DD" [list	1565		1562		1559		1556		1553		1571		1574		1577	18			0	]
	dict set bsc	"029140DD" [list	1565		1562		1559		1556		1553		1571		1574		1577	18			0	]
	dict set bsc	"029050DD" [list	1667		1664		1661		1658		1655		1673		1676		1679	18			0	]
	dict set bsc	"029150DD" [list	1667		1664		1661		1658		1655		1673		1676		1679	18			0	]
	dict set bsc	"029250DD" [list	1667		1664		1661		1658		1655		1673		1676		1679	18			0	]
	dict set bsc	"029450DD" [list	1667		1664		1661		1658		1655		1673		1676		1679	18			0	]
	dict set bsc	"029850DD" [list	1667		1664		1661		1658		1655		1673		1676		1679	18			0	]
	dict set bsc	"029950DD" [list	1667		1664		1661		1658		1655		1673		1676		1679	18			0	]

	#Arria 10		IDCODE => 	{		MSEL[2],	MSEL[1],	MSEL[0],	CONF_DONE,	nSTATUS,	nCE,	nCONFIG,	DCLK	}
	dict set bsc	"02EE20DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E620DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E220DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E020DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02EE30DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E630DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E230DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E030DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E240DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E040DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02EE50DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E650DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E250DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E050DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02EE60DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E660DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E260DD" [list	42			45			48			33			36			24		27			0	]
	dict set bsc	"02E060DD" [list	42			45			48			33			36			24		27			0	]

		
	set device_family [dict create]
	#						IDCODE	=>	{	Family,	DR_Length,	Description	}
	dict set device_family "02B010DD" [list "28nm"	729			"Cyclone V"	]	
	dict set device_family "02B020DD" [list "28nm"	1104		"Cyclone V"	]	
	dict set device_family "02B120DD" [list "28nm"	1104		"Cyclone V"	]	
	dict set device_family "02B220DD" [list "28nm"	1104		"Cyclone V"	]	
	dict set device_family "02B030DD" [list "28nm"	1488		"Cyclone V"	]	
	dict set device_family "02B130DD" [list "28nm"	1488		"Cyclone V"	]	
	dict set device_family "02B040DD" [list "28nm"	1728		"Cyclone V"	]
	dict set device_family "02B140DD" [list "28nm"	1728		"Cyclone V"	]
	dict set device_family "02B050DD" [list "28nm"	864			"Cyclone V"	]
	dict set device_family "02B150DD" [list "28nm"	864			"Cyclone V"	]
	dict set device_family "02D010DD" [list "28nm"	1197		"Cyclone V SoC"	]
	dict set device_family "02D110DD" [list "28nm"	1197		"Cyclone V SoC"	]
	dict set device_family "02D020DD" [list "28nm"	1485		"Cyclone V SoC"	]
	dict set device_family "02D120DD" [list "28nm"	1485		"Cyclone V SoC"	]	
	dict set device_family "02A060DD" [list "28nm"	2160		"Arria V"	]
	dict set device_family "02A160DD" [list "28nm"	2160		"Arria V"	]
	dict set device_family "02A010DD" [list "28nm"	1488		"Arria V"	]
	dict set device_family "02A110DD" [list "28nm"	1488		"Arria V"	]
	dict set device_family "02A020DD" [list "28nm"	1680		"Arria V"	]
	dict set device_family "02A120DD" [list "28nm"	1680		"Arria V"	]
	dict set device_family "02A030DD" [list "28nm"	2160		"Arria V"	]
	dict set device_family "02A130DD" [list "28nm"	2160		"Arria V"	]
	dict set device_family "02D030DD" [list "28nm"	2469		"Arria V SoC"	]
	dict set device_family "02D130DD" [list "28nm"	2469		"Arria V SoC"	]
	dict set device_family "029030DD" [list "28nm"	2843		"Stratix V"	]
	dict set device_family "029130DD" [list "28nm"	2843		"Stratix V"	]
	dict set device_family "029430DD" [list "28nm"	2843		"Stratix V"	]
	dict set device_family "029230DD" [list "28nm"	2843		"Stratix V"	]
	dict set device_family "029020DD" [list "28nm"	2225		"Stratix V"	]
	dict set device_family "029120DD" [list "28nm"	2225		"Stratix V"	]
	dict set device_family "029070DD" [list "28nm"	2775		"Stratix V"	]
	dict set device_family "029170DD" [list "28nm"	2775		"Stratix V"	]
	dict set device_family "029270DD" [list "28nm"	2775		"Stratix V"	]
	dict set device_family "029470DD" [list "28nm"	2775		"Stratix V"	]
	dict set device_family "029010DD" [list "28nm"	2131		"Stratix V"	]
	dict set device_family "029110DD" [list "28nm"	2131		"Stratix V"	]
	dict set device_family "029210DD" [list "28nm"	2131		"Stratix V"	]
	dict set device_family "029040DD" [list "28nm"	2843		"Stratix V"	]
	dict set device_family "029140DD" [list "28nm"	2843		"Stratix V"	]
	dict set device_family "029050DD" [list "28nm"	2945		"Stratix V"	]
	dict set device_family "029150DD" [list "28nm"	2945		"Stratix V"	]
	dict set device_family "029250DD" [list "28nm"	2945		"Stratix V"	]
	dict set device_family "029450DD" [list "28nm"	2945		"Stratix V"	]
	dict set device_family "029850DD" [list "28nm"	2945		"Stratix V"	]
	dict set device_family "029950DD" [list "28nm"	2945		"Stratix V"	]
	dict set device_family "02EE20DD" [list "20nm"	1339		"Arria 10 GX"	]
	dict set device_family "02E620DD" [list "20nm"	1390		"Arria 10 SoC"	]
	dict set device_family "02E220DD" [list "20nm"	1339		"Arria 10 GX"	]
	dict set device_family "02E020DD" [list "20nm"	1390		"Arria 10 SoC"	]
	dict set device_family "02EE30DD" [list "20nm"	1339		"Arria 10 GX"	]
	dict set device_family "02E630DD" [list "20nm"	1390		"Arria 10 SoC"	]
	dict set device_family "02E230DD" [list "20nm"	1339		"Arria 10 GX"	]
	dict set device_family "02E030DD" [list "20nm"	1390		"Arria 10 SoC"	]
	dict set device_family "02E240DD" [list "20nm"	1983		"Arria 10 GX"	]
	dict set device_family "02E040DD" [list "20nm"	2034		"Arria 10 SoC"	]
	dict set device_family "02EE50DD" [list "20nm"	2627		"Arria 10 GX"	]
	dict set device_family "02E650DD" [list "20nm"	2678		"Arria 10 SoC"	]
	dict set device_family "02E250DD" [list "20nm"	2627		"Arria 10 GX"	]
	dict set device_family "02E050DD" [list "20nm"	2678		"Arria 10 SoC"	]
	dict set device_family "02EE60DD" [list "20nm"	2899		"Arria 10 GX"	]
	dict set device_family "02E660DD" [list "20nm"	2899		"Arria 10 GX"	]
	dict set device_family "02E260DD" [list "20nm"	2899		"Arria 10 GT"	]
	dict set device_family "02E060DD" [list "20nm"	2899		"Arria 10 GT"	]
	
	set msel_table_28nm [dict create]
	dict set msel_table_28nm "10100" [list "FPPx8" "Fast POR"]
	dict set msel_table_28nm "11000" [list "FPPx8" "Standard POR"]
	dict set msel_table_28nm "10101" [list "FPPx8" "Fast POR" "Encrypt" "Uncompress"]
	dict set msel_table_28nm "11001" [list "FPPx8" "Standard POR" "Encrypt" "Uncompress"]
	dict set msel_table_28nm "10110" [list "FPPx8" "Fast POR" "Compress"]
	dict set msel_table_28nm "11010" [list "FPPx8" "Standard POR" "Compress"]
	dict set msel_table_28nm "00000" [list "FPPx16" "Fast POR"]
	dict set msel_table_28nm "00100" [list "FPPx16" "Standard POR"]
	dict set msel_table_28nm "00001" [list "FPPx16" "Fast POR" "Encrypt" "Uncompress"]
	dict set msel_table_28nm "00101" [list "FPPx16" "Standard POR" "Encrypt" "Uncompress"]
	dict set msel_table_28nm "00010" [list "FPPx16" "Fast POR" "Compress"]
	dict set msel_table_28nm "00110" [list "FPPx16" "Standard POR" "Compress"]
	dict set msel_table_28nm "01000" [list "FPPx32" "Fast POR"]
	dict set msel_table_28nm "01100" [list "FPPx32" "Standard POR"]
	dict set msel_table_28nm "01001" [list "FPPx32" "Fast POR" "Encrypt" "Uncompress"]
	dict set msel_table_28nm "01101" [list "FPPx32" "Standard POR" "Encrypt" "Uncompress"]
	dict set msel_table_28nm "01010" [list "FPPx32" "Fast POR" "Compress"]
	dict set msel_table_28nm "01110" [list "FPPx32" "Standard POR" "Compress"]
	dict set msel_table_28nm "10000" [list "PS" "Fast POR"]
	dict set msel_table_28nm "10001" [list "PS" "Standard POR"]
	dict set msel_table_28nm "10010" [list "AS(x1/x4)" "Fast POR"]
	dict set msel_table_28nm "10011" [list "AS(x1/x4)" "Standard POR"]

	set msel_table_20nm [dict create]
	dict set msel_table_20nm "010" [list "AS(x1/x4)" "Fast POR"]
	dict set msel_table_20nm "011" [list "AS(x1/x4)" "Slow POR"]
	dict set msel_table_20nm "000" [list "PS/FPP(x8/x16/x32)" "Fast POR"]
	dict set msel_table_20nm "001" [list "PS/FPP(x8/x16/x32)" "Slow POR"]	
	
	set msel_table [dict create]
	dict set msel_table "28nm" $msel_table_28nm
	dict set msel_table "20nm" $msel_table_20nm

}

namespace eval helper {
	# helper function
	set bin2hex_table [dict create]
	dict set bin2hex_table 0000 0
	dict set bin2hex_table 0001 1
	dict set bin2hex_table 0010 2
	dict set bin2hex_table 0011 3
	dict set bin2hex_table 0100 4
	dict set bin2hex_table 0101 5
	dict set bin2hex_table 0110 6
	dict set bin2hex_table 0111 7
	dict set bin2hex_table 1000 8
	dict set bin2hex_table 1001 9
	dict set bin2hex_table 1010 A
	dict set bin2hex_table 1011 B
	dict set bin2hex_table 1100 C
	dict set bin2hex_table 1101 D
	dict set bin2hex_table 1110 E
	dict set bin2hex_table 1111 F
}