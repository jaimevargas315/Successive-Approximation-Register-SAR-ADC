module tb_sar;
  reg clk_sar;
  reg clk_sample;
  reg rst;
  
  real vin;
  real VREF = 1.0;
  
  wire [7:0] q;
  wire busy;
  wire eoc;
  wire vcomp;
  
  wire[7:0] vin_scaled;
  assign vin_scaled = vin * 256;

  

  
  sar_top dut(
    .clk_sar(clk_sar),
    .clk_sample(clk_sample),
    .rst(rst),
    .vcomp(vcomp),
    .q(q),
    .busy(busy),
    .eoc(eoc)
  );
  
  assign vcomp = (vin >= (VREF * q / 256.0)) ? 1'b1 : 1'b0;
  
  always #2 clk_sar = ~clk_sar;
  
  initial begin 
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_sar);
    
    clk_sar = 0;
    clk_sample = 0;
    vin = 0.45;
    
    rst = 1;
    repeat(5) @(posedge clk_sar);
    rst = 0;
    
    //start pulse
    
    @(posedge clk_sar);
    clk_sample = 1;
    @(posedge clk_sar);
    clk_sample = 0;
    
    #200 $finish;
  end
  
endmodule