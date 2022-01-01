module camera_top(
    input               sys_clk         ,
    input               sys_rst         ,

    //����ͷ
    output              camera_sio_c    ,   
    inout               camera_sio_d    ,   
    output              camera_reset    ,   
    output              camera_pwdn     ,   
    output              camera_xclk     ,   
    input               camera_pclk     ,
    input               camera_href     ,
    input               camera_vsync    ,   
    input  [7:0]        camera_data     ,

    //�����������ã�
    input  [7:0]        key             ,
    output [7:0]        led             ,

    //�߶������
    output [7:0]        seg_ena         ,
    output [7:0]        seg_ctl         ,

    //VGA
    output [11:0]       vga_rgb         ,
    output              vga_hsync       ,
    output              vga_vsync       ,

    //����
    input               bluetooth_rxd   ,
    input               bluetooth_txd   ,

    //SD��
    input               sd_cd           ,
    output              sd_reset        ,
    output              sd_sck          ,
    output              sd_cmd          ,
    inout  [3:0]        sd_data         
);

    /**************************************************************
    ������Ĵ�������
    ***************************************************************/
    //��Ƶʱ��
    wire                clk_sd_50m          ;      //SD��д��ʱ�ӣ� 50mhz
    wire                clk_sd_50m_180deg   ;      //SD����ȡʱ�ӣ� 50mhz
    wire                clk_vga_24m         ;      //VGAд��ʱ�ӣ� 24mhz
    wire                clk_sccb_init_25m   ;      //SCCB���ó�ʼ��ʱ�ӣ�25mhz

    //SPI����
    wire                sd_clk              ;      //SPIʱ��
    wire                sd_cs               ;      //SPIƬѡ������
    wire                sd_mosi             ;      //SPI����������
    wire                sd_miso             ;      //SPI����������

    //SD��д����
    wire                wr_start_en         ;      //��ʼдSD�������ź�
    wire    [31:0]      wr_sec_addr         ;      //д����������ַ    
    wire    [15:0]      wr_data             ;      //д����            
    wire                rd_start_en         ;      //��ʼдSD�������ź�
    wire    [31:0]      rd_sec_addr         ;      //������������ַ  

   //SD��������
    wire                wr_busy             ;      //д����æ�ź�
    wire                wr_req              ;      //д���������ź�
    wire                rd_busy             ;      //��æ�ź�
    wire                rd_val_en           ;      //���ݶ�ȡ��Чʹ���ź�
    wire    [15:0]      rd_val_data         ;      //������
    wire                sd_init_done        ;      //SD����ʼ������ź�

    //����ģʽѡ��
    wire                photo_out_ena       ;      //��Ƭ���ʹ��
    wire    [3:0]       select_photo_no     ;      //��Ƭλѡ���ַ
    wire                get_photo_mode      ;      //��ȡģʽѡ��
    wire                caught_photo_mode   ;      //��Ӱģʽѡ��
    wire                camera_show_mode    ;      //ȡ��ģʽѡ��
    wire                camera_init_done    ;      //����ͷ��ʼ�����ʹ��
    //��Ƭ��д��ַ
    wire    [18:0]      sd_wr_ram_addr      ;      //SD��д���ַ
    wire    [11:0]      photo_out_data      ;      //��Ƭ������Ϣ
    wire    [18:0]      photo_out_position  ;      //��Ƭ����λ��
    wire    [18:0]      sd_rd_ram_addr      ;      //��Ƭд��λ��

    //RAM��д��ַ����
    wire    [11:0]      ram_data            ;       //�����д����
    wire    [18:0]      ram_addr            ;       //�����д��ַ
    wire    [11:0]      vga_rd_data         ;       //VGA������
    wire    [18:0]      rd_addr             ;       //VGA����ַ
    wire    [18:0]      baddr               ;       //RAM�˿�Bѡ���ַ
    wire    [11:0]      mem_douta           ;       //RAM�˿�A����ź�
    wire                wea_enable          ;       //RAM�˿�A��дѡ���ź�
    wire                wr_en               ;       //����д��Ч�ź�
    wire    [11:0]      vga_color_in        ;       //vga��ɫ�����ź�
    wire    [11:0]      doutb               ;       //RAM�˿�B����ź�

    /**************************************************************
    ��������
    ***************************************************************/
    //SDתSPI
    assign sd_reset = 0;
    assign sd_data[1] = 1;
    assign sd_data[2] = 1;
    assign sd_data[3] = sd_cs;
    assign sd_cmd = sd_mosi;
    assign sd_sck = sd_clk;
    assign sd_miso = sd_data[0];
    
    //LED״ָ̬ʾ������
    assign led[0] = camera_show_mode;
    assign led[1] = caught_photo_mode;
    assign led[2] = get_photo_mode;
    assign led[3] = sd_init_done;
    assign led[4] = camera_init_done;
    assign led[5] = ~sd_cd;

    //˫��RAM��ַѡ��
    assign wr_data = {4'b0, mem_douta};
    assign baddr = (rd_val_en ? sd_rd_ram_addr : ( caught_photo_mode ? sd_wr_ram_addr : rd_addr));
    assign mem_douta = doutb;
    assign vga_rd_data = doutb;
    assign wea_enable = wr_en & camera_show_mode;
    assign vga_color_in = (caught_photo_mode ? 12'hf00 : vga_rd_data);

    /**************************************************************
    ʵ������Ƶ��
    ***************************************************************/
    clk_wiz_0 clk_wiz_div(
        .clk_in1            (sys_clk)               ,
        .clk_out1           (clk_vga_24m)           ,
        .clk_out2           (clk_sccb_init_25m)     ,
        .clk_out3           (clk_sd_50m)            ,
        .clk_out4           (clk_sd_50m_180deg)
    );

    /**************************************************************
    ʵ��������ͷ��ʼ��ģ��
    ***************************************************************/
    ov2640_sccb_cfg_init ov2640_sccb_cfg_init_0(
        .clk                (clk_sccb_init_25m)     ,
        .sio_c              (camera_sio_c)          ,
        .sio_d              (camera_sio_d)          ,
        .reset              (camera_reset)          ,
        .pwdn               (camera_pwdn)           ,  
        .rst                (sys_rst)               ,
        .camera_init_done   (camera_init_done)      ,
        .xclk               (camera_xclk)
    );

    /**************************************************************
    ʵ��������ͷ���ݴ���ģ��
    ***************************************************************/
    ov2640_data_driver ov2640_data_driver_0(
        .rst                (sys_rst)               ,
        .pclk               (camera_pclk)           ,
        .href               (camera_href)           ,
        .vsync              (camera_vsync)          ,
        .data_in            (camera_data)           ,
        .data_out           (ram_data)              ,
        .wr_en              (wr_en)                 ,
        .ram_out_addr       (ram_addr)
    );

    /**************************************************************
    ʵ����RAMģ��
    ***************************************************************/
    blk_mem_gen_0 ram_0(
        .clka               (sys_clk)               ,
        .ena                (1'b1)                  ,
        .wea                (wea_enable)            ,
        .addra              (ram_addr)              ,
        .dina               (ram_data)              ,
        .clkb               (sys_clk)               ,
        .enb                (1'b1)                  ,
        .addrb              (baddr)                 ,
        .dinb               (rd_val_data[11:0])     ,
        .doutb              (doutb)                 ,
        .web                (rd_val_en)
    );

    /**************************************************************
    ʵ����VGA���ģ��
    ***************************************************************/
    vga_driver vga(
        .vga_clk            (clk_vga_24m)           ,
        .sys_rst_n          (~sys_rst)              ,
        .pixel_data         (vga_color_in)          ,
        .pixel_addr         (rd_addr)               ,
        .vga_hs             (vga_hsync)             ,
        .vga_vs             (vga_vsync)             ,
        .vga_rgb            (vga_rgb)            
    );

    
    /**************************************************************
    ʵ��������״̬ѡ��ģ��
    ***************************************************************/
    bluetooth_mode_control bluetooth_mode_control_0(
        .sys_clk            (sys_clk)               ,
        .sys_rst            (sys_rst)               ,
        .bluetooth_rxd      (bluetooth_txd)         ,
        .get_photo_mode     (get_photo_mode)        ,
        .caught_photo_mode  (caught_photo_mode)     ,
        .camera_show_mode   (camera_show_mode)      ,
        .select_photo_no    (select_photo_no)
    );

    /**************************************************************
    ʵ����7�������״̬��ʾģ��
    ***************************************************************/
    display7 display7_0( 
		.clk                (sys_clk)               ,
		.led1               (sd_wr_ram_addr[3:0])   ,
		.led2               (sd_wr_ram_addr[7:4])   ,
		.led3               (sd_wr_ram_addr[11:8])  ,
		.led4               (sd_wr_ram_addr[15:12]) ,
		.led5               ({1'b0,sd_wr_ram_addr[18:16]}),
		.led6               (4'b0)                  ,
		.led7               (4'b0)                  ,
		.led8               (select_photo_no)       ,
		.ena                (seg_ena)               ,
		.ctl                (seg_ctl)
	);

    /**************************************************************
    ʵ����SD������ģ��
    ***************************************************************/
    sd_ctrl sd_ctrl_0(
        .clk_ref            (clk_sd_50m)            ,
        .clk_ref_180deg     (clk_sd_50m_180deg)     ,
        .rst_n              (~sys_rst)              ,
        .sd_miso            (sd_miso)               ,
        .sd_clk             (sd_clk)                ,   
        .sd_cs              (sd_cs)                 ,
        .sd_mosi            (sd_mosi)               ,
        .wr_start_en        (wr_start_en)           ,
        .wr_sec_addr        (wr_sec_addr)           ,
        .wr_data            (wr_data)               ,
        .wr_busy            (wr_busy)               ,
        .wr_req             (wr_req)                ,
        .rd_start_en        (rd_start_en)           ,
        .rd_sec_addr        (rd_sec_addr)           ,
        .rd_busy            (rd_busy)               ,
        .rd_val_en          (rd_val_en)             ,
        .rd_val_data        (rd_val_data)           ,    
        .sd_init_done       (sd_init_done)          
    );

    /**************************************************************
    ʵ����SD����ȡ��Ƭģ��
    ***************************************************************/
    sd_read_photo sd_read_photo_0(
        .clk                (clk_sd_50m)            ,
        .get_photo_mode     (get_photo_mode)        ,
        .rd_start_en        (rd_start_en)           ,
        .select_photo_no    (select_photo_no)       ,
        .rd_busy            (rd_busy)               ,
        .rd_val_en          (rd_val_en)             ,
        .sd_rd_ram_addr     (sd_rd_ram_addr)        ,
        .rd_sec_addr        (rd_sec_addr)
    );

    /**************************************************************
    ʵ����SD��д����Ƭģ��
    ***************************************************************/
    sd_write_photo sd_write_photo_0(
        .clk                (clk_sd_50m)            ,
        .caught_photo_mode  (caught_photo_mode)     ,
        .select_photo_no    (select_photo_no)       ,
        .wr_start_en        (wr_start_en)           ,
        .wr_sec_addr        (wr_sec_addr)           ,
        .wr_busy            (wr_busy)               ,
        .wr_req             (wr_req)                ,
        .sd_wr_ram_addr     (sd_wr_ram_addr)
    );
endmodule
