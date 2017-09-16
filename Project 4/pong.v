/*  Lab 4
    Pong Game
    
    Final Project - Pong Game using FPGA board and VGA for Display.
    
    Brandon Tai, Fnu Shiva Sandesh, Junyoung Kim */

module pong (
	input wire pix_en,		//pixel clock: 25MHz
	input wire clk,			//100MHz
	input wire rst,			//asynchronous reset
    input wire up,
    input wire down,
    input wire pause,
	output wire hsync,		//horizontal sync out
	output wire vsync,		//vertical sync out
	output reg [2:0] red,	//red vga output
	output reg [2:0] green, //green vga output
	output reg [1:0] blue,	//blue vga output
    output reg [0:3] AN, // OUTPUT: LED number selector, (least significant -> most significant) ==> (AN[0] -> AN[3])
    output reg [0:7] C  // OUTPUT: 7-segment individual segment selector, (CA, CB, CC, CD, CE, CF, CG, DP) ==> (C[0], C[1], ..., C[6], C[7])
	);

// video structure constants
parameter hpixels = 800;// horizontal pixels per line
parameter vlines = 521; // vertical lines per frame
parameter hpulse = 96; 	// hsync pulse length
parameter vpulse = 2; 	// vsync pulse length
parameter hbp = 144; 	// end of horizontal back porch
parameter hfp = 784; 	// beginning of horizontal front porch
parameter vbp = 31; 	// end of vertical back porch
parameter vfp = 511; 	// beginning of vertical front porch
// active horizontal video is therefore: 784 - 144 = 640
// active vertical video is therefore: 511 - 31 = 480

parameter wall_height = 10;
parameter wall_width = 15;

parameter board_width = 15;
parameter board_height = 50;
parameter board_minY = vbp + wall_height;
parameter board_maxY = vfp - wall_height - board_height;

parameter ball_width = 10;
parameter ball_height = 10;
parameter ball_minX = hbp;
parameter ball_maxX = hfp - wall_width - ball_width;
parameter ball_minY = vbp + wall_height;
parameter ball_maxY = vfp - wall_height - ball_height;
parameter ball_startX = 464;
parameter ball_startY = 271;

//------------------------------------------------------
parameter ball_1_width = 10;
parameter ball_1_height = 10;
parameter ball_1_minX = hbp;
parameter ball_1_maxX = hfp - wall_width - ball_1_width;
parameter ball_1_minY = vbp + wall_height;
parameter ball_1_maxY = vfp - wall_height - ball_1_height;
parameter ball_1_startX = 464;
parameter ball_1_startY = 271; 
parameter ball_startspdX = 3;
parameter ball_startspdY = 3;
parameter startLives = 3;
parameter two_ball_score = 5;

reg ball_1_dirX = 1;
reg ball_1_dirY = 0;

reg [4:0] ball_1_spdX = ball_startspdX;
reg [4:0] ball_1_spdY = ball_startspdY;
reg [9:0] ball_1_posX = ball_startX;
reg [9:0] ball_1_posY = ball_startY;

//------------------------------------------------------

reg [0:18] COUNT_256Hz = 19'b0; // Convert 100 MHz -> 256 Hz ==> 1011111010111100001
reg CLK_256Hz = 1'b0;  // 256 Hz

reg [0:1] digit_select;

reg [0:1] random = 2'b0;

reg [3:0] cur_score = 0;

reg gameover = 0;
reg paused = 1;
reg pause_debounce = 0;

reg score_debounce = 0;

reg [3:0] score_ones = 3'b0;
reg [3:0] score_tens = 3'b0;
reg [3:0] lives = startLives;

reg [20:0] counter = 0;

reg [4:0] board_spdY = 3;

reg [9:0] board_posY = board_minY;

reg [9:0] ball_posX = ball_startX;
reg [9:0] ball_posY = ball_startY;

reg ball_dirX = 1;
reg ball_dirY = 0;

reg [4:0] ball_spdX = ball_startspdX;
reg [4:0] ball_spdY = ball_startspdY;

parameter obs1_startposX = 470;
parameter obs1_startposY = 340;

reg [9:0] obs1_posX = obs1_startposX;
reg [9:0] obs1_posY = obs1_startposY;
parameter obs1_height = 70;
parameter obs1_width = 70;
parameter obs1_edgeheight = 4;
parameter obs1_edgewidth = 4;


// registers for storing the horizontal & vertical counters
reg [9:0] hc;
reg [9:0] vc;

