
module main();

    initial begin
        $dumpfile("ppc.vcd");
        $dumpvars(0,main);
    end

    wire clk;
    wire halt;

    clock clock0(halt,clk);

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
    wire memReadEn1;
    wire [0:60]memReadAddr1;
    wire [0:63]memReadData1;
    wire memWriteEn;
    wire [0:60]memWriteAddr;
    wire [0:63]memWriteData;

    mem mem0(clk,
        memReadEn0,memReadAddr0,memReadData0,
        memReadEn1,memReadAddr1,memReadData1,
        memWriteEn,memWriteAddr,memWriteData);

    /********/
    /* regs */
    /********/

    wire regReadEn0;
    wire [0:4]regReadAddr0;
    wire [0:63]regReadData0;

    wire regReadEn1;
    wire [0:4]regReadAddr1;
    wire [0:63]regReadData1;

    wire regWriteEn0;
    wire [0:4]regWriteAddr0;
    wire [0:63]regWriteData0;

    wire regWriteEn1;
    wire [0:4]regWriteAddr1;
    wire [0:63]regWriteData1;

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

    reg[0:63][0:31] queue = 0;
    reg[0:5] tail = 0;
    reg[0:5] head = 0;

    /*********/
    /* Fetch */
    /*********/

    wire[0:63] fetch = ~state ? 0 : memReadData0; // Might want to stop fetching at some point.

    /**********/
    /* Decode */
    /**********/

    reg[0:31] Dinst0 = 0;
    reg[0:31] Dinst1 = 0;

    /************/
    /* Exectute */
    /************/

    reg[0:31] Xinst0 = 0;
    reg[0:31] Xinst1 = 0;

    /**************/
    /* Write Back */
    /**************/

    reg[0:31] WBinst0 = 0;
    reg[0:31] WBinst1 = 0;

    /**********/
    /* Update */
    /**********/

    wire[0:5] nextHead = canParallel ? head + 2 : head + 1;
    wire[0:5] nextTail = state ? tail + 2 : tail;
    wire[0:63] pcPlus4 = pc + 4;
    wire[0:63] nextpc = pcPlus4;
    always @(posedge clk) begin
        queue[tail + 1] = fetch[32:63];
        queue[tail] = fetch[0:31];
        WBinst1 <= Xinst1;
        WBinst0 <= Xinst0;
        Xinst1 <= Dinst1;
        Xinst0 <= Dinst0;
        Dinst1 <= queue[head + 1];
        Dinst0 <= queue[head];
        head <= nextHead;
        tail <= nextTail;
        pc <= nextpc;
        state <= 1;
    end

endmodule
