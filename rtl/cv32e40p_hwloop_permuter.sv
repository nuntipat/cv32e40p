
module cv32e40p_hwloop_permuter #(
  parameter NUM_INPUT = 4,
  parameter INPUT_WIDTH = 2,
  parameter USE_BRAM = 1
) (
  input clk,
  input rst_n,
  input next_i,
  input logic [NUM_CTRL_BIT-1:0] random_i, 
  output logic [NUM_INPUT-1:0][INPUT_WIDTH-1:0] index_o,
);
  // TODO: support NUM_INPUT = 8
  localparam NUM_CTRL_BIT = (USE_BRAM == 1) ? 5 : NUM_INPUT * $clog2(NUM_INPUT) - NUM_INPUT + 1;

  if (USE_BRAM == 1) begin
    if (NUM_INPUT == 4) begin
      logic [7:0] ram [23:0]; 

      initial begin
        ram[ 0] = 8'b00_01_10_11;
        ram[ 1] = 8'b00_01_11_10;
        ram[ 2] = 8'b00_10_01_11;
        ram[ 3] = 8'b00_10_11_01;
        ram[ 4] = 8'b00_11_01_10;
        ram[ 5] = 8'b00_11_10_01;
        ram[ 6] = 8'b01_00_10_11;
        ram[ 7] = 8'b01_00_11_10;
        ram[ 8] = 8'b01_10_00_11;
        ram[ 9] = 8'b01_10_11_00;
        ram[10] = 8'b01_11_00_10;
        ram[11] = 8'b01_11_10_00;
        ram[12] = 8'b10_00_01_11;
        ram[13] = 8'b10_00_11_01;
        ram[14] = 8'b10_01_00_11;
        ram[15] = 8'b10_01_11_00;
        ram[16] = 8'b10_11_00_01;
        ram[17] = 8'b10_11_00_01;
        ram[18] = 8'b11_00_01_10;
        ram[19] = 8'b11_00_10_01;
        ram[20] = 8'b11_01_00_10;
        ram[21] = 8'b11_01_10_00;
        ram[22] = 8'b11_10_00_01;
        ram[23] = 8'b11_10_01_00;
      end

      logic [5:0] ctrl_minus_24;
      assign ctrl_minus_24 = random_i - 5'd24;

      logic [4:0] address;
      assign address = ctrl_minus_24[5] ? random_i : ctrl_minus_24[4:0];

      logic [7:0] index_q;
      always_ff @ (posedge clk) begin
        if (next_i == 1'b1) begin
          index_q <= ram[address];
        end
      end

      assign index_o[0] = index_q[1:0];
      assign index_o[1] = index_q[3:2];
      assign index_o[2] = index_q[5:4];
      assign index_o[3] = index_q[7:6];
    end
    // TODO: support NUM_INPUT = 8
  end else begin
    if (NUM_INPUT == 4) begin
      logic [INPUT_WIDTH-1:0] index_d [NUM_INPUT-1:0];
      logic [INPUT_WIDTH-1:0] index_q [NUM_INPUT-1:0];

      logic [INPUT_WIDTH-1:0] out1_1;
      logic [INPUT_WIDTH-1:0] out1_2;
      logic [INPUT_WIDTH-1:0] out1_3;
      logic [INPUT_WIDTH-1:0] out1_4;
      cv32e40p_hwloop_permute_unit #(.INPUT_WIDTH(INPUT_WIDTH)) p1(index_q[0], index_q[1], random_i[0], out1_1, out1_2);
      cv32e40p_hwloop_permute_unit #(.INPUT_WIDTH(INPUT_WIDTH)) p2(index_q[2], index_q[3], random_i[1], out1_3, out1_4);

      logic [INPUT_WIDTH-1:0] out2_1;
      logic [INPUT_WIDTH-1:0] out2_2;
      logic [INPUT_WIDTH-1:0] out2_3;
      logic [INPUT_WIDTH-1:0] out2_4;
      cv32e40p_hwloop_permute_unit #(.INPUT_WIDTH(INPUT_WIDTH)) p3(out1_1, out1_3, random_i[2], out2_1, out2_2);
      cv32e40p_hwloop_permute_unit #(.INPUT_WIDTH(INPUT_WIDTH)) p4(out1_2, out1_4, random_i[3], out2_3, out2_4);

      logic [INPUT_WIDTH-1:0] out3_3;
      logic [INPUT_WIDTH-1:0] out3_4;
      cv32e40p_hwloop_permute_unit #(.INPUT_WIDTH(INPUT_WIDTH)) p5(out2_2, out2_4, random_i[4], out3_3, out3_4);

      assign index_d[0] = out2_1;
      assign index_d[1] = out2_3;
      assign index_d[2] = out3_3;
      assign index_d[3] = out3_4;

      integer i;
      always_ff @ (posedge clk) begin
        if (rst_n == 1'b0) begin
          for (i=0; i<NUM_INPUT; i++) begin
            index_q[i] <= i;
          end
        end else if (next_i == 1'b1) begin
          for (i=0; i<NUM_INPUT; i++) begin
            index_q[i] <= index_d[i];
          end
        end
      end

      genvar j;
      for (j=0; j<NUM_INPUT; j++) begin
        assign index_o[j] = index_q[j];
      end
    end 
    // TODO: support NUM_INPUT = 8
  end

endmodule

module cv32e40p_hwloop_permute_unit #(
  parameter INPUT_WIDTH = 2,
) (
  input logic [INPUT_WIDTH-1:0] a_i,
  input logic [INPUT_WIDTH-1:0] b_i,
  input logic                   s_i,
  input logic [INPUT_WIDTH-1:0] a_o,
  input logic [INPUT_WIDTH-1:0] b_o,
);

  assign a_o = s_i ? b_i : a_i;
  assign b_o = s_i ? a_i : b_i;

endmodule