// ============================================================
// CSE 1204 - Digital Logic Design Laboratory
// Project   : Divisor & Prime Number Explorer
// Board     : Basys 3 (Artix-7) | Clock: 100 MHz
// ============================================================
// BUTTON MAPPING:
//   BTNC = Reset
//   BTNL = Show divisor COUNT of N
//   BTNR = Start divisor SCROLL (auto every 1 sec)
//   BTNU = Show PRIME COUNT in 1..N
//   BTND = Start prime SCROLL / toggle asc-desc (auto every 1 sec)
//   LED0 = 1 if input N is prime
//   SW[9:0] = input number 1..1000
// DEFAULT (no button pressed): shows N on display
// ============================================================

`timescale 1ns / 1ps

// ============================================================
// MODULE 1: Button Debouncer (produces single-cycle pulse)
// ============================================================
module button_debounce(
    input  clk,
    input  rst,
    input  btn_in,
    output btn_out
);
    reg btn_sync_0, btn_sync_1;
    reg btn_stable, btn_prev;
    reg [19:0] counter;
    reg pulse;

    assign btn_out = pulse;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
            btn_stable <= 1'b0;
            btn_prev   <= 1'b0;
            counter    <= 20'd0;
            pulse      <= 1'b0;
        end else begin
            // 2-stage synchronizer
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;

            // debounce
            if (btn_sync_1 == btn_stable) begin
                counter <= 20'd0;
            end else begin
                if (counter == 20'd9_999) begin
                    btn_stable <= btn_sync_1;
                    counter    <= 20'd0;
                end else begin
                    counter <= counter + 1'b1;
                end
            end

            // one-clock pulse on rising edge
            pulse    <= btn_stable & ~btn_prev;
            btn_prev <= btn_stable;
        end
    end
endmodule

// ============================================================
// MODULE 2: Divisor Calculator
// - Finds all divisors of N sequentially (one per clock)
// - Stores up to 40 divisors (1000 has max 16 divisors)
// - next_div: advance to next divisor on 1-sec tick
// - start_scroll: begin scrolling from first divisor
// ============================================================
module divisor_calc(
    input        clk,
    input        rst,
    input  [9:0] N,
    output reg [9:0] div_count,
    output reg [9:0] div_val,
    output reg       calc_done,
    input        next_div,
    input        start_scroll
);
    reg [9:0] divisors [0:39];
    reg [5:0] div_index;
    reg [5:0] total_divs;
    reg [9:0] i;
 
    reg       scrolling;
    reg [9:0] N_prev;
    integer   j;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div_count  <= 10'd0;
            div_val    <= 10'd0;
            div_index  <= 6'd0;
            total_divs <= 6'd0;
            i          <= 10'd1;
            calc_done  <= 1'b0;
            scrolling  <= 1'b0;
            N_prev     <= 10'd0;
            for (j = 0; j < 40; j = j + 1) divisors[j] <= 10'd0;
        end else begin

            // Restart computation when N changes
            if (N != N_prev) begin
                N_prev     <= N;
                div_count  <= 10'd0;
                div_val    <= 10'd0;
                div_index  <= 6'd0;
                total_divs <= 6'd0;
                i          <= 10'd1;
                calc_done  <= 1'b0;
                scrolling  <= 1'b0;

            end else if (!calc_done) begin
                // Sequential divisor finding: one candidate per clock
                if (i <= N && total_divs < 40) begin
                    if ((N % i) == 0) begin
                        divisors[total_divs] <= i;
                        total_divs <= total_divs + 1'b1;
                    end
                    i <= i + 1'b1;
                end else begin
                    div_count <= total_divs;
                    calc_done <= 1'b1;
                    if (total_divs > 0)
                        div_val <= divisors[0];
                end

            end else begin
                // Calculation done — handle scroll
                if (start_scroll && total_divs > 0) begin
                    scrolling <= 1'b1;
                    div_index <= 6'd0;
                    div_val   <= divisors[0];
                end

                if (next_div && scrolling && total_divs > 0) begin
                    if (div_index >= total_divs - 1'b1) begin
                        div_index <= 6'd0;
                        div_val   <= divisors[0];
                    end else begin
                        div_index <= div_index + 1'b1;
                        div_val   <= divisors[div_index + 1'b1];
                    end
                end
            end
        end
    end
endmodule


// ============================================================
// MODULE 3: Prime Calculator
// - Finds all primes up to N sequentially
// - Stores up to 170 primes (there are 168 primes below 1000)
// - start_scroll: begin listing from start in current direction
// - dir_toggle:   flip ascending / descending
// - next_prime:   advance on 1-sec tick
// ============================================================
module prime_calc(
    input        clk,
    input        rst,
    input  [9:0] N,
    output reg [9:0] prime_count,
    output reg [9:0] prime_val,
    output reg       calc_done,
    input        start_scroll,
    input        next_prime,
    input        dir_toggle,
    output reg   is_asc
);
    reg [9:0] primes [0:169];
    reg [7:0] prime_index;
    reg [7:0] total_primes;
    reg [9:0] candidate;
    reg [9:0] divisor;
    reg       is_prime_flag;
    reg       scrolling;
    reg [9:0] N_prev;
    integer   j;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prime_count   <= 10'd0;
            prime_val     <= 10'd0;
            prime_index   <= 8'd0;
            total_primes  <= 8'd0;
            candidate     <= 10'd2;
            divisor       <= 10'd2;
            is_prime_flag <= 1'b1;
            calc_done     <= 1'b0;
            scrolling     <= 1'b0;
            is_asc        <= 1'b1;
            N_prev        <= 10'd0;
            for (j = 0; j < 170; j = j + 1) primes[j] <= 10'd0;
        end else begin

            // Restart computation when N changes
            if (N != N_prev) begin
                N_prev        <= N;
                prime_count   <= 10'd0;
                prime_val     <= 10'd0;
                prime_index   <= 8'd0;
                total_primes  <= 8'd0;
                candidate     <= 10'd2;
                divisor       <= 10'd2;
                is_prime_flag <= 1'b1;
                calc_done     <= 1'b0;
                scrolling     <= 1'b0;
                is_asc        <= 1'b1;

            end else if (!calc_done) begin
                // Sequential prime finding
                if (candidate <= N) begin
                    if (divisor * divisor <= candidate) begin
                        if ((candidate % divisor) == 0) begin
                            // candidate is not prime
                            is_prime_flag <= 1'b0;
                            divisor       <= divisor + 1'b1;
                        end else begin
                            divisor <= divisor + 1'b1;
                        end
                    end else begin
                        // finished checking divisors for this candidate
                        if (is_prime_flag && total_primes < 170) begin
                            primes[total_primes] <= candidate;
                            total_primes <= total_primes + 1'b1;
                        end
                        candidate     <= candidate + 1'b1;
                        divisor       <= 10'd2;
                        is_prime_flag <= 1'b1;
                    end
                end else begin
                    prime_count <= total_primes;
                    calc_done   <= 1'b1;
                    if (total_primes > 0)
                        prime_val <= primes[0];
                end

            end else begin
                // Calculation done — handle scroll and direction toggle

                // Start scroll (rewind to beginning in current direction)
                if (start_scroll && total_primes > 0) begin
                    scrolling <= 1'b1;
                    if (is_asc) begin
                        prime_index <= 8'd0;
                        prime_val   <= primes[0];
                    end else begin
                        prime_index <= total_primes - 1'b1;
                        prime_val   <= primes[total_primes - 1'b1];
                    end
                end

                // Toggle direction
                if (dir_toggle && total_primes > 0) begin
                    is_asc    <= ~is_asc;
                    scrolling <= 1'b1;
                    if (is_asc) begin
                        // was ascending → switch to descending
                        prime_index <= total_primes - 1'b1;
                        prime_val   <= primes[total_primes - 1'b1];
                    end else begin
                        // was descending → switch to ascending
                        prime_index <= 8'd0;
                        prime_val   <= primes[0];
                    end
                end

                // Advance to next prime on tick
                if (next_prime && scrolling && total_primes > 0) begin
                    if (is_asc) begin
                        if (prime_index >= total_primes - 1'b1) begin
                            prime_index <= 8'd0;
                            prime_val   <= primes[0];
                        end else begin
                            prime_index <= prime_index + 1'b1;
                            prime_val   <= primes[prime_index + 1'b1];
                        end
                    end else begin
                        if (prime_index == 8'd0) begin
                            prime_index <= total_primes - 1'b1;
                            prime_val   <= primes[total_primes - 1'b1];
                        end else begin
                            prime_index <= prime_index - 1'b1;
                            prime_val   <= primes[prime_index - 1'b1];
                        end
                    end
                end
            end
        end
    end
endmodule


// ============================================================
// MODULE 4: Prime Checker (combinational — for LED only)
// Bounded loop avoids synthesis timing issues
// ============================================================
module prime_checker(
    input  [9:0] N,
    output reg   is_prime
);
    integer k;
    always @(*) begin
        if (N < 2) begin
            is_prime = 1'b0;
        end else begin
            is_prime = 1'b1;
            for (k = 2; k <= 31; k = k + 1) begin
                if ((k * k <= N) && (N % k == 0))
                    is_prime = 1'b0;
            end
        end
    end
endmodule


// ============================================================
// MODULE 5: 7-Segment Decoder (active LOW cathodes)
// seg[6:0] = {g, f, e, d, c, b, a}
// ============================================================
module seg_decoder(
    input  [3:0] digit,
    input        blank,
    output reg [6:0] seg
);
    always @(*) begin
        if (blank) seg = 7'b1111111;
        else case (digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end
endmodule


// ============================================================
// MODULE 6: Display Controller (4-digit time-multiplexed)
// Blanks leading zeros automatically
// ============================================================
module display_controller(
    input         clk,
    input         rst,
    input  [13:0] number,
    input         show_blank,
    output reg [6:0] seg,
    output reg [3:0] an
);
    reg [16:0] refresh_counter;
    reg [1:0]  digit_select;

    wire [3:0] d0 =  number         % 10;
    wire [3:0] d1 = (number / 10)   % 10;
    wire [3:0] d2 = (number / 100)  % 10;
    wire [3:0] d3 = (number / 1000) % 10;

    // Blank leading zeros
    wire b3 = (number < 14'd1000);
    wire b2 = (number < 14'd100);
    wire b1 = (number < 14'd10);
    wire b0 = 1'b0;

    reg [3:0] cur_digit;
    reg       cur_blank;
    wire [6:0] seg_out;

    seg_decoder dec_inst(
        .digit(cur_digit),
        .blank(cur_blank | show_blank),
        .seg(seg_out)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            refresh_counter <= 17'd0;
            digit_select    <= 2'd0;
        end else if (refresh_counter == 17'd999) begin
            refresh_counter <= 17'd0;
            digit_select    <= digit_select + 1'b1;
        end else begin
            refresh_counter <= refresh_counter + 1'b1;
        end
    end

    always @(*) begin
        case (digit_select)
            2'd0: begin an=4'b1110; cur_digit=d0; cur_blank=b0; end
            2'd1: begin an=4'b1101; cur_digit=d1; cur_blank=b1; end
            2'd2: begin an=4'b1011; cur_digit=d2; cur_blank=b2; end
            2'd3: begin an=4'b0111; cur_digit=d3; cur_blank=b3; end
            default: begin an=4'b1111; cur_digit=4'd0; cur_blank=1'b1; end
        endcase
        seg = seg_out;
    end
endmodule


// ============================================================
// MODULE 7: 1-Second Auto-Scroll Timer
// Generates one tick every 1 second when enabled
// ============================================================
module one_sec_timer(
    input  clk,
    input  rst,
    input  enable,
    output reg tick
);
    reg [26:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 27'd0;
            tick    <= 1'b0;
        end else if (enable) begin
            if (counter == 27'd999_999) begin
                counter <= 27'd0;
                tick    <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                tick    <= 1'b0;
            end
        end else begin
            counter <= 27'd0;
            tick    <= 1'b0;
        end
    end
endmodule


// ============================================================
// TOP MODULE
// ============================================================
module top_module(
    input        clk,
    input  [9:0] SW,
    input        BTNU,    // Button 3 : prime count 1..N
    input        BTNL,    // Button 1 : divisor count
    input        BTNR,    // Button 2 : divisor scroll
    input        BTND,    // Button 4 : prime scroll / toggle asc-desc
    input        BTNC,    // Button 5 : reset
    output [6:0] seg,
    output [3:0] an,
    output       LED0     // 1 = N is prime
);

    wire rst = BTNC;
    reg [6:0] clk_div;
reg clk_work;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        clk_div  <= 7'd0;
        clk_work <= 1'b0;
    end else begin
        if (clk_div == 7'd49) begin
            clk_div  <= 7'd0;
            clk_work <= ~clk_work;
        end else begin
            clk_div <= clk_div + 1'b1;
        end
    end
end

    // Clamp SW input to 1..1000
    wire [9:0] N = (SW == 10'd0)   ? 10'd1    :
                   (SW > 10'd1000) ? 10'd1000 : SW;

    // ---- Debounced single-cycle button pulses ----
    wire btn_l, btn_r, btn_u, btn_d;
button_debounce db_l(.clk(clk_work),.rst(rst),.btn_in(BTNL),.btn_out(btn_l));
button_debounce db_r(.clk(clk_work),.rst(rst),.btn_in(BTNR),.btn_out(btn_r));
button_debounce db_u(.clk(clk_work),.rst(rst),.btn_in(BTNU),.btn_out(btn_u));
button_debounce db_d(.clk(clk_work),.rst(rst),.btn_in(BTND),.btn_out(btn_d));

    // ---- Prime LED ----
    wire n_is_prime;
    prime_checker pchk(.N(N), .is_prime(n_is_prime));
    assign LED0 = n_is_prime;

   // ---- Divisor engine ----
wire [9:0] div_count, div_val;
wire       div_tick;
wire       div_done;
reg        div_scroll_active;

divisor_calc div_calc(
   .clk(clk_work), .rst(rst), .N(N),
    .div_count(div_count),
    .div_val(div_val),
    .calc_done(div_done),
    .next_div(div_tick),
   .start_scroll(btn_r && div_done && (mode == 3'd2))
);

    one_sec_timer div_timer(
        .clk(clk_work), .rst(rst),
        .enable(div_scroll_active),
        .tick(div_tick)
    );

   // ---- Prime engine ----
wire [9:0] prime_count, prime_val;
wire       is_asc, prime_tick;
wire       prime_done;
reg        prime_scroll_active;

  prime_calc prm_calc(
    .clk(clk_work),
    .rst(rst),
    .N(N),
    .prime_count(prime_count),
    .prime_val(prime_val),
    .calc_done(prime_done),
.start_scroll(btn_d && prime_done && (mode == 3'd4)),
    .next_prime(prime_tick),
    .dir_toggle(btn_d && prime_done && (mode == 3'd4)),
    .is_asc(is_asc)
);

    one_sec_timer prime_timer(
        .clk(clk_work), .rst(rst),
        .enable(prime_scroll_active),
        .tick(prime_tick)
    );

    // ---- Display mux ----
    reg [13:0] display_num;
    reg        show_blank;

    // mode: 0=show N, 1=div count, 2=div scroll, 3=prime count, 4=prime scroll
 reg [2:0] mode;
reg [9:0] N_prev_top;

always @(posedge clk_work or posedge rst) begin
    if (rst) begin
        mode                <= 3'd0;
        div_scroll_active   <= 1'b0;
        prime_scroll_active <= 1'b0;
        display_num         <= {4'd0, N};
        show_blank          <= 1'b0;
        N_prev_top          <= N;
    end else begin
        if (N != N_prev_top) begin
            N_prev_top          <= N;
            mode                <= 3'd0;
            div_scroll_active   <= 1'b0;
            prime_scroll_active <= 1'b0;
            display_num         <= {4'd0, N};
            show_blank          <= 1'b0;
        end else begin

            if (btn_l && div_done) begin
                mode                <= 3'd1;
                div_scroll_active   <= 1'b0;
                prime_scroll_active <= 1'b0;
            end

            if (btn_r && div_done) begin
                mode                <= 3'd2;
                div_scroll_active   <= 1'b1;
                prime_scroll_active <= 1'b0;
            end

            if (btn_u && prime_done) begin
                mode                <= 3'd3;
                div_scroll_active   <= 1'b0;
                prime_scroll_active <= 1'b0;
            end

            if (btn_d && prime_done) begin
                mode                <= 3'd4;
                div_scroll_active   <= 1'b0;
                prime_scroll_active <= 1'b1;
            end

            case (mode)
                3'd0: begin
                    show_blank <= 1'b0;
                    display_num <= {4'd0, N};
                end
                3'd1: begin
                    show_blank <= 1'b0;
                    display_num <= {4'd0, div_count};
                end
                3'd2: begin
                    show_blank <= 1'b0;
                    display_num <= {4'd0, div_val};
                end
                3'd3: begin
                    show_blank <= 1'b0;
                    display_num <= {4'd0, prime_count};
                end
                3'd4: begin
                    show_blank <= 1'b0;
                    display_num <= {4'd0, prime_val};
                end
                default: begin
                    show_blank <= 1'b0;
                    display_num <= {4'd0, N};
                end
            endcase
        end
    end
end

    // ---- 7-segment display ----
    display_controller disp(
      .clk(clk_work), .rst(rst),
        .number(display_num),
        .show_blank(show_blank),
        .seg(seg),
        .an(an)
    );

endmodule
