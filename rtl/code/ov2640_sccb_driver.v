module ov2640_sccb_driver(
    input               clk         ,
    input               rst         ,
    inout               sio_d       ,
    output reg          sio_c       ,
    input               cfg_ok      ,
    output reg          sccb_ok     ,
    input [7:0]         slave_id    ,
    input [7:0]         cfg_addr    ,
    input [7:0]         value
);

    /**************************************************************
        �Ĵ����������ʼ��
    ***************************************************************/
    reg  [20:0]         cfg_cnt = 0 ;
    reg                 sio_d_tmp   ;
    reg  [31:0]         data_temp   ;
    initial sccb_ok <= 0;
    
    /**************************************************************
        �����ļ�������
    ***************************************************************/
    always @ (posedge clk)
    begin
        if(cfg_cnt == 0)
            cfg_cnt <= cfg_ok;
        else
            if(cfg_cnt[20:11] == 31)
                cfg_cnt <= 0;
            else
                cfg_cnt <= cfg_cnt + 1;
    end

    /**************************************************************
        SCCB��ʼ������ź�����
    ***************************************************************/
    always @ (posedge clk)
        sccb_ok <= (cfg_cnt == 0) && (cfg_ok==1);

    /**************************************************************
        SIOC����ͨ���ź�����
    ***************************************************************/
    always @ (posedge clk) begin
        if(cfg_cnt[20:11] == 0)
            sio_c <= 1;
        else if(cfg_cnt[20:11]==1) begin
            if(cfg_cnt[10:9] == 2'b11)
                sio_c <= 0;
            else
                sio_c <= 1;
        end else if(cfg_cnt[20:11] == 29) begin
            if(cfg_cnt[10:9] == 2'b00)
                sio_c <= 0;
            else
                sio_c <= 1;
        end else if(cfg_cnt[20:11] == 30 || cfg_cnt[20:11] == 31)
            sio_c <= 1;
        else begin
            if(cfg_cnt[10:9] == 2'b00)
                sio_c <= 0;
            else if(cfg_cnt[10:9] == 2'b01)
                sio_c <= 1;
            else if(cfg_cnt[10:9] == 2'b01)
                sio_c <= 1;
            else if(cfg_cnt[10:9] == 2'b11)
                sio_c <= 0;
        end
    end

    /**************************************************************
        SIOD����ͨ���ź����
    ***************************************************************/
    always @ (posedge clk) begin
        if(cfg_cnt[20:11] == 10 || cfg_cnt[20:11] == 19 || cfg_cnt[20:11] == 28)
            sio_d_tmp <= 0;
        else
            sio_d_tmp <= 1;
    end
    
    /**************************************************************
        �����ļ������������
    ***************************************************************/
    always @ (posedge clk) begin
        if(rst)
            data_temp<=32'hffffffff;
        else
        begin
            if(cfg_cnt==0&&cfg_ok==1)
                data_temp<={2'b10,slave_id,1'bx,cfg_addr,1'bx,value,1'bx,3'b011};
            else if(cfg_cnt[10:0]==0)
                data_temp<={data_temp[30:0],1'b1};
        end
    end
    assign sio_d=sio_d_tmp?data_temp[31]:'bz;//��̬�ſ���
    
endmodule