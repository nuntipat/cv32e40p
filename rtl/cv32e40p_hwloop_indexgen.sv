
module cv32e40p_hwloop_indexgen #(
  parameter BLOCK_SIZE = 4,
  parameter BLOCK_SIZE_BITS = $clog2(BLOCK_SIZE)
) (
  input logic clk,
  input logic rst_n,
  input logic [31:0] num_iter_i,
  input logic valid_i,
  input logic next_i,
  input logic [31:0] random_i,
  output logic [31:0] index_o
);
  integer i;

  // ..

  logic [31:0] num_iter_q;

  always_ff @ (posedge clk) begin
    if (valid_i == 1'b1) begin
      num_iter_q <= num_iter_i;
    end
  end

  // calculate start offset

  logic [31:0] cnt_mask;
  always_comb @ (*) begin
    cnt_mask[31] = num_iter_i[31];
    for (i = 30; i >= 0; i--) begin
      cnt_mask[i] = cnt_mask[i+1] | num_iter_i[i];
    end
  end

  logic [31:0] random_masked;
  assign random_masked = cnt_mask & random_i;

  logic [32:0] random_masked_minus_cnt;
  assign random_masked_minus_cnt = random_masked - num_iter_i;

  logic [31:0] start_offset;
  assign start_offset = random_masked_minus_cnt[32] ? random_masked : random_masked_minus_cnt;

  // generate permute index

  logic permute_next;
  logic [BLOCK_SIZE-1:0][BLOCK_SIZE_BITS-1:0] permuted_step;

  cv32e40p_hwloop_permuter #(
    .NUM_INPUT(BLOCK_SIZE),
    .INPUT_WIDTH(BLOCK_SIZE_BITS),
    .USE_BRAM(1)
  ) permuter (
    .clk(clk),
    .rst_n(rst_n),
    .next_i(permute_next),
    .random_i(random_i[4:0]),
    .index_o(permuted_step)
  );

  // ..

  logic [31:0] current_offset;
  logic [BLOCK_SIZE_BITS-1:0] step_index;
  
  always_ff @ (posedge clk) begin
    permute_next <= 1'b0;
    if (rst_n == 1'b0) begin
      permute_next <= 1'b1;
    end else if (valid_i == 1'b1) begin
      current_offset <= start_offset;
      step_index <= 0;
    end else if (next_i == 1'b1) begin
      step_index <= step_index + 1;
      if (&step_index == 1'b1) begin
        current_offset <= current_offset + BLOCK_SIZE;
        step_index <= 'd0;
      end
    end
  end

  logic [BLOCK_SIZE_BITS-1:0] current_step;
  assign current_step = permuted_step[step_index];

  logic [31:0] computed_index;
  assign computed_index = current_offset + current_step;

  logic [32:0] computed_index_minus_num_iteration;
  assign computed_index_minus_num_iteration = computed_index - num_iter_q;

  assign index_o = computed_index_minus_num_iteration[32] ? computed_index : computed_index_minus_num_iteration;

endmodule