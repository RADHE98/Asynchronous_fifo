	module async_fifo(wclk,rclk,w_en,r_en,wrst,rrst,data_in,data_out,full,empty);
	input wclk,rclk,wrst,rrst,w_en,r_en;
	input [7:0]data_in;
	output reg [7:0]data_out;
	output full,empty;

	reg [3:0]w_ptr_b,w_ptr_g_sync_1,w_ptr_g_sync_final;
	wire[3:0]w_ptr_b_sync_final,w_ptr_g;
	reg [3:0]r_ptr_b,r_ptr_g_sync_1,r_ptr_g_sync_final;
	wire[3:0]r_ptr_b_sync_final,r_ptr_g;
	reg [7:0]mem[8];
	wire MSB;



	//--binary code to gray code--//
	assign w_ptr_g = w_ptr_b^(w_ptr_b>>1);

	assign r_ptr_g = r_ptr_b^(r_ptr_b>>1);


	// write logic //

	always@(posedge wclk or negedge wrst )
	begin
	if (!wrst)
	begin
	w_ptr_b <= 0;
	end
	else if (w_en && !full)
	begin 
	mem[w_ptr_b[2:0]]<=data_in;

	w_ptr_b <= w_ptr_b+1;

	end
	end


	// read logic //
	always@(posedge rclk or negedge rrst )
	begin
	if (!rrst)
	begin
	r_ptr_b <= 0;
	data_out <= 0;
	end
	else if (r_en && !empty)
	begin 
	data_out<=mem[r_ptr_b[2:0]];

	r_ptr_b <= r_ptr_b+1;

	end
	end



	/////////////////////CLOCK DOMAIN CROSSING//////////////////////////////

	//2 D-Flipflops for reduced metastability in clock domain crossing from READ DOMAIN to WRITE DOMAIN

	always@(posedge wclk or posedge wrst)
	begin 
	r_ptr_g_sync_1 <= r_ptr_g;

	r_ptr_g_sync_final <= r_ptr_g_sync_1;

	end

	//2 D-Flipflops for reduced metastability in clock domain crossing from WRITE DOMAIN to READ DOMAIN

	always@(posedge rclk or posedge rrst)
	begin 
	w_ptr_g_sync_1 <= w_ptr_g;

	w_ptr_g_sync_final <= w_ptr_g_sync_1;
	end


	//--gray code to binary code--//
	assign w_ptr_b_sync_final = w_ptr_g_sync_final ^ (w_ptr_g_sync_final >> 1) ^ (w_ptr_g_sync_final >> 2) ^ (w_ptr_g_sync_final >> 3);

	assign r_ptr_b_sync_final = r_ptr_g_sync_final ^ (r_ptr_g_sync_final >> 1) ^ (r_ptr_g_sync_final >> 2) ^ (r_ptr_g_sync_final >> 3);



	assign MSB = w_ptr_b[3]^r_ptr_b_sync_final[3];
	assign full = MSB & (w_ptr_b[2:0] == r_ptr_b_sync_final[2:0]);

	assign empty = (w_ptr_b_sync_final == r_ptr_b) ;

	endmodule 

