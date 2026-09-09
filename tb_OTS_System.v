`timescale 1ns/1ps

module tb_OTS_System;

parameter CLK_PERIOD = 10;
parameter NUM_TRIALS = 100;

//----------------------------------------------------
// DUT Signals
//----------------------------------------------------

reg clk;
reg rst_n;
reg start;

wire done;
wire timeout_flag;
wire [9:0] switching_delay;
wire switch_success;

//----------------------------------------------------
// Statistics
//----------------------------------------------------

integer outfile;

integer trial;

integer success_count;
integer timeout_count;

integer total_delay;

// Histogram
integer delay_histogram [0:1023];

integer i;

//----------------------------------------------------
// DUT
//----------------------------------------------------

OTS_Top #(.MEM_FILE("LUT3.4V.mem"))DUT
(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),

    .done(done),
    .timeout_flag(timeout_flag),

    .switching_delay(switching_delay),
    .switch_success(switch_success)
);

//----------------------------------------------------
// Clock Generation
//----------------------------------------------------

initial
begin
    clk = 1'b0;

    forever
        #(CLK_PERIOD/2) clk = ~clk;
end

//----------------------------------------------------
// Reset Task
//----------------------------------------------------

task automatic reset_dut;

begin

    rst_n = 1'b0;
    start = 1'b0;

    repeat(5)
        @(posedge clk);

    rst_n = 1'b1;

    repeat(5)
        @(posedge clk);

end

endtask

//----------------------------------------------------
// One Trial
//----------------------------------------------------

task automatic run_trial;

begin

    //-----------------------------------------------
    // Generate one-clock start pulse
    //-----------------------------------------------

    @(posedge clk);
    start <= 1'b1;

    @(posedge clk);
    start <= 1'b0;

    //-----------------------------------------------
    // Wait for trial completion
    //-----------------------------------------------

    wait(done);

    //-----------------------------------------------
    // IMPORTANT:
    // Wait for the registered statistics result
    //-----------------------------------------------

    @(posedge clk);

    //-----------------------------------------------
    // Move away from the clock edge so that all
    // non-blocking assignments have completed
    //-----------------------------------------------

    #1;

end

endtask

//----------------------------------------------------
// Print and Collect Result
//----------------------------------------------------

task automatic print_result;

begin

    $display("%4d %8d %8d %8d",
             trial,
             switching_delay,
             switch_success,
             timeout_flag);

    //-----------------------------------------------
    // Write result to CSV
    //-----------------------------------------------

    $fwrite(outfile,
            "%0d,%0d,%0d,%0d\n",
            trial,
            switching_delay,
            switch_success,
            timeout_flag);

    //-----------------------------------------------
    // Successful switch
    //-----------------------------------------------

    if(switch_success)
    begin

        success_count = success_count + 1;

        total_delay = total_delay + switching_delay;

        //-------------------------------------------
        // Histogram
        //-------------------------------------------

        if(switching_delay <= 1023)
            delay_histogram[switching_delay] =
            delay_histogram[switching_delay] + 1;

    end

    //-----------------------------------------------
    // Timeout
    //-----------------------------------------------

    else
    begin

        timeout_count = timeout_count + 1;

    end

end

endtask

//----------------------------------------------------
// Main Test Sequence
//----------------------------------------------------

initial
begin

    //-----------------------------------------------
    // Initialize
    //-----------------------------------------------

    clk = 1'b0;
    rst_n = 1'b0;
    start = 1'b0;

    success_count = 0;
    timeout_count = 0;
    total_delay   = 0;

    //-----------------------------------------------
    // Initialize histogram
    //-----------------------------------------------

    for(i = 0; i < 1024; i = i + 1)
        delay_histogram[i] = 0;

    //-----------------------------------------------
    // Open CSV
    //-----------------------------------------------

    outfile = $fopen("Switching_Results_2-8V.csv", "w");

    if(outfile == 0)
    begin

        $display("ERROR: Could not open Switching_Results_2-8V.csv");

        $finish;

    end

    //-----------------------------------------------
    // CSV Header
    //-----------------------------------------------

    $fwrite(outfile,
            "Trial,Delay,Success,Timeout\n");

    //-----------------------------------------------
    // Reset DUT
    //-----------------------------------------------

    reset_dut();

    //-----------------------------------------------
    // Header
    //-----------------------------------------------

    $display("");

    $display("--------------------------------------------------------------");
    $display(" Trial   Delay   Success   Timeout");
    $display("--------------------------------------------------------------");

    //-----------------------------------------------
    // Run Monte Carlo trials
    //-----------------------------------------------

    for(trial = 1;
        trial <= NUM_TRIALS;
        trial = trial + 1)
    begin

        run_trial();

        print_result();

        //-------------------------------------------
        // Allow DUT to return to IDLE
        //-------------------------------------------

        repeat(2)
            @(posedge clk);

    end

    //-----------------------------------------------
    // Final Summary
    //-----------------------------------------------

    $display("");

    $display("================================================");
    $display("          MONTE CARLO SIMULATION SUMMARY");
    $display("================================================");

    $display("Total Trials        = %0d",
             NUM_TRIALS);

    $display("Successful Switches = %0d",
             success_count);

    $display("Timeouts            = %0d",
             timeout_count);

    //-----------------------------------------------
    // Success percentage
    //-----------------------------------------------

    $display("Success Rate        = %0f %%",
             (success_count * 100.0) / NUM_TRIALS);

    //-----------------------------------------------
    // Timeout percentage
    //-----------------------------------------------

    $display("Timeout Rate        = %0f %%",
             (timeout_count * 100.0) / NUM_TRIALS);

    //-----------------------------------------------
    // Average switching delay
    //-----------------------------------------------

    if(success_count > 0)
    begin

        $display("Average Delay       = %0f cycles",
                 total_delay * 1.0 / success_count);

    end

    else
    begin

        $display("Average Delay       = No successful switches");

    end

    //-----------------------------------------------
    // Print histogram
    //-----------------------------------------------

    $display("");
    $display("===============================================");
    $display("        SWITCHING DELAY HISTOGRAM");
    $display("===============================================");

    for(i = 0; i < 1024; i = i + 1)
    begin

        if(delay_histogram[i] > 0)
        begin

            $display("Delay %4d cycles : %6d",
                     i,
                     delay_histogram[i]);

        end

    end

    //-----------------------------------------------
    // Close CSV
    //-----------------------------------------------

    $fclose(outfile);

    $display("");

    $display("Results written to Switching_Results_2-8V.csv");

    $display("");

    $finish;

end

endmodule