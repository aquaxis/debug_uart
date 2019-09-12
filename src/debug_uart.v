module debug_uart
  (
   input         RST_N,
   input         CLK,

   output        TXD,
   input         RXD,

   output reg [7:0]  LED
   );

   wire write;
   wire [7:0] wdata;
   wire       full, afull;

   wire       read;
   wire [7:0] rdata;
   wire       empty, aempty;

   wire       w_write;
   wire       w_read;
   wire [31:0] w_adrs;
   wire [31:0] w_rdata;
   wire [31:0] w_wdata;

   uartcon_top u_uartcon_top
     (
	  .rst_n		( RST_N			),
	  .clk			( CLK    		),

	  .txd			( TXD			),
	  .rxd			( RXD			),

	  // Tx FIFO
	  .write		( write			),
	  .wdata		( wdata[7:0]	),
	  .full			( full			),
	  .almost_full	( afull			),

	  // Rx FIFO
	  .read			( read			),
	  .rdata		( rdata[7:0]	),
	  .empty		( empty			),
	  .almost_empty	( aempty		)
	  );

   uartcon_ctrl u_uartcon_ctrl
     (
	  .RST_N	( RST_N			),
	  .CLK		( CLK    		),

	  // UART
	  .EMPTY	( empty			),
	  .AEMPTY	( aempty		),
	  .READ		( read			),
	  .RDATA	( rdata[7:0]	),

	  .WRITE	( write			),
	  .FULL		( full			),
	  .AFULL	( afull			),
	  .WEMPTY	( 1'b1			),
	  .WDATA	( wdata[7:0]	),

	  // User Signal
	  .U_WRITE	( w_write		),
	  .U_READ	( w_read		),
	  .U_ADRS	( w_adrs[31:0]	),
	  .U_RDATA	( w_rdata[31:0]	),
	  .U_WDATA	( w_wdata[31:0]	)
      );


always @(posedge CLK or negedge RST_N) begin
  if(!RST_N) begin
    LED <= 0;
  end else begin
    if(w_write) begin
      case(w_adrs)
        32'h0000_0000: LED <= w_wdata[7:0];
      endcase
    end
  end
end

endmodule