// Horizontal & vertical counters --
// this is how we keep track of where we are on the screen.
// ------------------------
// Sequential "always block", which is a block that is
// only triggered on signal transitions or "edges".
// posedge = rising edge  &  negedge = falling edge
// Assignment statements can only be used on type "reg" and need to be of the "non-blocking" type: <=
always @(posedge clk)
begin

	if (rst == 1) begin
		ball_posX = ball_startX;
		ball_posY = ball_startY;
		ball_1_posX = ball_startX;
		ball_1_posY = ball_startY;
		counter = 1;
		ball_spdX = ball_startspdX;
		ball_spdY = ball_startspdY;
		ball_dirX = 1;
		ball_dirY = 0;
		ball_1_spdX = ball_startspdX;
		ball_1_spdY = ball_startspdY;
		ball_1_dirX = 1;
		ball_1_dirY = 0;
        board_spdY = 3;
		paused = 1;
		gameover = 0;
		random = 0;
		cur_score = 0;
		score_ones = 0;
		score_tens = 0;
		lives = startLives;
	end

    if (counter == 20'b0) begin // Game Tick
    
        if (up == 1 && down == 0 && board_posY > board_minY) begin
            board_posY = board_posY - board_spdY;
        end else if (up == 0 && down == 1 && board_posY < board_maxY) begin
            board_posY = board_posY + board_spdY;
        end
        
        if (board_posY < board_minY) begin
            board_posY = board_minY;
        end else if (board_posY > board_maxY) begin
            board_posY = board_maxY;
        end
        if (ball_posX < ball_minX) begin // TEMPORARY Left Wall Collision
            if (lives > 0) begin
                lives = lives - 1;
                ball_posX = ball_startX;
                ball_posY = ball_startY;
                ball_1_posX = ball_startX;
                ball_1_posY = ball_startY;
            end else begin
                gameover = 1;
            end
                cur_score = 0;
                counter = 1;
                ball_spdX = ball_startspdX;
                ball_spdY = ball_startspdY;
                ball_dirX = 1;
                ball_dirY = 0;
                board_spdY = 2;
                paused = 1;
        end else if ( ball_posX <= (ball_minX + board_width) && 
                      ball_posY > (board_posY - ball_height) && 
                      ball_posY < (board_posY + board_height + ball_height) && 
                      score_debounce == 0)
        begin
            score_debounce = 1;
            ball_dirX = 1;
            if (random == 2'b11) begin
                ball_spdY = ball_spdY + 1;
                board_spdY = board_spdY + 1;
            end else if (random < 2) begin
                ball_spdX = ball_spdX + 1;
                board_spdY = board_spdY + 1;
            end
            random = random + 1;
            if (score_ones == 9) begin
                    
                if (score_tens != 9) begin
                    score_tens = score_tens + 1;
                    score_ones = 3'b0;
                end
                    
            end else begin
                score_ones = score_ones + 1;
            end
			if (cur_score < 15) begin
				cur_score = cur_score + 1;
			end
            if (cur_score == two_ball_score) begin
                ball_1_posX = ball_posX;
                ball_1_posY = ball_posY;
                ball_1_spdX = ball_spdX - 2;
                ball_1_spdY = ball_spdY - 2;
                ball_1_dirX = 1;
                ball_1_dirY = ~ball_dirY;
            end
        end else begin
            score_debounce = 0;
        end
        
        if (ball_posX > ball_maxX) begin // Right Wall Collision
            ball_dirX = 0;
        end
        
        if (ball_posY < ball_minY) begin // Top Wall Collision
            ball_dirY = 1;
        end
        
        if (ball_posY > ball_maxY) begin // Bottom Wall Collision
            ball_dirY = 0;
        end
        
        if          (ball_posX >= obs1_posX-8 && ball_posX < (obs1_posX + obs1_edgewidth) && 
                     ball_posY >= obs1_posY && ball_posY <= (obs1_posY + obs1_height)) begin                     // Obstacle 1 Left Collision
            ball_dirX = 0;
        end else if (ball_posX > (obs1_posX + obs1_width - obs1_edgewidth) && ball_posX <= (obs1_posX + obs1_width) && 
                     ball_posY >= obs1_posY && ball_posY <= (obs1_posY + obs1_height)) begin                     // Obstacle 1 Right Collision
            ball_dirX = 1;
        end else if (ball_posX >= obs1_posX && ball_posX <= (obs1_posX + obs1_width) &&                          // Obstacle 1 Top Collision
                     ball_posY >= obs1_posY-8 && ball_posY < (obs1_posY + obs1_edgeheight)) begin
            ball_dirY = 0;
        end else if (ball_posX >= obs1_posX && ball_posX <= (obs1_posX + obs1_width) &&                          // Obstacle 1 Bottom Collision
                     ball_posY > (obs1_posY + obs1_height - obs1_edgeheight) && ball_posY <= (obs1_posY + obs1_height)) begin
            ball_dirY = 1;
        end
        
        if (ball_dirX == 1) begin
            ball_posX = ball_posX + ball_spdX;
        end else begin
            ball_posX = ball_posX - ball_spdX;
        end
        
        if (ball_dirY == 1) begin
            ball_posY = ball_posY + ball_spdY;
        end else begin
            ball_posY = ball_posY - ball_spdY;
        end
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		if (ball_1_posX < ball_minX) begin // TEMPORARY Left Wall Collision
		if (lives > 0) begin
			lives = lives - 1;
			ball_posX = ball_startX;
			ball_posY = ball_startY;
			ball_1_posX = ball_startX;
			ball_1_posY = ball_startY;
		end else begin
			gameover = 1;
		end
            cur_score = 0;
			counter = 1;
			ball_spdX = ball_startspdX;
			ball_spdY = ball_startspdY;
			ball_dirX = 1;
			ball_dirY = 0;
            board_spdY = 3;
			paused = 1;
		end else if ( ball_1_posX <= (ball_minX + board_width) && 
					  ball_1_posY > (board_posY - ball_height) && 
					  ball_1_posY < (board_posY + board_height + ball_height) &&
                      score_debounce == 0)
		begin
            score_debounce = 1;
			ball_1_dirX = 1;
            if (random == 2'b11) begin
                ball_1_spdY = ball_1_spdY + 1;
                board_spdY = board_spdY + 1;
            end else if (random < 2) begin
                ball_1_spdX = ball_1_spdX + 1;
                board_spdY = board_spdY + 1;
            end
			random = random + 1;
			if (score_ones == 9) begin
					
				if (score_tens != 9) begin
					score_tens = score_tens + 1;
					score_ones = 3'b0;
				end
					
			end else begin
				score_ones = score_ones + 1;
			end
		end else begin
            score_debounce = 0;
        end
		
		if (ball_1_posX > ball_maxX) begin // Right Wall Collision
			ball_1_dirX = 0;
		end
		
		if (ball_1_posY < ball_minY) begin // Top Wall Collision
			ball_1_dirY = 1;
		end
		
		if (ball_1_posY > ball_maxY) begin // Bottom Wall Collision
			ball_1_dirY = 0;
		end
        
        if          (ball_1_posX >= obs1_posX-8 && ball_1_posX < (obs1_posX + obs1_edgewidth) && 
                     ball_1_posY >= obs1_posY && ball_1_posY <= (obs1_posY + obs1_height)) begin                     // Obstacle 1 Left Collision
            ball_1_dirX = 0;
        end else if (ball_1_posX > (obs1_posX + obs1_width - obs1_edgewidth) && ball_1_posX <= (obs1_posX + obs1_width) && 
                     ball_1_posY >= obs1_posY && ball_1_posY <= (obs1_posY + obs1_height)) begin                     // Obstacle 1 Right Collision
            ball_1_dirX = 1;
        end else if (ball_1_posX >= obs1_posX && ball_1_posX <= (obs1_posX + obs1_width) &&                          // Obstacle 1 Top Collision
                     ball_1_posY >= obs1_posY-8 && ball_1_posY < (obs1_posY + obs1_edgeheight)) begin
            ball_1_dirY = 0;
        end else if (ball_1_posX >= obs1_posX && ball_1_posX <= (obs1_posX + obs1_width) &&                          // Obstacle 1 Bottom Collision
                     ball_1_posY > (obs1_posY + obs1_height - obs1_edgeheight) && ball_1_posY <= (obs1_posY + obs1_height)) begin
            ball_1_dirY = 1;
        end
            
        if (cur_score >= two_ball_score) begin
            if (ball_1_dirX == 1) begin
                ball_1_posX = ball_1_posX + ball_1_spdX;
            end else begin
                ball_1_posX = ball_1_posX - ball_1_spdX;
            end
            
            if (ball_1_dirY == 1) begin
                ball_1_posY = ball_1_posY + ball_1_spdY;
            end else begin
                ball_1_posY = ball_1_posY - ball_1_spdY;
            end
        end 
        //++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    end
    
    
    if (pause == 1 && pause_debounce == 0) begin
        if (paused == 0) begin
            paused = 1;
            counter = 1;
        end else begin
            paused = 0;
        end
        pause_debounce = 1;
    end else if (pause == 0) begin
        pause_debounce = 0;
    end
    
    if (paused == 0 && gameover == 0) begin
        counter = counter + 1;
    end
    else begin
        counter = 1;
    end

	// reset condition
	if (rst == 1)
	begin
		hc <= 0;
		vc <= 0;
	end
	else if (pix_en == 1)
	begin
		// keep counting until the end of the line
		if (hc < hpixels - 1)
			hc <= hc + 1;
		else
		// When we hit the end of the line, reset the horizontal
		// counter and increment the vertical counter.
		// If vertical counter is at the end of the frame, then
		// reset that one too.
		begin
			hc <= 0;
			if (vc < vlines - 1)
				vc <= vc + 1;
			else
				vc <= 0;
		end
		
	end
    
    if (COUNT_256Hz == 19'b1111010000100100) begin // 256 Hz Clock generation
        CLK_256Hz = ~CLK_256Hz;
        COUNT_256Hz = 19'b0;
    end else begin
        COUNT_256Hz = COUNT_256Hz + 1;
    end
    
end

always @(posedge(CLK_256Hz)) begin
    
    case (digit_select)
    
    2'b00 : begin // score_ones
        AN = 4'b0111;
        C = numToDisplay(score_ones); 
    end
    
    2'b01 : begin // score_tens
        AN = 4'b1011;
        C = numToDisplay(score_tens);
    end
    
    2'b10 : begin
        AN = 4'b1111;
    end
    
    2'b11 : begin // lives
        AN = 4'b1110;
        C = numToDisplay(lives);
    end
    
    endcase
    
    digit_select = digit_select + 1;

end

// generate sync pulses (active low)
// ----------------
// "assign" statements are a quick way to
// give values to variables of type: wire
assign hsync = (hc < hpulse) ? 0:1;
assign vsync = (vc < vpulse) ? 0:1;

// display 100% saturation colorbars
// ------------------------
// Combinational "always block", which is a block that is
// triggered when anything in the "sensitivity list" changes.
// The asterisk implies that everything that is capable of triggering the block
// is automatically included in the sensitivty list.  In this case, it would be
// equivalent to the following: always @(hc, vc)
// Assignment statements can only be used on type "reg" and should be of the "blocking" type: =
always @(*)
begin
	// first check if we're within vertical active video range
	if (vc >= vbp && vc < vfp && hc >= hbp && hc < hfp)
	begin
		// now display different colors every 80 pixels
		// while we're within the active horizontal range
		// -----------------
		// display green wall
		if ((hc >= (hfp - wall_width) && hc < hfp) || ((vc >= vbp && vc < (vbp + wall_height)) || (vc >= (vfp - wall_height) && vc < vfp)))
		begin
			red = 3'b000;
			green = 3'b111;
			blue = 2'b00;
		end
        
        // display ball
        // color - yellow 
        else if (vc >= ball_posY && vc < (ball_posY + ball_height) && hc >= ball_posX && hc < (ball_posX + ball_width))
		begin
			red = 3'b111;
			green = 3'b111;
			blue = 2'b00;
		end
        else if(cur_score >= two_ball_score && vc >= ball_1_posY && vc < (ball_1_posY + ball_height) && hc >= ball_1_posX && hc < (ball_1_posX + ball_width)) 
		begin
			red = 3'b111;
			green = 3'b000;
			blue = 2'b11;
		end
        
        // display obstacle 1
        else if (vc >= obs1_posY && vc < (obs1_posY + obs1_height) && hc >= obs1_posX && hc < (obs1_posX + obs1_width))
        begin
			red = 3'b000;
			green = 3'b111;
			blue = 2'b00;
        end
        
        // PONG GAME text
        else if ((vc>=131 && vc<136 && hc>=234 && hc<239) || (vc>=126 && vc<131 && hc>=234 && hc<239) || (vc>=121 && vc<126 && hc>=234 && hc<239) || 
                 (vc>=116 && vc<121 && hc>=234 && hc<239) || (vc>=111 && vc<116 && hc>=234 && hc<239) || (vc>=106 && vc<111 && hc>=234 && hc<239) || 
                 (vc>=101 && vc<106 && hc>=234 && hc<239) || (vc>=96  && vc<101 && hc>=234 && hc<239) || (vc>=91  && vc<96  && hc>=234 && hc<239) || 
                 (vc>=86  && vc<91  && hc>=234 && hc<239) || (vc>=81  && vc<86  && hc>=234 && hc<239) || (vc>=81  && vc<86  && hc>=239 && hc<244) || 
                 (vc>=81  && vc<86  && hc>=244 && hc<249) || (vc>=81  && vc<86  && hc>=249 && hc<254) || (vc>=81  && vc<86  && hc>=254 && hc<259) || 
                 (vc>=86  && vc<91  && hc>=259 && hc<264) || (vc>=86  && vc<91  && hc>=254 && hc<259) || (vc>=91  && vc<96  && hc>=254 && hc<259) || 
                 (vc>=91  && vc<96  && hc>=259 && hc<264) || (vc>=96  && vc<101 && hc>=259 && hc<264) || (vc>=96  && vc<101 && hc>=254 && hc<259) || 
                 (vc>=101 && vc<106 && hc>=254 && hc<259) || (vc>=101 && vc<106 && hc>=249 && hc<254) || (vc>=101 && vc<106 && hc>=244 && hc<249) || 
                 (vc>=101 && vc<106 && hc>=239 && hc<244) || (vc>=81  && vc<86  && hc>=274 && hc<279) || (vc>=86  && vc<91  && hc>=274 && hc<279) || 
                 (vc>=91  && vc<96  && hc>=274 && hc<279) || (vc>=96  && vc<101 && hc>=274 && hc<279) || (vc>=101 && vc<106 && hc>=274 && hc<279) || 
                 (vc>=106 && vc<111 && hc>=274 && hc<279) || (vc>=111 && vc<116 && hc>=274 && hc<279) || (vc>=116 && vc<121 && hc>=274 && hc<279) || 
                 (vc>=121 && vc<126 && hc>=274 && hc<279) || (vc>=126 && vc<131 && hc>=274 && hc<279) || (vc>=81  && vc<86  && hc>=279 && hc<284) || 
                 (vc>=81  && vc<86  && hc>=284 && hc<289) || (vc>=81  && vc<86  && hc>=289 && hc<294) || (vc>=81  && vc<86  && hc>=294 && hc<299) || 
                 (vc>=81  && vc<86  && hc>=299 && hc<304) || (vc>=86  && vc<91  && hc>=299 && hc<304) || (vc>=91  && vc<96  && hc>=299 && hc<304) || 
                 (vc>=96  && vc<101 && hc>=299 && hc<304) || (vc>=101 && vc<106 && hc>=299 && hc<304) || (vc>=106 && vc<111 && hc>=299 && hc<304) || 
                 (vc>=111 && vc<116 && hc>=299 && hc<304) || (vc>=116 && vc<121 && hc>=299 && hc<304) || (vc>=121 && vc<126 && hc>=299 && hc<304) || 
                 (vc>=126 && vc<131 && hc>=299 && hc<304) || (vc>=131 && vc<136 && hc>=274 && hc<279) || (vc>=131 && vc<136 && hc>=279 && hc<284) || 
                 (vc>=131 && vc<136 && hc>=284 && hc<289) || (vc>=131 && vc<136 && hc>=289 && hc<294) || (vc>=131 && vc<136 && hc>=294 && hc<299) || 
                 (vc>=131 && vc<136 && hc>=299 && hc<304) || (vc>=86  && vc<91  && hc>=314 && hc<319) || (vc>=91  && vc<96  && hc>=314 && hc<319) || 
                 (vc>=96  && vc<101 && hc>=314 && hc<319) || (vc>=101 && vc<106 && hc>=314 && hc<319) || (vc>=106 && vc<111 && hc>=314 && hc<319) || 
                 (vc>=111 && vc<116 && hc>=314 && hc<319) || (vc>=116 && vc<121 && hc>=314 && hc<319) || (vc>=121 && vc<126 && hc>=314 && hc<319) || 
                 (vc>=126 && vc<131 && hc>=314 && hc<319) || (vc>=131 && vc<136 && hc>=314 && hc<319) || (vc>=81  && vc<86  && hc>=314 && hc<319) || 
                 (vc>=81  && vc<86  && hc>=339 && hc<344) || (vc>=86  && vc<91  && hc>=339 && hc<344) || (vc>=91  && vc<96  && hc>=339 && hc<344) || 
                 (vc>=96  && vc<101 && hc>=339 && hc<344) || (vc>=101 && vc<106 && hc>=339 && hc<344) || (vc>=106 && vc<111 && hc>=339 && hc<344) || 
                 (vc>=111 && vc<116 && hc>=339 && hc<344) || (vc>=116 && vc<121 && hc>=339 && hc<344) || (vc>=121 && vc<126 && hc>=339 && hc<344) || 
                 (vc>=126 && vc<131 && hc>=339 && hc<344) || (vc>=131 && vc<136 && hc>=339 && hc<344) || (vc>=96  && vc<101 && hc>=324 && hc<329) || 
                 (vc>=121 && vc<126 && hc>=334 && hc<339) || (vc>=116 && vc<121 && hc>=329 && hc<334) || (vc>=111 && vc<116 && hc>=329 && hc<334) || 
                 (vc>=91  && vc<96  && hc>=319 && hc<324) || (vc>=101 && vc<106 && hc>=324 && hc<329) || (vc>=106 && vc<111 && hc>=329 && hc<334) || 
                 (vc>=106 && vc<111 && hc>=324 && hc<329) || (vc>=81  && vc<86  && hc>=354 && hc<359) || (vc>=86  && vc<91  && hc>=354 && hc<359) || 
                 (vc>=91  && vc<96  && hc>=354 && hc<359) || (vc>=96  && vc<101 && hc>=354 && hc<359) || (vc>=101 && vc<106 && hc>=354 && hc<359) || 
                 (vc>=106 && vc<111 && hc>=354 && hc<359) || (vc>=111 && vc<116 && hc>=354 && hc<359) || (vc>=116 && vc<121 && hc>=354 && hc<359) || 
                 (vc>=126 && vc<131 && hc>=354 && hc<359) || (vc>=131 && vc<136 && hc>=354 && hc<359) || (vc>=121 && vc<126 && hc>=354 && hc<359) || 
                 (vc>=131 && vc<136 && hc>=359 && hc<364) || (vc>=131 && vc<136 && hc>=364 && hc<369) || (vc>=131 && vc<136 && hc>=369 && hc<374) || 
                 (vc>=131 && vc<136 && hc>=374 && hc<379) || (vc>=131 && vc<136 && hc>=379 && hc<384) || (vc>=131 && vc<136 && hc>=384 && hc<389) || 
                 (vc>=126 && vc<131 && hc>=384 && hc<389) || (vc>=121 && vc<126 && hc>=384 && hc<389) || (vc>=111 && vc<116 && hc>=369 && hc<374) || 
                 (vc>=111 && vc<116 && hc>=374 && hc<379) || (vc>=111 && vc<116 && hc>=379 && hc<384) || (vc>=111 && vc<116 && hc>=384 && hc<389) || 
                 (vc>=116 && vc<121 && hc>=384 && hc<389) || (vc>=81  && vc<86  && hc>=359 && hc<364) || (vc>=81  && vc<86  && hc>=364 && hc<369) || 
                 (vc>=81  && vc<86  && hc>=369 && hc<374) || (vc>=81  && vc<86  && hc>=374 && hc<379) || (vc>=81  && vc<86  && hc>=384 && hc<389) || 
                 (vc>=81  && vc<86  && hc>=379 && hc<384) || (vc>=81  && vc<86  && hc>=414 && hc<419) || (vc>=86  && vc<91  && hc>=414 && hc<419) || 
                 (vc>=91  && vc<96  && hc>=414 && hc<419) || (vc>=96  && vc<101 && hc>=414 && hc<419) || (vc>=101 && vc<106 && hc>=414 && hc<419) || 
                 (vc>=106 && vc<111 && hc>=414 && hc<419) || (vc>=111 && vc<116 && hc>=414 && hc<419) || (vc>=116 && vc<121 && hc>=414 && hc<419) || 
                 (vc>=121 && vc<126 && hc>=414 && hc<419) || (vc>=126 && vc<131 && hc>=414 && hc<419) || (vc>=131 && vc<136 && hc>=414 && hc<419) || 
                 (vc>=131 && vc<136 && hc>=419 && hc<424) || (vc>=131 && vc<136 && hc>=424 && hc<429) || (vc>=131 && vc<136 && hc>=429 && hc<434) || 
                 (vc>=131 && vc<136 && hc>=434 && hc<439) || (vc>=131 && vc<136 && hc>=439 && hc<444) || (vc>=131 && vc<136 && hc>=444 && hc<449) || 
                 (vc>=126 && vc<131 && hc>=444 && hc<449) || (vc>=121 && vc<126 && hc>=444 && hc<449) || (vc>=116 && vc<121 && hc>=444 && hc<449) || 
                 (vc>=111 && vc<116 && hc>=439 && hc<444) || (vc>=111 && vc<116 && hc>=444 && hc<449) || (vc>=111 && vc<116 && hc>=434 && hc<439) || 
                 (vc>=111 && vc<116 && hc>=429 && hc<434) || (vc>=81  && vc<86  && hc>=419 && hc<424) || (vc>=81  && vc<86  && hc>=424 && hc<429) || 
                 (vc>=81  && vc<86  && hc>=429 && hc<434) || (vc>=81  && vc<86  && hc>=434 && hc<439) || (vc>=81  && vc<86  && hc>=439 && hc<444) || 
                 (vc>=81  && vc<86  && hc>=444 && hc<449) || (vc>=81  && vc<86  && hc>=459 && hc<464) || (vc>=86  && vc<91  && hc>=459 && hc<464) || 
                 (vc>=101 && vc<106 && hc>=459 && hc<464) || (vc>=106 && vc<111 && hc>=459 && hc<464) || (vc>=111 && vc<116 && hc>=459 && hc<464) || 
                 (vc>=126 && vc<131 && hc>=459 && hc<464) || (vc>=131 && vc<136 && hc>=459 && hc<464) || (vc>=121 && vc<126 && hc>=459 && hc<464) || 
                 (vc>=116 && vc<121 && hc>=459 && hc<464) || (vc>=106 && vc<111 && hc>=394 && hc<399) || (vc>=106 && vc<111 && hc>=399 && hc<404) || 
                 (vc>=91  && vc<96  && hc>=459 && hc<464) || (vc>=96  && vc<101 && hc>=459 && hc<464) || (vc>=81  && vc<86  && hc>=464 && hc<469) || 
                 (vc>=81  && vc<86  && hc>=469 && hc<474) || (vc>=81  && vc<86  && hc>=474 && hc<479) || (vc>=81  && vc<86  && hc>=479 && hc<484) || 
                 (vc>=81  && vc<86  && hc>=484 && hc<489) || (vc>=81  && vc<86  && hc>=489 && hc<494) || (vc>=86  && vc<91  && hc>=489 && hc<494) || 
                 (vc>=91  && vc<96  && hc>=489 && hc<494) || (vc>=96  && vc<101 && hc>=489 && hc<494) || (vc>=121 && vc<126 && hc>=489 && hc<494) || 
                 (vc>=116 && vc<121 && hc>=489 && hc<494) || (vc>=111 && vc<116 && hc>=489 && hc<494) || (vc>=106 && vc<111 && hc>=489 && hc<494) || 
                 (vc>=101 && vc<106 && hc>=489 && hc<494) || (vc>=126 && vc<131 && hc>=489 && hc<494) || (vc>=131 && vc<136 && hc>=489 && hc<494) || 
                 (vc>=106 && vc<111 && hc>=464 && hc<469) || (vc>=106 && vc<111 && hc>=469 && hc<474) || (vc>=106 && vc<111 && hc>=474 && hc<479) || 
                 (vc>=106 && vc<111 && hc>=479 && hc<484) || (vc>=106 && vc<111 && hc>=484 && hc<489) || (vc>=86  && vc<91  && hc>=509 && hc<514) || 
                 (vc>=91  && vc<96  && hc>=509 && hc<514) || (vc>=96  && vc<101 && hc>=509 && hc<514) || (vc>=101 && vc<106 && hc>=509 && hc<514) || 
                 (vc>=106 && vc<111 && hc>=509 && hc<514) || (vc>=126 && vc<131 && hc>=509 && hc<514) || (vc>=121 && vc<126 && hc>=509 && hc<514) || 
                 (vc>=116 && vc<121 && hc>=509 && hc<514) || (vc>=111 && vc<116 && hc>=509 && hc<514) || (vc>=81  && vc<86  && hc>=509 && hc<514) || 
                 (vc>=81  && vc<86  && hc>=514 && hc<519) || (vc>=81  && vc<86  && hc>=519 && hc<524) || (vc>=81  && vc<86  && hc>=524 && hc<529) || 
                 (vc>=86  && vc<91  && hc>=524 && hc<529) || (vc>=91  && vc<96  && hc>=524 && hc<529) || (vc>=96  && vc<101 && hc>=529 && hc<534) || 
                 (vc>=91  && vc<96  && hc>=529 && hc<534) || (vc>=86  && vc<91  && hc>=534 && hc<539) || (vc>=81  && vc<86  && hc>=534 && hc<539) || 
                 (vc>=81  && vc<86  && hc>=539 && hc<544) || (vc>=81  && vc<86  && hc>=544 && hc<549) || (vc>=86  && vc<91  && hc>=544 && hc<549) || 
                 (vc>=91  && vc<96  && hc>=544 && hc<549) || (vc>=96  && vc<101 && hc>=544 && hc<549) || (vc>=101 && vc<106 && hc>=544 && hc<549) || 
                 (vc>=106 && vc<111 && hc>=544 && hc<549) || (vc>=111 && vc<116 && hc>=544 && hc<549) || (vc>=116 && vc<121 && hc>=544 && hc<549) || 
                 (vc>=121 && vc<126 && hc>=544 && hc<549) || (vc>=126 && vc<131 && hc>=544 && hc<549) || (vc>=131 && vc<136 && hc>=509 && hc<514) || 
                 (vc>=131 && vc<136 && hc>=544 && hc<549) || (vc>=81  && vc<86  && hc>=564 && hc<569) || (vc>=81  && vc<86  && hc>=559 && hc<564) || 
                 (vc>=86  && vc<91  && hc>=559 && hc<564) || (vc>=91  && vc<96  && hc>=559 && hc<564) || (vc>=96  && vc<101 && hc>=559 && hc<564) || 
                 (vc>=116 && vc<121 && hc>=559 && hc<564) || (vc>=101 && vc<106 && hc>=559 && hc<564) || (vc>=106 && vc<111 && hc>=559 && hc<564) || 
                 (vc>=111 && vc<116 && hc>=559 && hc<564) || (vc>=121 && vc<126 && hc>=559 && hc<564) || (vc>=126 && vc<131 && hc>=559 && hc<564) || 
                 (vc>=131 && vc<136 && hc>=559 && hc<564) || (vc>=131 && vc<136 && hc>=564 && hc<569) || (vc>=81  && vc<86  && hc>=569 && hc<574) || 
                 (vc>=81  && vc<86  && hc>=574 && hc<579) || (vc>=81  && vc<86  && hc>=579 && hc<584) || (vc>=81  && vc<86  && hc>=584 && hc<589) || 
                 (vc>=81  && vc<86  && hc>=589 && hc<594) || (vc>=131 && vc<136 && hc>=569 && hc<574) || (vc>=131 && vc<136 && hc>=574 && hc<579) || 
                 (vc>=131 && vc<136 && hc>=584 && hc<589) || (vc>=131 && vc<136 && hc>=579 && hc<584) || (vc>=131 && vc<136 && hc>=589 && hc<594) || 
                 (vc>=106 && vc<111 && hc>=564 && hc<569) || (vc>=106 && vc<111 && hc>=569 && hc<574) || (vc>=106 && vc<111 && hc>=574 && hc<579) || 
                 (vc>=106 && vc<111 && hc>=584 && hc<589) || (vc>=106 && vc<111 && hc>=579 && hc<584) || (vc>=81  && vc<86  && hc>=609 && hc<614) || 
                 (vc>=81  && vc<86  && hc>=614 && hc<619) || (vc>=116 && vc<121 && hc>=614 && hc<619) || (vc>=116 && vc<121 && hc>=609 && hc<614) || 
                 (vc>=111 && vc<116 && hc>=609 && hc<614) || (vc>=106 && vc<111 && hc>=609 && hc<614) || (vc>=101 && vc<106 && hc>=609 && hc<614) || 
                 (vc>=86  && vc<91  && hc>=609 && hc<614) || (vc>=86  && vc<91  && hc>=614 && hc<619) || (vc>=91  && vc<96  && hc>=609 && hc<614) || 
                 (vc>=96  && vc<101 && hc>=609 && hc<614) || (vc>=91  && vc<96  && hc>=614 && hc<619) || (vc>=81  && vc<86  && hc>=619 && hc<624) || 
                 (vc>=86  && vc<91  && hc>=619 && hc<624) || (vc>=91  && vc<96  && hc>=619 && hc<624) || (vc>=96  && vc<101 && hc>=619 && hc<624) || 
                 (vc>=96  && vc<101 && hc>=614 && hc<619) || (vc>=101 && vc<106 && hc>=614 && hc<619) || (vc>=106 && vc<111 && hc>=614 && hc<619) || 
                 (vc>=111 && vc<116 && hc>=614 && hc<619) || (vc>=101 && vc<106 && hc>=619 && hc<624) || (vc>=106 && vc<111 && hc>=619 && hc<624) || 
                 (vc>=111 && vc<116 && hc>=619 && hc<624) || (vc>=116 && vc<121 && hc>=619 && hc<624) || (vc>=131 && vc<136 && hc>=614 && hc<619) || 
                 (vc>=126 && vc<131 && hc>=614 && hc<619)) 
        begin
            red = 3'b111;
			green = 3'b111;
			blue = 2'b11;
        end
        
        // 3 hearts 
        else if (lives == 3 && 
                ((vc>=436 && vc<441 && hc>=264 && hc<269) || (vc>=431 && vc<436 && hc>=254 && hc<259) || (vc>=436 && vc<441 && hc>=259 && hc<264) || 
                 (vc>=431 && vc<436 && hc>=249 && hc<254) || (vc>=436 && vc<441 && hc>=244 && hc<249) || (vc>=441 && vc<446 && hc>=244 && hc<249) || 
                 (vc>=446 && vc<451 && hc>=244 && hc<249) || (vc>=451 && vc<456 && hc>=249 && hc<254) || (vc>=456 && vc<461 && hc>=254 && hc<259) || 
                 (vc>=461 && vc<466 && hc>=259 && hc<264) || (vc>=456 && vc<461 && hc>=264 && hc<269) || (vc>=451 && vc<456 && hc>=269 && hc<274) || 
                 (vc>=446 && vc<451 && hc>=274 && hc<279) || (vc>=441 && vc<446 && hc>=274 && hc<279) || (vc>=436 && vc<441 && hc>=274 && hc<279) || 
                 (vc>=431 && vc<436 && hc>=269 && hc<274) || (vc>=436 && vc<441 && hc>=254 && hc<259) || (vc>=441 && vc<446 && hc>=254 && hc<259) || 
                 (vc>=446 && vc<451 && hc>=254 && hc<259) || (vc>=451 && vc<456 && hc>=254 && hc<259) || (vc>=451 && vc<456 && hc>=259 && hc<264) || 
                 (vc>=446 && vc<451 && hc>=259 && hc<264) || (vc>=441 && vc<446 && hc>=259 && hc<264) || (vc>=441 && vc<446 && hc>=264 && hc<269) || 
                 (vc>=446 && vc<451 && hc>=264 && hc<269) || (vc>=446 && vc<451 && hc>=269 && hc<274) || (vc>=441 && vc<446 && hc>=269 && hc<274) || 
                 (vc>=436 && vc<441 && hc>=269 && hc<274) || (vc>=451 && vc<456 && hc>=264 && hc<269) || (vc>=456 && vc<461 && hc>=259 && hc<264) || 
                 (vc>=431 && vc<436 && hc>=274 && hc<279) || (vc>=436 && vc<441 && hc>=279 && hc<284) || (vc>=441 && vc<446 && hc>=279 && hc<284) || 
                 (vc>=446 && vc<451 && hc>=279 && hc<284) || (vc>=451 && vc<456 && hc>=274 && hc<279) || (vc>=456 && vc<461 && hc>=269 && hc<274) || 
                 (vc>=461 && vc<466 && hc>=264 && hc<269) || (vc>=436 && vc<441 && hc>=249 && hc<254) || (vc>=441 && vc<446 && hc>=249 && hc<254) || 
                 (vc>=446 && vc<451 && hc>=249 && hc<254) || (vc>=431 && vc<436 && hc>=319 && hc<324) || (vc>=431 && vc<436 && hc>=324 && hc<329) || 
                 (vc>=436 && vc<441 && hc>=314 && hc<319) || (vc>=436 && vc<441 && hc>=319 && hc<324) || (vc>=436 && vc<441 && hc>=324 && hc<329) || 
                 (vc>=436 && vc<441 && hc>=329 && hc<334) || (vc>=436 && vc<441 && hc>=334 && hc<339) || (vc>=436 && vc<441 && hc>=339 && hc<344) || 
                 (vc>=436 && vc<441 && hc>=344 && hc<349) || (vc>=436 && vc<441 && hc>=349 && hc<354) || (vc>=431 && vc<436 && hc>=339 && hc<344) || 
                 (vc>=431 && vc<436 && hc>=344 && hc<349) || (vc>=441 && vc<446 && hc>=314 && hc<319) || (vc>=441 && vc<446 && hc>=319 && hc<324) || 
                 (vc>=441 && vc<446 && hc>=324 && hc<329) || (vc>=441 && vc<446 && hc>=329 && hc<334) || (vc>=441 && vc<446 && hc>=334 && hc<339) || 
                 (vc>=441 && vc<446 && hc>=339 && hc<344) || (vc>=441 && vc<446 && hc>=344 && hc<349) || (vc>=441 && vc<446 && hc>=349 && hc<354) || 
                 (vc>=446 && vc<451 && hc>=314 && hc<319) || (vc>=446 && vc<451 && hc>=319 && hc<324) || (vc>=446 && vc<451 && hc>=324 && hc<329) || 
                 (vc>=446 && vc<451 && hc>=329 && hc<334) || (vc>=446 && vc<451 && hc>=339 && hc<344) || (vc>=446 && vc<451 && hc>=334 && hc<339) || 
                 (vc>=446 && vc<451 && hc>=344 && hc<349) || (vc>=446 && vc<451 && hc>=349 && hc<354) || (vc>=451 && vc<456 && hc>=319 && hc<324) || 
                 (vc>=451 && vc<456 && hc>=324 && hc<329) || (vc>=451 && vc<456 && hc>=329 && hc<334) || (vc>=451 && vc<456 && hc>=334 && hc<339) || 
                 (vc>=451 && vc<456 && hc>=339 && hc<344) || (vc>=451 && vc<456 && hc>=344 && hc<349) || (vc>=456 && vc<461 && hc>=324 && hc<329) || 
                 (vc>=456 && vc<461 && hc>=329 && hc<334) || (vc>=456 && vc<461 && hc>=334 && hc<339) || (vc>=456 && vc<461 && hc>=339 && hc<344) || 
                 (vc>=461 && vc<466 && hc>=329 && hc<334) || (vc>=461 && vc<466 && hc>=334 && hc<339) || (vc>=436 && vc<441 && hc>=384 && hc<389) || 
                 (vc>=436 && vc<441 && hc>=389 && hc<394) || (vc>=436 && vc<441 && hc>=394 && hc<399) || (vc>=436 && vc<441 && hc>=399 && hc<404) || 
                 (vc>=436 && vc<441 && hc>=404 && hc<409) || (vc>=436 && vc<441 && hc>=419 && hc<424) || (vc>=431 && vc<436 && hc>=389 && hc<394) || 
                 (vc>=431 && vc<436 && hc>=394 && hc<399) || (vc>=431 && vc<436 && hc>=409 && hc<414) || (vc>=431 && vc<436 && hc>=414 && hc<419) || 
                 (vc>=441 && vc<446 && hc>=384 && hc<389) || (vc>=441 && vc<446 && hc>=389 && hc<394) || (vc>=441 && vc<446 && hc>=394 && hc<399) || 
                 (vc>=441 && vc<446 && hc>=399 && hc<404) || (vc>=441 && vc<446 && hc>=404 && hc<409) || (vc>=436 && vc<441 && hc>=409 && hc<414) || 
                 (vc>=436 && vc<441 && hc>=414 && hc<419) || (vc>=441 && vc<446 && hc>=409 && hc<414) || (vc>=441 && vc<446 && hc>=414 && hc<419) || 
                 (vc>=441 && vc<446 && hc>=419 && hc<424) || (vc>=446 && vc<451 && hc>=384 && hc<389) || (vc>=446 && vc<451 && hc>=389 && hc<394) || 
                 (vc>=446 && vc<451 && hc>=394 && hc<399) || (vc>=446 && vc<451 && hc>=399 && hc<404) || (vc>=446 && vc<451 && hc>=404 && hc<409) || 
                 (vc>=446 && vc<451 && hc>=409 && hc<414) || (vc>=446 && vc<451 && hc>=414 && hc<419) || (vc>=446 && vc<451 && hc>=419 && hc<424) || 
                 (vc>=451 && vc<456 && hc>=389 && hc<394) || (vc>=451 && vc<456 && hc>=394 && hc<399) || (vc>=451 && vc<456 && hc>=399 && hc<404) || 
                 (vc>=451 && vc<456 && hc>=404 && hc<409) || (vc>=451 && vc<456 && hc>=409 && hc<414) || (vc>=451 && vc<456 && hc>=414 && hc<419) || 
                 (vc>=456 && vc<461 && hc>=394 && hc<399) || (vc>=456 && vc<461 && hc>=399 && hc<404) || (vc>=456 && vc<461 && hc>=409 && hc<414) || 
                 (vc>=456 && vc<461 && hc>=404 && hc<409) || (vc>=461 && vc<466 && hc>=399 && hc<404) || (vc>=461 && vc<466 && hc>=404 && hc<409)))
        begin
			red = 3'b111;
			green = 3'b000;
			blue = 2'b00;
        end
        // 2 hearts
        else if (lives == 2 && 
                ((vc>=436 && vc<441 && hc>=264 && hc<269) || (vc>=431 && vc<436 && hc>=254 && hc<259) || (vc>=436 && vc<441 && hc>=259 && hc<264) || 
                 (vc>=431 && vc<436 && hc>=249 && hc<254) || (vc>=436 && vc<441 && hc>=244 && hc<249) || (vc>=441 && vc<446 && hc>=244 && hc<249) || 
                 (vc>=446 && vc<451 && hc>=244 && hc<249) || (vc>=451 && vc<456 && hc>=249 && hc<254) || (vc>=456 && vc<461 && hc>=254 && hc<259) || 
                 (vc>=461 && vc<466 && hc>=259 && hc<264) || (vc>=456 && vc<461 && hc>=264 && hc<269) || (vc>=451 && vc<456 && hc>=269 && hc<274) || 
                 (vc>=446 && vc<451 && hc>=274 && hc<279) || (vc>=441 && vc<446 && hc>=274 && hc<279) || (vc>=436 && vc<441 && hc>=274 && hc<279) || 
                 (vc>=431 && vc<436 && hc>=269 && hc<274) || (vc>=436 && vc<441 && hc>=254 && hc<259) || (vc>=441 && vc<446 && hc>=254 && hc<259) || 
                 (vc>=446 && vc<451 && hc>=254 && hc<259) || (vc>=451 && vc<456 && hc>=254 && hc<259) || (vc>=451 && vc<456 && hc>=259 && hc<264) || 
                 (vc>=446 && vc<451 && hc>=259 && hc<264) || (vc>=441 && vc<446 && hc>=259 && hc<264) || (vc>=441 && vc<446 && hc>=264 && hc<269) || 
                 (vc>=446 && vc<451 && hc>=264 && hc<269) || (vc>=446 && vc<451 && hc>=269 && hc<274) || (vc>=441 && vc<446 && hc>=269 && hc<274) || 
                 (vc>=436 && vc<441 && hc>=269 && hc<274) || (vc>=451 && vc<456 && hc>=264 && hc<269) || (vc>=456 && vc<461 && hc>=259 && hc<264) || 
                 (vc>=431 && vc<436 && hc>=274 && hc<279) || (vc>=436 && vc<441 && hc>=279 && hc<284) || (vc>=441 && vc<446 && hc>=279 && hc<284) || 
                 (vc>=446 && vc<451 && hc>=279 && hc<284) || (vc>=451 && vc<456 && hc>=274 && hc<279) || (vc>=456 && vc<461 && hc>=269 && hc<274) || 
                 (vc>=461 && vc<466 && hc>=264 && hc<269) || (vc>=436 && vc<441 && hc>=249 && hc<254) || (vc>=441 && vc<446 && hc>=249 && hc<254) || 
                 (vc>=446 && vc<451 && hc>=249 && hc<254) || (vc>=431 && vc<436 && hc>=319 && hc<324) || (vc>=431 && vc<436 && hc>=324 && hc<329) || 
                 (vc>=436 && vc<441 && hc>=314 && hc<319) || (vc>=436 && vc<441 && hc>=319 && hc<324) || (vc>=436 && vc<441 && hc>=324 && hc<329) || 
                 (vc>=436 && vc<441 && hc>=329 && hc<334) || (vc>=436 && vc<441 && hc>=334 && hc<339) || (vc>=436 && vc<441 && hc>=339 && hc<344) || 
                 (vc>=436 && vc<441 && hc>=344 && hc<349) || (vc>=436 && vc<441 && hc>=349 && hc<354) || (vc>=431 && vc<436 && hc>=339 && hc<344) || 
                 (vc>=431 && vc<436 && hc>=344 && hc<349) || (vc>=441 && vc<446 && hc>=314 && hc<319) || (vc>=441 && vc<446 && hc>=319 && hc<324) || 
                 (vc>=441 && vc<446 && hc>=324 && hc<329) || (vc>=441 && vc<446 && hc>=329 && hc<334) || (vc>=441 && vc<446 && hc>=334 && hc<339) || 
                 (vc>=441 && vc<446 && hc>=339 && hc<344) || (vc>=441 && vc<446 && hc>=344 && hc<349) || (vc>=441 && vc<446 && hc>=349 && hc<354) || 
                 (vc>=446 && vc<451 && hc>=314 && hc<319) || (vc>=446 && vc<451 && hc>=319 && hc<324) || (vc>=446 && vc<451 && hc>=324 && hc<329) || 
                 (vc>=446 && vc<451 && hc>=329 && hc<334) || (vc>=446 && vc<451 && hc>=339 && hc<344) || (vc>=446 && vc<451 && hc>=334 && hc<339) || 
                 (vc>=446 && vc<451 && hc>=344 && hc<349) || (vc>=446 && vc<451 && hc>=349 && hc<354) || (vc>=451 && vc<456 && hc>=319 && hc<324) || 
                 (vc>=451 && vc<456 && hc>=324 && hc<329) || (vc>=451 && vc<456 && hc>=329 && hc<334) || (vc>=451 && vc<456 && hc>=334 && hc<339) || 
                 (vc>=451 && vc<456 && hc>=339 && hc<344) || (vc>=451 && vc<456 && hc>=344 && hc<349) || (vc>=456 && vc<461 && hc>=324 && hc<329) || 
                 (vc>=456 && vc<461 && hc>=329 && hc<334) || (vc>=456 && vc<461 && hc>=334 && hc<339) || (vc>=456 && vc<461 && hc>=339 && hc<344) || 
                 (vc>=461 && vc<466 && hc>=329 && hc<334) || (vc>=461 && vc<466 && hc>=334 && hc<339)))
        begin
			red = 3'b111;
			green = 3'b000;
			blue = 2'b00;
        end
        // 1 heart
        else if (lives == 1 && 
                ((vc>=436 && vc<441 && hc>=264 && hc<269) || (vc>=431 && vc<436 && hc>=254 && hc<259) || (vc>=436 && vc<441 && hc>=259 && hc<264) || 
                 (vc>=431 && vc<436 && hc>=249 && hc<254) || (vc>=436 && vc<441 && hc>=244 && hc<249) || (vc>=441 && vc<446 && hc>=244 && hc<249) || 
                 (vc>=446 && vc<451 && hc>=244 && hc<249) || (vc>=451 && vc<456 && hc>=249 && hc<254) || (vc>=456 && vc<461 && hc>=254 && hc<259) || 
                 (vc>=461 && vc<466 && hc>=259 && hc<264) || (vc>=456 && vc<461 && hc>=264 && hc<269) || (vc>=451 && vc<456 && hc>=269 && hc<274) || 
                 (vc>=446 && vc<451 && hc>=274 && hc<279) || (vc>=441 && vc<446 && hc>=274 && hc<279) || (vc>=436 && vc<441 && hc>=274 && hc<279) || 
                 (vc>=431 && vc<436 && hc>=269 && hc<274) || (vc>=436 && vc<441 && hc>=254 && hc<259) || (vc>=441 && vc<446 && hc>=254 && hc<259) || 
                 (vc>=446 && vc<451 && hc>=254 && hc<259) || (vc>=451 && vc<456 && hc>=254 && hc<259) || (vc>=451 && vc<456 && hc>=259 && hc<264) || 
                 (vc>=446 && vc<451 && hc>=259 && hc<264) || (vc>=441 && vc<446 && hc>=259 && hc<264) || (vc>=441 && vc<446 && hc>=264 && hc<269) || 
                 (vc>=446 && vc<451 && hc>=264 && hc<269) || (vc>=446 && vc<451 && hc>=269 && hc<274) || (vc>=441 && vc<446 && hc>=269 && hc<274) || 
                 (vc>=436 && vc<441 && hc>=269 && hc<274) || (vc>=451 && vc<456 && hc>=264 && hc<269) || (vc>=456 && vc<461 && hc>=259 && hc<264) || 
                 (vc>=431 && vc<436 && hc>=274 && hc<279) || (vc>=436 && vc<441 && hc>=279 && hc<284) || (vc>=441 && vc<446 && hc>=279 && hc<284) || 
                 (vc>=446 && vc<451 && hc>=279 && hc<284) || (vc>=451 && vc<456 && hc>=274 && hc<279) || (vc>=456 && vc<461 && hc>=269 && hc<274) || 
                 (vc>=461 && vc<466 && hc>=264 && hc<269) || (vc>=436 && vc<441 && hc>=249 && hc<254) || (vc>=441 && vc<446 && hc>=249 && hc<254) || 
                 (vc>=446 && vc<451 && hc>=249 && hc<254)))
        begin
			red = 3'b111;
			green = 3'b000;
			blue = 2'b00;
        end
        
        // display board
        else if (vc >= board_posY && vc < (board_posY + board_height) && hc >= hbp && hc < (hbp + board_width))
		begin
			red = 3'b000;
			green = 3'b000;
			blue = 2'b11;
		end
        
		// display black background
		else
		begin
			red = 0;
			green = 0;
			blue = 0;
		end
	end
	// we're outside active vertical range so display black
	else
	begin
		red = 0;
		green = 0;
		blue = 0;
	end
    
end

// Seven-Segment Display 

function [0:7] numToDisplay;
input [0:3] num;

    case (num)
    
    4'b0000 : numToDisplay = 8'b00000011;   // Display 0
    
    4'b0001 : numToDisplay = 8'b10011111;   // Display 1
    
    4'b0010 : numToDisplay = 8'b00100101;   // Display 2
    
    4'b0011 : numToDisplay = 8'b00001101;   // Display 3
		
    4'b0100 : numToDisplay = 8'b10011001;   // Display 4
    
    4'b0101 : numToDisplay = 8'b01001001;   // Display 5
    
    4'b0110 : numToDisplay = 8'b01000001;   // Display 6
    
    4'b0111 : numToDisplay = 8'b00011111;   // Display 7
    
    4'b1000 : numToDisplay = 8'b00000001;   // Display 8
    
    4'b1001 : numToDisplay = 8'b00001001;   // Display 9
    
    endcase

endfunction


endmodule