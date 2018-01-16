module data_selector (
    input          CLK,
    input          RST,
    input   [15:0] DATA_H, DATA_F,
    input   [15:0] DATA01, DATA02, DATA03, DATA04,
    input   [15:0] DATA05, DATA06, DATA07, DATA08,
    input   [15:0] DATA09, DATA10, DATA11, DATA12,
    input   [15:0] DATA13, DATA14, DATA15, DATA16,
    input          MEM_RD_FLAG,
    output   [5:0] MEM_ADDR_OUT,
    output  [31:0] DATA_OUT,
    output         FIFO_WR_EN
);


// Using Memory Write Timing ( it must a few clock later )
reg flag_already_start=1'b0;
reg mem_write_finish_pulse=1'b0;
always @( posedge CLK )
begin
    if ( MEM_RD_FLAG==1'b1 && flag_already_start==1'b0 ) begin
        flag_already_start <= 1'b1;
        mem_write_finish_pulse <= 1'b1;
    end
    else if (MEM_RD_FLAG==1'b1 && flag_already_start==1'b1)  begin
        mem_write_finish_pulse <= 1'b0;
    end
    else begin
        flag_already_start <= 1'b0;
        mem_write_finish_pulse <= 1'b0;
    end 
end


// Mage "reset" signal from "SR_OUT"
reg [5:0] ch_cnt  = 6'h0;
reg [5:0] ad_cnt  = 6'h0;
reg sr_out_rst=1'b1;
always @( posedge CLK )
begin
    //if ( mem_write_finish_pulse && ad_cnt!=6'd47 && ch_cnt!=5'd23)
    if ( mem_write_finish_pulse )
            sr_out_rst <= 1'b1;
    else
            sr_out_rst <= 1'b0;
end
        
        
// Without implement "State Machine", memory access should need to wait the finish timing of writing memories.
// Timing of the Memory Access is shifted as Writing clock = Time(4 MHz*4 clock) = Time(100 MHz*100 clock).    
// Inserting extra reset signal  when "Reset" is issueed. 
//reg [7:0] rst_cnt = 8'h0;
//reg rst = 1'b0;
//always @( posedge CLK )
//begin
//    if ( RST ) begin
//        rst <= 1'b1;
//        rst_cnt <= 8'h0;
//    end
//    else if ( rst_cnt < 8'd100 ) begin
//        rst <= 1'b1;
//        rst_cnt <= rst_cnt + 8'h1;
//    end
//    else
//        rst <= 1'b0;
//end 

// 4MHz 1 clock = 100MHz 25 clocks
// 2MHz 1 clock = 100MHz 50 clocks
//reg [4:0] ch_cnt  = 5'h0;

