module sar_top(
  input clk_sar,
  input clk_sample,
  input rst,
  input vcomp,
  output [7:0] q,
  output eoc,
  output busy
);
  
  reg samp_d1, samp_d2;
  wire start_pulse;
  
  // Edge detection
  always @(posedge clk_sar)begin
    if(rst)begin
      samp_d1 <= 1'b0;
      samp_d2 <= 1'b0;
    end else begin 
      samp_d1 <= clk_sample;
      samp_d2<= samp_d1;
    end end 
  assign start_pulse = samp_d1 &~ samp_d2;
  wire init, trial, commit, shift;
  wire done;
  
  sar_fsm u_fsm (
    .clk (clk_sar),
    .rst (rst),
    .start (start_pulse),
    .busy (busy),
    .eoc (eoc),
    .init (init),
    .commit (commit),
    .shift (shift),
    .done (done)
  );
  
  sar_datapath u_datapath(
    .clk	(clk_sar),
    .rst	(rst),
    .init	(init),
    .trial	(trial),
    .commit	(commit),
    .shift	(shift),
    .vcomp	(vcomp),
    .q		(q),
    .done	(done)
  );
  
endmodule

module sar_fsm(
  input	clk,
  input rst,
  input start,
  output busy,
  output eoc, 
  output reg init,
  output reg trial, 
  output reg commit, 
  output reg shift,
  input done
);
  
  localparam S_IDLE = 3'd0;
  localparam S_INIT = 3'd1;
  localparam S_TRIAL = 3'd2;
  localparam S_COMMIT = 3'd3;
  localparam S_SHIFT = 3'd4;
  localparam S_DONE  = 3'd5;
  
  reg [2:0] state, next_state;
  
  assign busy = (state != S_IDLE);
  assign eoc = (state == S_DONE);
  
  always @(*) begin
    init = 1'b0;
    trial = 1'b0;
    commit = 1'b0;
    shift = 1'b0;
    
    next_state = state;
    
    case (state)
      S_IDLE:	if(start) next_state = S_INIT;
      S_INIT:	begin init = 1'b1; next_state = S_TRIAL; end
      S_TRIAL:	begin trial = 1'b1; next_state = S_COMMIT; end
      S_COMMIT: begin
        		commit = 1'b1;
        if(done) next_state = S_DONE;
        else	 next_state = S_SHIFT;
      end
      S_SHIFT: begin shift = 1'b1; next_state = S_TRIAL; end
      S_DONE: next_state = S_IDLE;
      default: next_state = S_IDLE;
    endcase
  end
  
  always @(posedge clk) begin
    if(rst)	state <= S_IDLE;
    else	state <= next_state;
  end
endmodule

module sar_datapath(
  input	clk,
  input	rst,
  input init,
  input trial, 
  input commit,
  input shift,
  input vcomp,
  output reg [7:0] q,
  output done
);
  
  reg [2:0] idx;
  
  assign done = commit && (idx == 3'd0);
  always @(posedge clk)begin
    if (rst) begin
    q <= 8'b0;
    idx <= 3'd7;
  end
    
  else if (init) begin
    q <= 8'b0;
    idx <= 3'd7;
  end
    
    if(trial)begin
      q[idx] <= 1'b1;
    end
    
    else if(commit)begin
      q[idx] <= vcomp ? 1'b1 : 1'b0;
    end
    
    if (shift)begin
      if(idx != 3'd0) begin
        idx <= idx -3'd1;
      end
    end
  end
endmodule