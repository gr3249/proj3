module arb (
           reset,
           clk,
           dma_breq,
           dma_grant,
           tdsp_breq,
           tdsp_grant,
           scan_in0,
           scan_en,
           scan_out0
       );
          
input
    reset,                       // system reset
    clk,                         // system clock
    dma_breq,                    // dma controller bus request
    tdsp_breq ;                 // tdsp bus request

output
    dma_grant,                   // dma controller bus grant
    tdsp_grant ;                // tdsp bus grant

input
    scan_in0,                    // test scan mode data input
    scan_en;                    // test scan mode enable

output
    scan_out0;                  // test scan mode data output




//
// explicit state machine states
//
`include "./include/arb.h"     
reg dma_grant;
reg tdsp_grant;
reg[2:0]presentstate;

always @(posedge clk or posedge reset)
begin
if(reset)
begin presentstate <= `ARB_IDLE;
dma_grant<=1'b0;
tdsp_grant<=1'b0; 
end

else
	begin
case(presentstate)
      `ARB_IDLE:
      begin
	      
	 if((dma_breq==1) && (tdsp_breq==1))   	
	begin		
	presentstate<= `ARB_GRANT_TDSP;
	tdsp_grant<=1;
	dma_grant <= 0;
	end
          else if((dma_breq==1) &&(tdsp_breq==0))
	begin	
	
	presentstate<= `ARB_GRANT_DMA;
	dma_grant<=1; 
	tdsp_grant <= 0;
	end
	else if((dma_breq==0 && tdsp_breq==1))
	begin
    	presentstate<= `ARB_GRANT_TDSP;
	dma_grant<=1; 
	tdsp_grant <= 0;    
	    end
    end
     `ARB_GRANT_DMA:
      begin
         dma_grant<=1;
	 tdsp_grant<=0;
        
       if(dma_breq==0)
	begin	
		dma_grant<=0;
		tdsp_grant<=1;
          presentstate<=`ARB_CLEAR;
      end
    end
    `ARB_GRANT_TDSP:
      begin
          tdsp_grant<=1;
	   dma_grant<=0;
        if(tdsp_breq==0)
		begin		
		tdsp_grant<=1;
		dma_grant <= 0 ;
          presentstate<=`ARB_CLEAR;
      end
    end
    `ARB_CLEAR:
    begin
	dma_grant<= 0;
	tdsp_grant<= 1;         
	if((tdsp_breq==1) && (dma_breq==1))          
	begin            
	presentstate<=`ARB_GRANT_TDSP;
	tdsp_grant <= 1;
	dma_grant <= 0;
	end
        else if((dma_breq==1) && (tdsp_breq==0))	
	begin	
	presentstate<=`ARB_DMA_PRI;
        dma_grant<=0;
	tdsp_grant<=0;
	end
	else if((tdsp_breq ==1) && (dma_breq==0))
	begin	presentstate<=`ARB_GRANT_TDSP;
	tdsp_grant <= 1;
	dma_grant <= 0;
	end
	else if((dma_breq==0) && (tdsp_breq==0))
	begin	
	presentstate<= `ARB_CLEAR; 
	dma_grant<= 0;
	tdsp_grant<=1;  
	end
	

end
   
     `ARB_DMA_PRI:
     begin
	 
	if((dma_breq==1) && (tdsp_breq==1))
       begin presentstate<=`ARB_GRANT_DMA;
	dma_grant <= 1 ;
	tdsp_grant <= 0; end
     else if((dma_breq==0) && (tdsp_breq==1))
     begin   presentstate<=`ARB_GRANT_TDSP;
	dma_grant <= 0 ;
	tdsp_grant <= 1; end
     else if((dma_breq==1) && (tdsp_breq==0))	
	begin	
	   
	presentstate<=`ARB_GRANT_DMA;
	dma_grant <= 1 ;
	tdsp_grant <= 0;	
	end     
	else begin
       presentstate	<= `ARB_IDLE;
	dma_grant <= 0 ;
	tdsp_grant <= 0; end
	end


	default:
	presentstate <=`ARB_IDLE;
endcase
end
end
endmodule