always @( posedge CLK )
begin
    if ( RST )
        ch_cnt <= 6'h0;
    //else if ( rst == 1'b1 )   // Stop couting while internal reset is High .
    else if (sr_out_rst == 1'b1 )   
        ch_cnt <= 6'h0;
    //else if ( ch_cnt == 5'd24 ) begin
    else if ( ch_cnt == 6'd49 ) begin
        ch_cnt <= 6'h0;
    end
    else
        ch_cnt <= ch_cnt + 6'h1;
end

// Memory Address (== column) Counter 1-48
//reg [5:0] ad_cnt  = 6'h0;
always @( posedge CLK )
begin
    if ( RST )
        ad_cnt <= 6'h0;
    //else if ( rst == 1'b1 )   // Stop couting while internal reset is High .
    else if ( sr_out_rst == 1'b1 )   
        ad_cnt <= 6'h0; 
    else if ( ch_cnt == 6'd49 ) begin
        if ( ad_cnt == 6'd47 ) 
            ad_cnt <= 6'h0;
        else
            ad_cnt <= ad_cnt + 6'h1;
    end
end

// First DFF 
reg [5:0] ch_id;
reg [5:0] ad_id;
reg [15:0] d_header, d_footer;
reg [15:0] d01, d02, d03, d04, d05, d06, d07, d08;
reg [15:0] d09, d10, d11, d12, d13, d14, d15, d16;
always @( posedge CLK )
begin
    ch_id <= ch_cnt;
    ad_id <= ad_cnt;
    
    d_header <= DATA_H;
    d_footer <= DATA_F;
    d01 <= DATA01;  d02 <= DATA02;  d03 <= DATA03;  d04 <= DATA04;
    d05 <= DATA05;  d06 <= DATA06;  d07 <= DATA07;  d08 <= DATA08;
    d09 <= DATA09;  d10 <= DATA10;  d11 <= DATA11;  d12 <= DATA12;
    d13 <= DATA13;  d14 <= DATA14;  d15 <= DATA15;  d16 <= DATA16;    
end

assign MEM_ADDR_OUT = ad_id;

//  Event Header/Event Footer 
reg [31:0] event_header = 32'haaaaaaaa;
reg [31:0] event_footer = 32'hf0f0f0f0;

// Event Number
reg [15:0] event_number = 16'h0;
always @( posedge CLK )
begin
    if ( RST ) begin
        event_number <= 16'h0;
    end
//    else if ( ch_id == 6'h0 && ad_id == 6'h0 )
    else if ( sr_out_rst == 1'b1 )
        event_number <= event_number + 16'h1;
end

// Second DFF for Multiplexer -- dirty writing ! better to replace "generate" & "DFF circuit"
reg [15:0] d1_d01, d1_d02, d1_d03, d1_d04, d1_d05, d1_d06, d1_d07, d1_d08;
reg [15:0] d1_d09, d1_d10, d1_d11, d1_d12, d1_d13, d1_d14, d1_d15, d1_d16;

reg [15:0] d2_d01, d2_d02, d2_d03, d2_d04, d2_d05, d2_d06, d2_d07, d2_d08;
reg [15:0] d2_d09, d2_d10, d2_d11, d2_d12, d2_d13, d2_d14, d2_d15, d2_d16;

reg [15:0] d3_d01, d3_d02, d3_d03, d3_d04, d3_d05, d3_d06, d3_d07, d3_d08;
reg [15:0] d3_d09, d3_d10, d3_d11, d3_d12, d3_d13, d3_d14, d3_d15, d3_d16;

reg [15:0] d4_d01, d4_d02, d4_d03, d4_d04, d4_d05, d4_d06, d4_d07, d4_d08;
reg [15:0] d4_d09, d4_d10, d4_d11, d4_d12, d4_d13, d4_d14, d4_d15, d4_d16;

reg [15:0] d1_d_header, d1_d_footer;
reg [15:0] d2_d_header, d2_d_footer;
reg [15:0] d3_d_header, d3_d_footer;
reg [15:0] d4_d_header, d4_d_footer;
reg [15:0] d5_d_header, d5_d_footer;

reg [31:0] d1_event_header, d1_event_footer;
reg [31:0] d2_event_header, d2_event_footer;
reg [31:0] d3_event_header, d3_event_footer;
reg [31:0] d4_event_header, d4_event_footer;
reg [31:0] d5_event_header, d5_event_footer;

always @( posedge CLK )
begin
    d1_d01 <= d01;  d1_d02 <= d02;  d1_d03 <= d03;  d1_d04 <= d04;
    d1_d05 <= d05;  d1_d06 <= d06;  d1_d07 <= d07;  d1_d08 <= d08;
    d1_d09 <= d09;  d1_d10 <= d10;  d1_d11 <= d11;  d1_d12 <= d12; 
    d1_d13 <= d13;  d1_d14 <= d14;  d1_d15 <= d15;  d1_d16 <= d16;   
    d1_d_footer <= d_footer;    d1_event_footer <= event_footer;
    
    d2_d05 <= d1_d05;  d2_d06 <= d1_d06;  d2_d07 <= d1_d07;  d2_d08 <= d1_d08;
    d2_d09 <= d1_d09;  d2_d10 <= d1_d10;  d2_d11 <= d1_d11;  d2_d12 <= d1_d12; 
    d2_d13 <= d1_d13;  d2_d14 <= d1_d14;  d2_d15 <= d1_d15;  d2_d16 <= d1_d16;   
    d2_d_footer <= d1_d_footer;    d2_event_footer <= d1_event_footer;
    
    d3_d09 <= d2_d09;  d3_d10 <= d2_d10;  d3_d11 <= d2_d11;  d3_d12 <= d2_d12; 
    d3_d13 <= d2_d13;  d3_d14 <= d2_d14;  d3_d15 <= d2_d15;  d3_d16 <= d2_d16;   
    d3_d_footer <= d2_d_footer;    d3_event_footer <= d2_event_footer;
     
    d4_d13 <= d3_d13;  d4_d14 <= d3_d14;  d4_d15 <= d3_d15;  d4_d16 <= d3_d16;     
    d4_d_footer <= d3_d_footer;    d4_event_footer <= d3_event_footer; 
    
    d5_d_footer <= d4_d_footer;    d5_event_footer <= d4_event_footer;
end


// Get Data from Memory Buffers
reg [31:0] data32_pre = 32'h0;
reg [31:0] data32 = 32'h0;
//reg [31:0] data32_pre;
//reg [31:0] data32;
always @( posedge CLK )
begin
    case ( ch_id )
        6'd1  : data32_pre <= event_header;                // multiplexer1
        6'd2  : data32_pre <= { d_header, event_number };
        6'd3  : data32_pre <= { d1_d02, d1_d01 };          // multiplexer2
        6'd4  : data32_pre <= { d1_d04, d1_d03 };
        6'd5  : data32_pre <= { d2_d06, d2_d05 };          // multiplexer3
        6'd6  : data32_pre <= { d2_d08, d2_d07 };
        6'd7  : data32_pre <= { d3_d10, d3_d09 };          // multiplexer4
        6'd8  : data32_pre <= { d3_d12, d3_d11 };
        6'd9  : data32_pre <= { d4_d14, d4_d13 };          // multiplexer5
        6'd10 : data32_pre <= { d4_d16, d4_d15 };
        6'd11 : data32_pre <= { d5_d_footer, 10'h0, ad_id };  // multiplexer6
        //6'd11 : data32_pre <= { d5_d_footer, 2'b00, ad_id };  // multiplexer6
        6'd12 : data32_pre <= d5_event_footer;
        default : data32_pre <= 32'h0;
    endcase
    
    data32 <= data32_pre;
end

assign DATA_OUT = data32;

// FIFO Write Enable
reg wr_en_pre = 1'b0;
reg wr_en = 1'b0;
always @( posedge CLK )
begin
    if ( ad_id == 6'h0 ) begin
        if ( ch_id >= 6'd1 && ch_id <= 6'd11)
            wr_en_pre <= 1'b1;
        else
            wr_en_pre <= 1'b0;
    end
    else if ( ad_id == 6'd47 ) begin
        if ( ch_id >= 6'd2 && ch_id <= 6'd12)
            wr_en_pre <= 1'b1;
        else
            wr_en_pre <= 1'b0;
    end
    else begin
        if ( ch_id >= 6'd2 && ch_id <= 6'd11)
            wr_en_pre <= 1'b1;
        else
            wr_en_pre <= 1'b0;    
    end
    
    wr_en <= wr_en_pre;
end

assign FIFO_WR_EN = wr_en;


endmodule



