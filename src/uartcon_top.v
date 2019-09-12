module uartcon_top
  (
   input        rst_n,
   input        clk,

   output       txd,
   input        rxd,

   // Tx FIFO
   input        write,
   input [7:0]  wdata,
   output       full,
   output       almost_full,
   output       wempty,

   // Rx FIFO
   input        read,
   output [7:0] rdata,
   output       empty,
   output       almost_empty
   );

   wire         uart_clk;

   wire [7:0]   tx_data;
   wire         tx_empty, tx_almost_empty;
   wire         load;

   wire [7:0]   rx_data;
   wire         rx_full, rx_almost_full;
   wire         save;

   reg			tx_empty_reg;
   reg			tx_empty_d1, tx_empty_d2;

   always @(posedge clk or negedge rst_n) begin
	  if(!rst_n) begin
		 tx_empty_reg <= 1'b1;
		 tx_empty_d1 <= 1'b0;
		 tx_empty_d2 <= 1'b0;
	  end else begin
		 tx_empty_d1 <= tx_empty;
		 tx_empty_d2 <= tx_empty_d1;
		 if((tx_empty_d2 == 1'b0) && (tx_empty_d1 == 1'b1)) begin
			tx_empty_reg <= 1'b1;
		 end else if(write == 1'b1) begin
			tx_empty_reg <= 1'b0;
		 end
	  end
   end
   assign wempty = tx_empty_reg;

   uartcon_clk u_uartcon_clk
     (
      .rst_n      ( rst_n     ),
      .clk        ( clk       ),
      .out_clk    ( uart_clk  )
      );

   // Tx FIFO
   fifo
     #(
       .FIFO_DEPTH(7), // 64depth
       .FIFO_WIDTH(8)  // 8bit
       )
   u_tx_fifo
     (
      .RST_N              ( rst_n             ),
      .FIFO_WR_CLK        ( clk               ),
      .FIFO_WR_ENA        ( write             ),
      .FIFO_WR_LAST       ( 1'b1              ),
      .FIFO_WR_DATA       ( wdata[7:0]        ),
      .FIFO_WR_FULL       ( full              ),
      .FIFO_WR_ALM_FULL   ( almost_full       ),
      .FIFO_WR_ALM_COUNT  ( 7'd1              ),
      .FIFO_RD_CLK        ( uart_clk          ),
      .FIFO_RD_ENA        ( load              ),
      .FIFO_RD_DATA       ( tx_data[7:0]      ),
      .FIFO_RD_EMPTY      ( tx_empty          ),
      .FIFO_RD_ALM_EMPTY  ( tx_almost_empty   ),
      .FIFO_RD_ALM_COUNT  ( 7'd1              )
      );

   // Rx FIFO
   fifo
     #(
       .FIFO_DEPTH(7), // 64depth
       .FIFO_WIDTH(8)  // 8bit
       )
   u_rx_fifo
     (
      .RST_N              ( rst_n             ),
      .FIFO_WR_CLK        ( uart_clk          ),
      .FIFO_WR_ENA        ( save              ),
      .FIFO_WR_LAST       ( 1'b1              ),
      .FIFO_WR_DATA       ( rx_data[7:0]      ),
      .FIFO_WR_FULL       ( rx_full           ),
      .FIFO_WR_ALM_FULL   ( rx_almost_full    ),
      .FIFO_WR_ALM_COUNT  ( 7'd1              ),
      .FIFO_RD_CLK        ( clk               ),
      .FIFO_RD_ENA        ( read              ),
      .FIFO_RD_DATA       ( rdata[7:0]        ),
      .FIFO_RD_EMPTY      ( empty             ),
      .FIFO_RD_ALM_EMPTY  ( almost_empty      ),
      .FIFO_RD_ALM_COUNT  ( 7'd1              )
      );

    uartcon_tx u_uartcon_tx
      (
       .rst_n  ( rst_n         ),
       .clk    ( uart_clk      ),
       .txd    ( txd           ),
       .valid  ( ~tx_empty     ),
       .load   ( load          ),
       .data   ( tx_data[7:0]  )
    );

    uartcon_rx u_uartcon_rx
      (
       .rst_n  ( rst_n         ),
       .clk    ( uart_clk      ),
       .rxd    ( rxd           ),
       .valid  ( save          ),
       .data   ( rx_data[7:0]  )
       );

endmodule
