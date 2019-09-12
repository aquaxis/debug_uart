`timescale 1ns / 1ps

module tb_uartcon;

   reg			RST_N;
   reg			CLK100M;
   reg			CLK800k;

   reg [31:0]   u_rdata;

   initial begin
	  #0;
	  $display("");
	  $display("============================================================");
	  $display(" Start Simulation");
	  $display("============================================================");
	  $display("");

	  RST_N		= 1'b0;
	  CLK100M		= 1'b0;
      CLK800k = 1'b0;

	  u_rdata[31:0] = 32'd0;

	  #100;	// 100ns

	  RST_N		= 1'b1;
	  $display(" -> Release Reset");

	  #300000;	// 300us

	  u_task_uart.write("g");
	  u_task_uart.write("e");
	  u_task_uart.write("t");
	  u_task_uart.write(" ");

	  u_task_uart.write("7");
	  u_task_uart.write("6");
	  u_task_uart.write("5");
	  u_task_uart.write("4");
	  u_task_uart.write("3");
	  u_task_uart.write("2");
	  u_task_uart.write("1");
	  u_task_uart.write("0");

	  u_task_uart.write(" ");

	  u_task_uart.write("4");
//		u_task_uart.write("E");
//		u_task_uart.write("D");
//		u_task_uart.write("C");
//		u_task_uart.write("B");
//		u_task_uart.write("A");
//		u_task_uart.write("9");
//		u_task_uart.write("8");

	  u_rdata[31:0] = 32'h89ABCDEF;

	  u_task_uart.write(8'h0D);

//		#3000000;	// 3ms
	  #(3000000*5);	// 15ms

	  u_task_uart.write("s");
	  u_task_uart.write("e");
	  u_task_uart.write("t");
	  u_task_uart.write(" ");

	  u_task_uart.write("F");
	  u_task_uart.write("E");
	  u_task_uart.write("D");
	  u_task_uart.write("C");
	  u_task_uart.write("B");
	  u_task_uart.write("A");
	  u_task_uart.write("9");
	  u_task_uart.write("8");

	  u_task_uart.write(" ");

	  u_task_uart.write("0");
	  u_task_uart.write("0");
	  u_task_uart.write("1");
	  u_task_uart.write("1");
	  u_task_uart.write("2");
	  u_task_uart.write("2");
	  u_task_uart.write("3");
	  u_task_uart.write("3");

	  u_rdata[31:0] = 32'h89ABCDEF;

	  u_task_uart.write(8'h0D);

	  #3000000;	// 3ms

	  u_task_uart.write("b");
	  u_task_uart.write("e");
	  u_task_uart.write("t");

	  u_task_uart.write(" ");

	  u_task_uart.write("7");
	  u_task_uart.write("6");
	  u_task_uart.write("5");
	  u_task_uart.write("4");
	  u_task_uart.write("3");
	  u_task_uart.write("2");
	  u_task_uart.write("1");
	  u_task_uart.write("0");

	  u_task_uart.write(" ");

	  u_task_uart.write("F");
	  u_task_uart.write("E");
	  u_task_uart.write("D");
	  u_task_uart.write("C");
	  u_task_uart.write("B");
	  u_task_uart.write("A");
	  u_task_uart.write("9");
	  u_task_uart.write("8");

	  u_task_uart.write(8'h0D);

	  #3000000;	// 1ms

	  $display("");
	  $display("============================================================");
	  $display(" Finshed Simulation");
	  $display("  Simulation time: %6d [usec]", $time()/1000);
	  $display("============================================================");
	  $display("");

//		$stop();
	  $finish();
   end

   always begin
	  #(83.3/2)	CLK100M <= ~CLK100M;
   end
   always begin
	  #(1250/2)	CLK800k <= ~CLK800k;
   end

   wire txd, rxd;

   wire write;
   wire [7:0] wdata;
   wire       full, afull;

   wire       read;
   wire [7:0] rdata;
   wire       empty, aempty;

   uartcon_top u_uartcon_top
     (
	  .rst_n			( RST_N			),
	  .clk			( CLK800k		),
	  .refclk			( CLK100M		),

	  .txd			( txd			),
	  .rxd			( rxd			),

	  // Tx FIFO
	  .write			( write			),
	  .wdata			( wdata[7:0]	),
	  .full			( full			),
	  .almost_full	( afull			),

	  // Rx FIFO
	  .read			( read			),
	  .rdata			( rdata[7:0]	),
	  .empty			( empty			),
	  .almost_empty	( aempty		)
	  );

   task_uart u_task_uart
     (
	  .tx			( rxd		),
	  .rx			( txd		)
	  );


   wire       u_write, u_read;
   wire [31:0] u_adrs, u_wdata;

   uartcon_ctrl u_uartcon_ctrl
     (
	  .RST_N		( RST_N			),
	  .CLK		( CLK800k		),

	  // UART
	  .EMPTY		( empty			),
	  .AEMPTY		( aempty		),
	  .READ		( read			),
	  .RDATA		( rdata[7:0]	),

	  .WRITE		( write			),
	  .FULL		( full			),
	  .AFULL		( afull			),
	  .WEMPTY		( 1'b1			),
	  .WDATA		( wdata[7:0]	),

	  // User Signal
	  .U_WRITE	( u_write		),
	  .U_READ		( u_read		),
	  .U_ADRS		( u_adrs[31:0]	),
	  .U_RDATA	( u_rdata[31:0]	),
	  .U_WDATA	( u_wdata[31:0]	)
	  );

endmodule
