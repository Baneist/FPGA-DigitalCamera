module ov2640_data_driver(
    input               rst                 ,
    input               pclk                ,
    input               href                ,
    input               vsync               ,
    input       [7:0]   data_in             ,
    output reg  [11:0]  data_out            ,
    output reg          wr_en               ,
    output reg  [18:0]  ram_out_addr    
);
    
    /**************************************************************
        �Ĵ�������
    ***************************************************************/
    reg  [15:0]         ori_color = 0       ;
    reg  [18:0]         ram_next_addr = 0   ;
    reg  [1:0]          bit_status = 0      ;   //���ںϲ���ɫ��
    initial ram_out_addr <= 0;
    
    /**************************************************************
        ���ݺϲ�+ori_colorתRGB444
    ***************************************************************/
    always@ (posedge pclk) begin
        if(vsync == 0) begin
            ram_out_addr <= 0;
            ram_next_addr <= 0;
            bit_status <= 0;
        end else begin
            data_out <= { ori_color[15:12], ori_color[10:7], ori_color[4:1] };
            ram_out_addr <= ram_next_addr;
            wr_en <= bit_status[1];
            bit_status <= {bit_status[0], (href && !bit_status[0])};//���Ǹߵ�ƽ��Ч
            ori_color <= {ori_color[7:0], data_in};    
            if(bit_status[1] == 1)
                ram_next_addr <= ram_next_addr+1;
        end
    end

endmodule