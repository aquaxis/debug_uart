module uartcon_tx
(
   input       rst_n,
   input       clk,

   output reg  txd,

   input       valid,
   output reg  load,
   input [7:0] data
);

   reg [1:0]   sample_count;
   reg [2:0]   bit_count;
   reg [7:0]   tx_data;

   wire        sample_point;

   reg [3:0]   state;

   localparam S_IDLE    = 4'd0;
   localparam S_START   = 4'd1;
   localparam S_DATA    = 4'd2;
   localparam S_STOP    = 4'd3;
   localparam S_LAST    = 4'd4;

   always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
         sample_count[1:0] <= 2'd0;
      end else begin
         if(state != S_IDLE) begin
            sample_count[1:0] <= sample_count[1:0] + 2'd1;
         end else begin
            sample_count[1:0] <= 2'd0;
         end
      end
   end

   assign sample_point = (sample_count[1:0] == 2'd3)?1'b1:1'b0;

   always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
         state          <= S_IDLE;
         tx_data[7:0]   <= 8'd0;
         load           <= 1'b0;
         txd            <= 1'b1;
         bit_count[2:0] <= 3'd0;
      end else begin
         case(state)
           S_IDLE: begin
              if(valid == 1'b1) begin
                 state        <= S_START;
                 tx_data[7:0] <= data[7:0];
                 load         <= 1'b1;
              end
              bit_count[2:0]  <= 3'd0;
           end
           S_START: begin
              load     <= 1'b0;
              txd      <= 1'b0;
              if(sample_point == 1'b1) begin
                 state <= S_DATA;
              end
           end
           S_DATA: begin
              txd <= tx_data[0];
              if(sample_point == 1'b1) begin
                 tx_data[7:0]   <= {1'b0, tx_data[7:1]};
                 bit_count[2:0] <= bit_count[2:0] + 3'd1;
                 if(bit_count[2:0] == 3'd7) begin
                    state <= S_STOP;
                 end
              end
           end
           S_STOP: begin
              txd <= 1'b1;
              if(sample_point == 1'b1) begin
                 state <= S_LAST;
              end
           end
           S_LAST: begin
              txd <= 1'b1;
              if(sample_point == 1'b1) begin
                 state <= S_IDLE;
              end
           end
         endcase
      end
   end
endmodule
