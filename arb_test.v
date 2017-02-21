 /*
 * Author:  Mark A. Indovina
 *          Rochester, NY, USA
 *
 */


`timescale 1ns / 1ns
`define stop(a)\
    begin if (a==1) begin \
    $display("the process is stopped");\
    $stop;end\
    end
module test;

wire dma_grant, tdsp_grant;
wire scan_out0;
reg dma_error, tdsp_error;
reg clk, dma_breq, reset, tdsp_breq;
reg scan_in0, scan_en;
arb top(
        .reset(reset),
        .clk(clk),
        .dma_breq(dma_breq),
        .dma_grant(dma_grant),
        .tdsp_breq(tdsp_breq),
        .tdsp_grant(tdsp_grant),
        .scan_in0(scan_in0),
        .scan_en(scan_en),
        .scan_out0(scan_out0)
    );


reg [4: 0]
    dma_wait,
    tdsp_wait ;

integer
    i,
    j,
    k,
    l,
    x,
    y,
    dma_cnt,
    tdsp_cnt ;

wire
    grant = dma_grant | tdsp_grant ;

initial
begin
    $timeformat( -9, 2, "ns", 16);
`ifdef SDFSCAN

    $sdf_annotate("sdf/arb_tsmc18_scan.sdf", test.top);
`endif

    clk = 1'b0;
    dma_breq = 1'b0;
    reset = 1'b0;
    tdsp_breq = 1'b0;
    scan_in0 = 1'b0;
    scan_en = 1'b0;
    dma_cnt = 0 ;
    tdsp_cnt = 0 ;
    dma_wait = $random ;
    tdsp_wait = $random ;
    dma_error =1'b0;
    tdsp_error=1'b0;
    x=0;
    y=0;

    @(negedge clk)
     reset = 1'b1 ;
    repeat (2)
        @(negedge clk) ;
    @(negedge clk)
     reset = 1'b0 ;
    repeat (2)
        @(posedge clk) ;

    repeat (256)
    begin
        @(posedge clk)
         dma_wait <= $random ;
        tdsp_wait <= $random ;
        fork
            dma_request ;
            tdsp_request ;
        dma_check;
        tdsp_check;
        join
        repeat (4)
            @(posedge clk) ;
    end
    repeat (4)
        @(posedge clk) ;
    if (dma_cnt != tdsp_cnt)
    begin
        $display(" ** Fails simulation!");
        $display(" ** 256 Individual Bus request cycles generated,");
        $display(" ** (#tdsp grants == %d) != (#dma grants == %d)", tdsp_cnt, dma_cnt);
    end
    else
    begin
        $display(" ** Passes simulation!");
        $display(" ** 256 Individual Bus request cycles generated,");
        $display(" ** (#tdsp grants == %d) == (#dma grants == %d)", tdsp_cnt, dma_cnt);
    end
    $stop ;
end

always #20
    clk = ~clk ;

task dma_request ;
    begin
        repeat (dma_wait)
            @(posedge clk) ;
        dma_breq <= 1 ;
        $display("%t DMA Bus Request", $time);
        for (i = 0 ; i < (dma_wait + tdsp_wait + 10) ; i = i + 1)
            @(posedge clk)
             if (dma_grant)
             begin
                 dma_cnt = dma_cnt + 1 ;
                 i = (dma_wait + tdsp_wait + 10) ;
             end
         @(posedge clk)
          dma_breq <= 0 ;
        @(posedge clk);
    end
endtask

task tdsp_request ;
    begin
        repeat (tdsp_wait)
            @(posedge clk) ;
        tdsp_breq <= 1 ;
        $display("%t TDSP Bus Request", $time);
        for (j = 0 ; j < (dma_wait + tdsp_wait + 10) ; j = j + 1)
            @(posedge clk)
             if (tdsp_grant)
             begin
                 tdsp_cnt = tdsp_cnt + 1 ;
                 j = (dma_wait + tdsp_wait + 10) ;
             end
         @(posedge clk)
          tdsp_breq <= 0 ;
        @(posedge clk);
    end
endtask
task dma_check ;
begin
x=0;
@(dma_breq)
begin
    if(tdsp_grant==1)   
        begin   
        @(negedge tdsp_grant)
       
	   for(k=0;k<3;k=k+1)
		begin  
                 @(posedge clk); 
                 if(dma_grant==1)                   
            	  x=x+1;
        end
        if(x==0)
                begin
                            dma_error<=1'b1;
                            $display(" DMA FLAG ERROR is %d",dma_error);
                                 $display("%t simultationtime",$time);
                          `stop(dma_error)
                end
               
                  
          
    end         
end  
end 
 
endtask


task tdsp_check;
begin       
@(posedge tdsp_breq)
    if(dma_grant==1)
	begin
        @(negedge dma_grant);
        for(l=0;l<1;l=l+1)
	begin
	@(posedge clk); 
        if(tdsp_grant==1)
        y=y+1;
	end
       
   
            if(y==0)
                            begin
                            tdsp_error<=1'b1;
                            $display(" tdsp FLAG ERROR is %d",tdsp_error);
                            $display("%t simultationtime",$time);
                            `stop(tdsp_error)
                            end

        
end

 end
endtask

endmodule
