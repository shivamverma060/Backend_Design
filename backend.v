/////////////////////////////////////////////////////////
//////////////////////
/*Backend Model
 * Generates reset signal Amplifier1, Amplifier2 and Oscillator
 * Recieves serial data from FPGA and accordingly sets gain of Amplifiers.
 * Estimates frequency of Oscillator.
*/
module backend( i_resetbAll,
		        i_clk,        
		        i_sclk,       
		        i_sdin,       
		        i_vco_clk,   
		        o_ready,      
		        o_resetb1,    
		        o_gainA1,     
		        o_resetb2,    
		        o_gainA2,     
		        o_resetbvco); 
		
//============================================================================
//Input output declarations		
		
input i_clk;                      // Main clock
input i_sdin;                     // Serial data in to chip
input i_sclk;                     // Serial clock for communication
input i_vco_clk;                  // Oscillator clock 
input i_resetbAll;                // Reset for the chip
output reg o_resetb1;             // Active Low Reset Signal for Amplifier1
output reg o_resetb2;             // Active Low Reset Signal for Amplifier2
output reg o_resetbvco;           // Active Low Reset Signal for Oscillator
output reg o_ready;               // Alerts FPGA that chip is programmed and ready
output reg [1:0] o_gainA1;        // gain of Amplifier1 when serial data is recieved by chip
output reg [2:0] o_gainA2;        // gain of Amplifier2 when serial data is recieved by chip
output reg [6:0] counter_main;    // Counter to count pulse of Main Clock upto 20
output reg [6:0] counter_vco;     // Counter to count pulse of Oscillator Clock till Counter Main counts 20

//===========================================================================

//Internal wire, reg declarations

reg[4:0]tmp;                      // store the serial data
reg [3:0] count;                  // used for counting pulse of Sclk upto 5
reg [4:0] count1;                 // used for delaying 2 clock pulse
reg [4:0] count2;                 // used for delaying 10 clock pulse  
reg [4:0] count3;                 // used for delaying 10 clock pulse

//=============================================================
//BEHAVIORAL DESCRIPTION
//=============================================================
//========================================================
/*resetb1,resetb1,resetb_vco,gainA1,gainA1
 * resetb1=0,resetb1=0,resetb_vco=0 when resetbAll is reset. 
 * gainA1=0, gainA2=0  when resetbAll is reset. 
 * storing serial in data into "tmp" register @ positive edge of sclk.
*/
 
always@(posedge i_sclk,i_resetbAll)

      begin
		
           if(i_resetbAll==0)
		   
               begin
			   
                 tmp<=5'b00000;
                 o_gainA1[0]<=0;
                 o_gainA1[1]<=0;
                 o_gainA2[0]<=0;
                 o_gainA2[1]<=0;
                 o_gainA2[2]<=0;
	             o_resetb1<=0;
	             o_resetb2<=0;
	             o_ready<=0;
				 o_resetbvco<=0;
				 
               end
			   
           else
		   
              begin
			  
                 tmp<={tmp[4:0],i_sdin};
 
 
	           end
      end
	  
//==========================================================
/*count
 * used for updating gain of Amplifier1 and Amplifier 2
 */
	  
 
 always@ (posedge(i_sclk) or negedge(i_resetbAll))

        begin
		
	       if(i_resetbAll == 0)
	
		     count <= 0;
		
		
	      else
	
		     count <= count+1;
		
		

	  end
	  
//==========================================================
/*gainA1,gainA2
 * updating gainA1 and gainA2 when serial data is recieved
 * else gainA1=0, gainA2=0
 */  
	
   always@ (posedge(i_clk))
   
        begin
  
           if(count==5)
		   
                begin
				
	               
	                o_gainA1[0]<=tmp[0];
                    o_gainA1[1]<=tmp[1];
                    o_gainA2[0]<=tmp[2];
                    o_gainA2[1]<=tmp[3];
                    o_gainA2[2]<=tmp[4];
		end
		
		   else
		   
		  begin
		  
            o_gainA1[0]<=0;
            o_gainA1[1]<=0;
            o_gainA2[0]<=0;
            o_gainA2[1]<=0;
            o_gainA2[2]<=0;
			
	       end
       end
	   
	   
 //==========================================================
