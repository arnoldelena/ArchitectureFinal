
module main();

    initial begin
        $dumpfile("ppc.vcd");
        $dumpvars(0,main);
    end

    wire clk;
    wire halt = WBisSc & (WBva == 1);

    clock clock0(halt,clk);

    reg[0:63] oldpc = 0;
    reg[0:63] pc = 0;
    reg[0:63] lr = 0;
    reg[0:63] ctr = 0;
    reg[0:31] cr = 0;
    reg[0:31] xer = 0;

    reg state = 0;

    /********************/
    /* Memory interface */
    /********************/

    wire memReadEn0 = 1;
    wire [0:60]memReadAddr0 = pc[0:60];
    wire [0:63]memReadData0;
    wire memReadEn1 = XisLd | XisLdu;
    wire [0:60]memReadAddr1 = Xea[0:60];
    wire [0:63]memReadData1;
    wire memWriteEn = XisStd;
    wire [0:60]memWriteAddr = Xea[0:60];
    wire [0:63]memWriteData = XwriteData;

    mem mem0(clk,
        memReadEn0,memReadAddr0,memReadData0,
        memReadEn1,memReadAddr1,memReadData1,
        memWriteEn,memWriteAddr,memWriteData);

    /********/
    /* regs */
    /********/

    wire regReadEn0 = Dread0;
    wire [0:4]regReadAddr0 = Dreg0;
    wire [0:63]regReadData0;

    wire regReadEn1 = Dread1;
    wire [0:4]regReadAddr1 = Dreg1;
    wire [0:63]regReadData1;

    wire regWriteEn0 = WBwrite0;
    wire [0:4]regWriteAddr0 = WBwrite0Target;
    wire [0:63]regWriteData0 = writeData;

    wire regWriteEn1 = WBwrite1;
    wire [0:4]regWriteAddr1 = WBra;
    wire [0:63]regWriteData1 = WBea;

    regs gprs(clk,
       /* Read port #0 */
       regReadEn0,
       regReadAddr0, 
       regReadData0,

       /* Read port #1 */
       regReadEn1,
       regReadAddr1, 
       regReadData1,

       /* Write port #0 */
       regWriteEn0,
       regWriteAddr0, 
       regWriteData0,

       /* Write port #1 */
       regWriteEn1,
       regWriteAddr1, 
       regWriteData1
    );

endmodule
