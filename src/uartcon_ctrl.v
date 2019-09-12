module uartcon_ctrl
  (
   input         RST_N,
   input         CLK,

   // UART
   input         EMPTY,
   input         AEMPTY,
   output        READ,
   input [7:0]   RDATA,

   output        WRITE,
   input         FULL,
   input         AFULL,
   input         WEMPTY,
   output [7:0]  WDATA,

	// User Signal
   output        U_RUN,
   output        U_STOP,
   output        U_WRITE,
   output        U_READ,
   output [31:0] U_ADRS,
   input [31:0]  U_RDATA,
   output [31:0] U_WDATA
   );

   // Hex2Binary convert
   function [3:0] f_hex2bin;
	  input [7:0] data;
	  begin
		 if((data[7:0] >= 8'h30) && (data[7:0] <= 8'h39)) begin
			// numeric
			f_hex2bin[3:0] = data[7:0] - 8'h30;
		 end else if((data[7:0] >= 8'h41) && (data[7:0] <= 8'h46)) begin
			// Eigo(big)
			f_hex2bin[3:0] = data[7:0] - 8'h41 + 8'd10;
		 end else if((data[7:0] >= 8'h61) && (data[7:0] <= 8'h66)) begin
			// Eigo(little)
			f_hex2bin[3:0] = data[7:0] - 8'h61 + 8'd10;
		 end else begin
			f_hex2bin[3:0] = 8'd0;
		 end
	  end
   endfunction

   localparam [23:0]	P_CMD_GET	= "get";
   localparam [23:0]	P_CMD_SET	= "set";
   localparam [23:0]	P_CMD_RUN	= "run";
   localparam [23:0]	P_CMD_STP	= "stp";

   localparam S_INIT		= 6'd0;
   localparam S_PROMPT1		= 6'd1;
   localparam S_PROMPT2		= 6'd2;
   localparam S_IDLE		= 6'd3;
   localparam S_GETCHAR		= 6'd4;
   localparam S_GET_CMD		= 6'd5;
   localparam S_GET_SPACE1	= 6'd6;
   localparam S_GET_ADRS	= 6'd7;
   localparam S_GET_SPACE2	= 6'd8;
   localparam S_GET_DATA	= 6'd9;
   localparam S_DECODE1		= 6'd10;
   localparam S_EXECUTE		= 6'd11;
   localparam S_ERROR		= 6'd12;
   localparam S_WRITEBACK1	= 6'd13;
   localparam S_WRITEBACK2	= 6'd14;
   localparam S_WRITEBACK3	= 6'd15;
   localparam S_WRITEBACK4	= 6'd16;
   localparam S_WRITEBACK5	= 6'd17;
   localparam S_WRITEBACK6	= 6'd18;
   localparam S_FINISH		= 6'd19;
   localparam S_NEWLINE1	= 6'd20;
   localparam S_NEWLINE2	= 6'd21;
   localparam S_DECODE0		= 6'd22;

   reg [5:0]	ctrl_state;
   reg			uart_write;
   reg [7:0]    uart_wdata;
   reg [4:0]    buff_wp;
   reg [4:0]    buff_rp;
   reg [4:0]    buff_ct;
   reg [23:0]   buff_cmd;
   reg [23:0]   buff_rtn;
   reg [31:0]   buff_adrs;
   reg [31:0]   buff_rad;
   reg [31:0]   buff_data;
   reg [31:0]   buff_cnt;
   reg			user_write;
   reg			user_read;
   reg			user_run;
   reg			user_stop;
   reg [7:0]    uart_buff[0:31];

   // Command state machine
   always @(posedge CLK or negedge RST_N) begin
	  if(!RST_N) begin
		 ctrl_state		<= S_INIT;
		 uart_write		<= 1'b0;
		 uart_wdata[7:0]	<= 8'd0;
		 buff_wp[4:0]	<= 5'd0;
		 buff_rp[4:0]	<= 5'd0;
		 buff_ct[4:0]	<= 5'd0;
		 buff_cmd[23:0]	<= 24'd0;
		 buff_rtn[23:0]	<= 24'd0;
		 buff_adrs[31:0]	<= 32'd0;
		 buff_data[31:0]	<= 32'd0;
		 buff_cnt[31:0]	<= 32'd0;
		 buff_rad[31:0]	<= 32'd0;
		 user_write		<= 1'b0;
		 user_read		<= 1'b0;
		 user_run		<= 1'b0;
		 user_stop		<= 1'b0;
	  end else begin
		 case(ctrl_state)
		   S_INIT: begin
			  // Initialize
		     ctrl_state		<= S_PROMPT1;
			  uart_write		<= 1'b0;
			  uart_wdata[7:0]	<= 8'd0;
			  buff_wp[4:0]	<= 5'd0;
			  buff_rp[4:0]	<= 5'd0;
			  buff_ct[4:0]	<= 5'd0;
			  buff_cmd[23:0]	<= 24'd0;
			  buff_adrs[31:0]	<= 32'd0;
			  buff_data[31:0]	<= 32'd0;
			  buff_cnt[31:0]	<= 32'd0;
			  buff_rad[31:0]	<= 32'd0;
			  user_write		<= 1'b0;
			  user_read		<= 1'b0;

	       end
		   S_PROMPT1: begin
			  // send ">" for prompt
			  ctrl_state		<= S_PROMPT2;
			  uart_write		<= 1'b1;
			  uart_wdata[7:0]	<= 8'h3E;	// ">"
		   end
		   S_PROMPT2: begin
			  // send " "(space)
			  ctrl_state <= S_IDLE;
			  uart_write		<= 1'b1;
			  uart_wdata[7:0]	<= 8'h20;	// " "(space)
		   end
		   S_IDLE: begin
			  // wait for input command
			  uart_write		<= 1'b0;
			  if(!EMPTY) begin
				 ctrl_state	<= S_GETCHAR;
			  end
		   end
		   S_GETCHAR: begin
			  // get char
			  uart_write		<= 1'b1;
			  uart_wdata[7:0]	<= RDATA[7:0];	// echo
			  buff_wp[4:0]	<= buff_wp[4:0] + 5'd1;
			  uart_buff[buff_wp[4:0]]	<= RDATA[7:0];
			  if(RDATA[7:0] == 8'h0D) begin
				 // if detect 0x0D(CR) then finish
				 ctrl_state	<= S_NEWLINE1;
			  end else begin
				 ctrl_state	<= S_IDLE;
			  end
			  buff_rp[4:0]	<= 5'd0;
			  buff_ct[4:0]	<= 5'd0;
		   end
		   S_NEWLINE1: begin
			  ctrl_state	<= S_GET_CMD;
			  uart_wdata[7:0]	<= 8'h0A;	// LF(New Line)
		   end
		   S_GET_CMD: begin
			  // Get Command
			  if(buff_rp[4:0] == buff_wp[4:0]) begin
				 // if buffer empty thern finish
				 ctrl_state	<= S_DECODE0;
			  end else if(uart_buff[buff_rp[4:0]] == 8'h0D) begin
				 // if detect 0x0D(CR) then finish
				 ctrl_state	<= S_DECODE0;
			  end else if(uart_buff[buff_rp[4:0]] == 8'h20) begin
				 // if detect space then finish
				 ctrl_state	<= S_GET_SPACE1;
			  end else begin
				 // Save localparam(3 chara)
				 if(buff_ct[4:0] < 5'd3) begin
					buff_cmd[23:0] <= {buff_cmd[15:0], uart_buff[buff_rp[4:0]]};
					buff_ct[4:0] <= buff_ct[4:0] + 8'd1;
				 end
			  end
			  buff_rp[4:0] <= buff_rp[4:0] + 5'd1;
			  uart_write		<= 1'b0;
		   end
		   S_GET_SPACE1: begin
			  if(buff_rp[4:0] == buff_wp[4:0]) begin
				 // if buffer empty thern finish
				 ctrl_state	<= S_DECODE0;
			  end else if(uart_buff[buff_rp[4:0]] == 8'h0D) begin
				 // if detect 0x0D(CR) then finish
				 ctrl_state	<= S_DECODE0;
			  end else if(uart_buff[buff_rp[4:0]] == 8'h20) begin
				 // if detect space then finish
				 buff_rp[4:0] <= buff_rp[4:0] + 5'd1;
			  end else begin
				 ctrl_state	<= S_GET_ADRS;
			  end
			  buff_ct[4:0]	<= 5'd0;
		   end
		   S_GET_ADRS: begin
			  if(buff_rp[4:0] == buff_wp[4:0]) begin
				 // if buffer empty thern finish
				 ctrl_state	<= S_DECODE0;
			  end else if(uart_buff[buff_rp[4:0]] == 8'h0D) begin
				 // if detect 0x0D(CR) then finish
				 ctrl_state	<= S_DECODE0;
			  end else if(uart_buff[buff_rp[4:0]] == 8'h20) begin
				 // if detect space then finish
				 ctrl_state	<= S_GET_SPACE2;
			  end else begin
				 // Save localparam(8 chara)
				 if(buff_ct[4:0] < 5'd8) begin
					buff_adrs[31:0] <= {buff_adrs[27:0], f_hex2bin(uart_buff[buff_rp[4:0]])};
					buff_ct[4:0] <= buff_ct[4:0] + 5'd1;
				 end
			  end
			  buff_rp[4:0] <= buff_rp[4:0] + 5'd1;
		   end
		   S_GET_SPACE2: begin
			  if(buff_rp[4:0] == buff_wp[4:0]) begin
				 // if buffer empty thern finish
				 ctrl_state	<= S_DECODE0;
			  end else if(uart_buff[buff_rp[4:0]] == 8'h0D) begin
				 // if detect 0x0D(CR) then finish
				 ctrl_state	<= S_DECODE0;
			  end else if(uart_buff[buff_rp[4:0]] == 8'h20) begin
				 // if detect space then skip
				 buff_rp[4:0] <= buff_rp[4:0] + 5'd1;
			  end else begin
				 ctrl_state	<= S_GET_DATA;
			  end
			  buff_ct[4:0]	<= 5'd0;
		   end
		   S_GET_DATA: begin
			  if(buff_rp[4:0] == buff_wp[4:0]) begin
				 // if buffer empty thern finish
				 ctrl_state	<= S_DECODE0;
			  end else if(uart_buff[buff_rp[4:0]] == 8'h0D) begin
				 // if detect 0x0D(CR) then finish
				 ctrl_state	<= S_DECODE0;
			  end else begin
				 // Save localparam(8 chara)
				 if(buff_ct[4:0] < 5'd8) begin
					buff_data[31:0] <= {buff_data[27:0], f_hex2bin(uart_buff[buff_rp[4:0]])};
					buff_ct[4:0] <= buff_ct[4:0] + 5'd1;
				 end
			  end
			  buff_rp[4:0] <= buff_rp[4:0] + 5'd1;
		   end
		   S_DECODE0: begin
			  ctrl_state	<= S_DECODE1;
			  case(buff_cmd[23:0])
				P_CMD_GET: begin
				   if(buff_data[31:0] == 32'd0) begin
					  buff_cnt[31:0]	<= 32'd1;
				   end else begin
					  buff_cnt[31:0]	<= buff_data[31:0];
				   end
				end
				default: begin
				   buff_cnt[31:0]	<= 32'd1;
				end
			  endcase
		   end
		   S_DECODE1: begin
			  case(buff_cmd[23:0])
				P_CMD_GET: begin
				   buff_data[31:0] <= U_RDATA[31:0];
				   user_read <= 1'b1;
				   ctrl_state	<= S_EXECUTE;
				end
				P_CMD_SET: begin
				   user_write <= 1'b1;
				   ctrl_state	<= S_EXECUTE;
				end
				P_CMD_RUN: begin
				   user_run <= 1'b1;
				   user_stop <= 1'b0;
				   ctrl_state	<= S_EXECUTE;
				end
				P_CMD_STP: begin
				   user_run <= 1'b0;
				   user_stop <= 1'b1;
				   ctrl_state	<= S_EXECUTE;
				end
				default: begin
				   ctrl_state	<= S_ERROR;
				end
			  endcase
			  uart_write	<= 1'b0;
			  buff_rad[31:0]	<= buff_adrs[31:0];
		   end
		   S_EXECUTE: begin
			  if(WEMPTY == 1'b1) begin
				 ctrl_state	<= S_WRITEBACK1;
			  end
			  user_read	<= 1'b0;
			  user_write	<= 1'b0;
			  buff_rtn[23:0]	<= "ACK";
			  buff_ct[4:0]	<= 5'd0;
		   end
		   S_ERROR: begin
			  ctrl_state	<= S_WRITEBACK1;
			  buff_rtn[23:0]	<= "ERR";
			  buff_ct[4:0]	<= 5'd0;
		   end
		   S_WRITEBACK1: begin
			  // Output Reply Command
			  if(buff_ct[4:0] == 5'd2) begin
				 ctrl_state	<= S_WRITEBACK2;
			  end else begin
				 buff_ct[4:0]	<= buff_ct[4:0] + 5'd1;
			  end
			  uart_write		<= 1'b1;
			  uart_wdata[7:0]	<= buff_rtn[23:16];
			  buff_rtn[23:8]	<= buff_rtn[15:0];
		   end
		   S_WRITEBACK2: begin
			  ctrl_state	<= S_WRITEBACK3;
			  uart_wdata[7:0]	<= 8'h20;	// 	Space
			  buff_ct[4:0]	<= 5'd0;
			  uart_write		<= 1'b1;
		   end
		   S_WRITEBACK3: begin
			  // Output Address
			  if(buff_ct[4:0] == 5'd7) begin
				 ctrl_state	<= S_WRITEBACK4;
			  end else begin
				 buff_ct[4:0]	<= buff_ct[4:0] + 5'd1;
			  end
			  uart_write		<= 1'b1;
			  if(buff_rad[31:28] >= 4'd10) begin
				 uart_wdata[7:0]	<= {4'd0, buff_rad[31:28]} + 8'h41 - 8'd10;
			  end else begin
				 uart_wdata[7:0]	<= {4'd0, buff_rad[31:28]} + 8'h30;
			  end
			  buff_rad[31:4]	<= buff_rad[27:0];
		   end
		   S_WRITEBACK4: begin
			  ctrl_state	<= S_WRITEBACK5;
			  uart_wdata[7:0]	<= 8'h20;	// Space
			  buff_ct[4:0]	<= 5'd0;
			  uart_write		<= 1'b1;
		   end
		   S_WRITEBACK5: begin
			  // Output Data
			  if(buff_ct[4:0] == 5'd7) begin
				 ctrl_state	<= S_WRITEBACK6;
			  end else begin
				 buff_ct[4:0]	<= buff_ct[4:0] + 5'd1;
			  end
			  uart_write		<= 1'b1;
			  if(buff_data[31:28] >= 4'd10) begin
				 uart_wdata[7:0]	<= {4'd0, buff_data[31:28]} + 8'h41 - 8'd10;
			  end else begin
				 uart_wdata[7:0]	<= {4'd0, buff_data[31:28]} + 8'h30;
			  end
			  buff_data[31:4]	<= buff_data[27:0];
		   end
		   S_WRITEBACK6: begin
			  ctrl_state	<= S_NEWLINE2;
			  uart_wdata[7:0]	<= 8'h0D;	// 0x0D(CR)
			  buff_ct[4:0]	<= 5'd0;
			  buff_adrs[31:0] <= buff_adrs[31:0] + 32'd1;
			  uart_write		<= 1'b1;
		   end
		   S_NEWLINE2: begin
			  if(buff_cnt[31:0] == 32'd1) begin
				 ctrl_state	<= S_FINISH;
			  end else begin
				 buff_cnt[31:0] <= buff_cnt[31:0] - 32'd1;
				 ctrl_state	<= S_DECODE1;
			  end
			  uart_wdata[7:0]	<= 8'h0A;	// LF(New Line)
			  uart_write		<= 1'b1;
		   end

		   S_FINISH: begin
			  uart_write	<= 1'b0;
			  ctrl_state	<= S_INIT;
		   end
		 endcase
	  end
   end

   assign READ			= (ctrl_state == S_GETCHAR)?1'b1:1'b0;
   assign WRITE			= uart_write;
   assign WDATA[7:0]		= uart_wdata[7:0];

   assign U_RUN			= user_run;
   assign U_STOP			= user_stop;
   assign U_WRITE			= user_write;
   assign U_READ			= user_read;
   assign U_ADRS[31:0]	= buff_adrs[31:0];
   assign U_WDATA[31:0]	= buff_data[31:0];

endmodule