/*count1
 * used for seting VCO
 */	   
	 always@ (posedge(i_clk))
	 
	  begin
	 
	    if(i_resetbAll==0)
		
		     count1<=0;
			 
	    else		 
	 
	     begin
		 
		    if(count==5 && count1<=1)
			
			   count1<=count1+1;
			   
			 else
                
                count1<=count1;				
			   
		end
        end		
		
		
 //==========================================================
/*count2
 * used for seting Amplifier1 and Amplifier 2
 */			

	always@ (posedge (i_clk))
	
	
	 begin
	
	    if(i_resetbAll==0)
		
		    count2<=0;
			
		else	
	 
	     begin
		 
		    if(count==5 && count1==2 && count2<=9)
			
			   count2<=count2+1;
			   
			else 
                
                count2<=count2;
            end	
			
	end		
	
	
 //==========================================================
/*count3
 * used for seting ready, indicates that the start-up sequence has been completed and the amplifiers within the the chip is ready to be used
 */					
	always@ (posedge (i_clk))
	
	  begin
		
	 if (i_resetbAll==0)
	 
	     count3<=0;
		 
	  else	 
	 
	    begin
		 
		    if (count==5&& count2==10 && count3<=9)
			
			   count3<=count3+1;
			   
			else 
                
                count3<=count3;
        end	
		
	end
	
	
//==========================================================
/*resetbvco
 * set vco after delay of 2 clock pulse when serial data is recieved
 */		

    always@ (posedge (i_clk), i_resetbAll)

        begin
          
		  if(i_resetbAll==0)
		  
		        o_resetbvco<=0;
				
		   else

           begin
		   
             if (count1==2)

                 o_resetbvco<=1;

             end

        end	
		
		
//==========================================================
/*resetb1 and resetb2
 * set Amplifier1 and Amplifier2 after delay of 10 clock pulse after vco is set
 */			

        			
	always@ (posedge (i_clk),i_resetbAll)

        begin
		
		
		    if (i_resetbAll==0)
			
			    begin
				 
                 o_resetb1<=0;
				 o_resetb2<=0;
				 
				end

			else  
			     
				begin
				
                   if (count2==10)

                      begin
				 
                        o_resetb1<=1;
				        o_resetb2<=1;
				 
				      end
					  
				end

            
        end	
		
		
//==========================================================
/*ready
 * set ready after delay of 10 clock pulse when Amplifier1 and Amplifier2 is set.
 */			
		
		
	always@ (posedge (i_clk),i_resetbAll)

        begin
          
		  if (i_resetbAll==0)
		  
		        o_ready<=0;
				
		  else
            
            begin	
			
             if (count3==10)

                 o_ready<=1;

            end    
        end		
		

//==========================================================
/*		         BONUS QUESTION
*/
//==========================================================
/*counter_main
 *counter_main is used for counting pulse of main clock after ready is set till counter_main counts upto 20.
 */	
		 
	always@ (posedge (i_clk),i_resetbAll)

        begin 
		
		  if(i_resetbAll==0)
		     
			  counter_main<=0;	
			  
		   else	  
         
                 if (o_ready==1 && counter_main <=19)
               
                    counter_main<=counter_main+1;
				
                 else
           
                    counter_main<=counter_main;				
        end		
		
//==========================================================
/*counter_vco
 * counter_vco is used for counting pulse of oscillator clock after ready is set till counter_main counts upto 20
 */			

    always@ (posedge (i_vco_clk),i_resetbAll)

        begin 
		
		   if(i_resetbAll==0)
		     
			  counter_vco<=0;	
			  
		   else	  
         
                 if (o_ready==1 && counter_main <=19)
               
                    counter_vco<=counter_vco+1;
				
                 else
           
                    counter_vco<=counter_vco;				
        end	

 endmodule