`timescale 1ns / 1ns
module vga_pic(
    input  wire        vga_clk,
    input  wire        sys_rst_n,
    input  wire [9:0]  pix_x,
    input  wire [9:0]  pix_y,
    output reg  [15:0] pix_data
);

    localparam BLACK  = 16'h0000;
    localparam WHITE  = 16'hFFFF;

    // 减小X_START使字母整体左移
    localparam X_START  = 10'd120;  // 原数值可根据需要调整，如从180改为150
    localparam Y_START  = 10'd190;
    localparam LETTER_H = 10'd90;   
    localparam LETTER_W = 10'd90;   
    localparam GAP      = 10'd25;   
    localparam STROKE   = 10'd15;      
    localparam MID_STROKE = 10'd22; // 中间斜线加粗参数

          // M letter - 中间V形斜线加粗至与竖线同宽
        // M letter - 消除笔画间空隙
    wire in_m_box = (pix_x >= X_START) &&
                    (pix_x <  X_START + LETTER_W) &&
                    (pix_y >= Y_START) &&
                    (pix_y <  Y_START + LETTER_H);
    
    wire [9:0] m_x_off = pix_x - X_START;
    wire [9:0] m_y_off = pix_y - Y_START;
    
    wire m_left_bar   = (m_x_off < STROKE + 2);  // 左竖条向右扩展2像素
    wire m_right_bar  = (m_x_off >= LETTER_W - STROKE - 2); // 右竖条向左扩展2像素
    // 左斜线：起始端向左扩展，与左竖条重叠
    wire m_slope1     = (m_x_off >= STROKE - 2) && (m_x_off < LETTER_W/2) && 
                        (m_y_off >= (LETTER_H * (m_x_off - (STROKE - 2))) / (LETTER_W/2 - (STROKE - 2)) - STROKE/2) &&
                        (m_y_off <= (LETTER_H * (m_x_off - (STROKE - 2))) / (LETTER_W/2 - (STROKE - 2)) + STROKE/2) &&
                        (m_y_off >= 0);
    // 右斜线：末端向右扩展，与右竖条重叠
    wire m_slope2     = (m_x_off >= LETTER_W/2) && (m_x_off < LETTER_W - STROKE + 2) && 
                        (m_y_off >= LETTER_H - (LETTER_H * (m_x_off - LETTER_W/2)) / (LETTER_W/2 - (STROKE - 2)) - STROKE/2) &&
                        (m_y_off <= LETTER_H - (LETTER_H * (m_x_off - LETTER_W/2)) / (LETTER_W/2 - (STROKE - 2)) + STROKE/2) &&
                        (m_y_off >= 0);
    
    wire draw_m = in_m_box && (m_left_bar || m_right_bar || m_slope1 || m_slope2);
    // U letter - 扁形优化
        // U letter - 底部连贯修正
    localparam U_X_START = X_START + LETTER_W + GAP;
    wire in_u_box = (pix_x >= U_X_START) &&
                    (pix_x < U_X_START + LETTER_W) &&
                    (pix_y >= Y_START) &&
                    (pix_y < Y_START + LETTER_H);

    wire [9:0] u_x_off = pix_x - U_X_START;
    wire [9:0] u_y_off = pix_y - Y_START;
    
    wire u_left_bar   = (u_x_off < STROKE);                              // 左竖条
    wire u_right_bar  = (u_x_off >= LETTER_W - STROKE);                // 右竖条
    // 底部横条：横向覆盖整个字母宽度，纵向覆盖STROKE高度，确保与竖条无缝连接
    wire u_bottom_bar = (u_y_off >= LETTER_H - STROKE) &&              
                        (u_x_off >= 0) && (u_x_off < LETTER_W);
    
    wire draw_u = in_u_box && (u_left_bar || u_right_bar || u_bottom_bar);
    // S letter - 扁形优化
    localparam S_X_START = U_X_START + LETTER_W + GAP;
    wire in_s_box = (pix_x >= S_X_START) &&
                    (pix_x < S_X_START + LETTER_W) &&
                    (pix_y >= Y_START) &&
                    (pix_y < Y_START + LETTER_H);

    wire [9:0] s_x_off = pix_x - S_X_START;
    wire [9:0] s_y_off = pix_y - Y_START;
    
    wire s_top_bar = (s_y_off < STROKE) && 
                     (s_x_off >= STROKE);
    wire s_mid_bar = (s_y_off >= LETTER_H/2 - STROKE/2) &&
                     (s_y_off <= LETTER_H/2 + STROKE/2) &&
                     (s_x_off >= (s_y_off < LETTER_H/2 ? 0 : STROKE)) &&
                     (s_x_off <= (s_y_off < LETTER_H/2 ? LETTER_W - STROKE : LETTER_W));
    wire s_bottom_bar = (s_y_off > LETTER_H - STROKE) &&
                        (s_x_off <= LETTER_W - STROKE);
    wire s_left_top = (s_x_off < STROKE) &&
                      (s_y_off >= STROKE) &&
                      (s_y_off < LETTER_H/2);
    wire s_right_bottom = (s_x_off > LETTER_W - STROKE) &&
                          (s_y_off > LETTER_H/2) &&
                          (s_y_off <= LETTER_H - STROKE);
    
    wire draw_s = in_s_box && (s_top_bar || s_mid_bar || s_bottom_bar || s_left_top || s_right_bottom);

    // T letter - 扁形优化
    localparam T_X_START = S_X_START + LETTER_W + GAP;
    wire in_t_box = (pix_x >= T_X_START) &&
                    (pix_x < T_X_START + LETTER_W) &&
                    (pix_y >= Y_START) &&
                    (pix_y < Y_START + LETTER_H);

    wire [9:0] t_x_off = pix_x - T_X_START;
    wire [9:0] t_y_off = pix_y - Y_START;
    
    wire t_horizontal = (t_y_off < STROKE) &&                        
                        (t_x_off >= 0) && (t_x_off < LETTER_W);
    wire t_vertical   = (t_x_off >= LETTER_W/2 - STROKE/2) &&       
                        (t_x_off <= LETTER_W/2 + STROKE/2) &&
                        (t_y_off >= STROKE);
    
    wire draw_t = in_t_box && (t_horizontal || t_vertical);

    // 像素数据输出逻辑
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            pix_data <= BLACK;
        else
            pix_data <= (draw_m || draw_u || draw_s || draw_t) ? WHITE : BLACK;
    end

endmodule