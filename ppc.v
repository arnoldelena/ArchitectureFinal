
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

    // D0

    reg[0:31] D0inst = 0;

    wire[0:5] D0opcode = D0inst[0:5];
    wire[0:4] D0rs = D0inst[6:10];
    wire[0:4] D0rt = D0inst[6:10];
    wire[0:4] D0ra = D0inst[11:15];
    wire[0:4] D0rb = D0inst[16:20];
    wire[0:7] D0lev = D0inst[20:26];
    wire[0:8] D0xop9 = D0inst[22:30];
    wire[0:9] D0xop10 = D0inst[21:30];
    wire[0:9] D0spr = {D0inst[16:20],D0inst[11:15]};

    wire D0isOr = (D0opcode == 31) & (D0xop10 == 444);
    wire D0isAdd = (D0opcode == 31) & (D0xop9 == 266);
    wire D0isMTSpr = (D0opcode == 31) & (D0xop10 == 467) & ((D0spr == 1) || (D0spr == 8) || (D0spr == 9));
    wire D0isMTCrf = (D0opcode == 31) & (D0xop10 == 144);
    wire D0isLd = (D0opcode == 58) & (D0inst[30:31] == 0);
    wire D0isLdu = (D0opcode == 58) & (D0inst[30:31] == 1) & (D0ra != 0) & (D0ra != D0rt);
    wire D0isStd = D0opcode == 62;
    wire D0isAddi = D0opcode == 14;
    wire D0isSc = (D0opcode == 17) & ((D0lev == 0) | (D0lev == 1)) & D0inst[30];

    // D1

    reg[0:31] D1inst = 0;

    wire[0:5] D1opcode = D1inst[0:5];
    wire[0:4] D1rs = D1inst[6:10];
    wire[0:4] D1rt = D1inst[6:10];
    wire[0:4] D1ra = D1inst[11:15];
    wire[0:4] D1rb = D1inst[16:20];
    wire[0:7] D1lev = D1inst[20:26];
    wire[0:8] D1xop9 = D1inst[22:30];
    wire[0:9] D1xop10 = D1inst[21:30];
    wire[0:9] D1spr = {D1inst[16:20],D0inst[11:15]};

    wire D1isOr = (D1opcode == 31) & (D1xop10 == 444);
    wire D1isAdd = (D1opcode == 31) & (D1xop9 == 266);
    wire D1isMTSpr = (D1opcode == 31) & (D1xop10 == 467) & ((D1spr == 1) || (D1spr == 8) || (D1spr == 9));
    wire D1isMTCrf = (D1opcode == 31) & (D1xop10 == 144);
    wire D1isLd = (D1opcode == 58) & (D1inst[30:31] == 0);
    wire D1isLdu = (D1opcode == 58) & (D1inst[30:31] == 1) & (D1ra != 0) & (D1ra != D1rt);
    wire D1isStd = D1opcode == 62;
    wire D1isAddi = D1opcode == 14;
    wire D1isSc = (D1opcode == 17) & ((D1lev == 0) | (D1lev == 1)) & D1inst[30];

    /************/
    /* Exectute */
    /************/

    // X0

    reg[0:31] X0inst = 0;

    wire[0:5] X0opcode = X0inst[0:5];
    wire[0:4] X0rt = X0inst[6:10];
    wire[0:4] X0rs = X0inst[6:10];
    wire[0:4] X0ra = X0inst[11:15];
    wire[0:4] X0rb = X0inst[16:20];
    wire[0:7] X0crm = X0inst[12:19];
    wire[0:7] X0lev = X0inst[20:26];
    wire[0:8] X0xop9 = X0inst[22:30];
    wire[0:9] X0xop10 = X0inst[21:30];
    wire[0:9] X0spr = {X0inst[16:20],X0inst[11:15]};
    wire[0:63] X0ds = {{48{X0inst[16]}},{X0inst[16:29] << 2}};

    wire X0oe = X0inst[21];
    wire X0rc = X0inst[31];

    wire X0isOr = (X0opcode == 31) & (X0xop10 == 444);
    wire X0isAdd = (X0opcode == 31) & (X0xop9 == 266);
    wire X0isMTSpr = (X0opcode == 31) & (X0xop10 == 467) & ((X0spr == 1) || (X0spr == 8) || (X0spr == 9));
    wire X0isMFSpr = (X0opcode == 31) & (X0xop10 == 339) & ((X0spr == 1) || (X0spr == 8) || (X0spr == 9));
    wire X0isMTCrf = (X0opcode == 31) & (X0xop10 == 144);
    wire X0isAddi = X0opcode == 14;
    wire X0isLd = (X0opcode == 58) & (X0inst[30:31] == 0);
    wire X0isLdu = (X0opcode == 58) & (X0inst[30:31] == 1) & (X0ra != 0) & (X0ra != X0rt);
    wire X0isStd = X0opcode == 62;
    wire X0isSc = (X0opcode == 17) & ((X0lev == 0) | (X0lev == 1)) & X0inst[30];

    // X1

    reg[0:31] X1inst = 0;

    wire[0:5] X1opcode = X1inst[0:5];
    wire[0:4] X1rt = X1inst[6:10];
    wire[0:4] X1rs = X1inst[6:10];
    wire[0:4] X1ra = X1inst[11:15];
    wire[0:4] X1rb = X1inst[16:20];
    wire[0:7] X1crm = X1inst[12:19];
    wire[0:7] X1lev = X1inst[20:26];
    wire[0:8] X1xop9 = X1inst[22:30];
    wire[0:9] X1xop10 = X1inst[21:30];
    wire[0:9] X1spr = {X1inst[16:20],X1inst[11:15]};
    wire[0:63] X1ds = {{48{X1inst[16]}},{X1inst[16:29] << 2}};

    wire X1oe = X1inst[21];
    wire X1rc = X1inst[31];

    wire X1isOr = (X1opcode == 31) & (X1xop10 == 444);
    wire X1isAdd = (X1opcode == 31) & (X1xop9 == 266);
    wire X1isMTSpr = (X1opcode == 31) & (X1xop10 == 467) & ((X1spr == 1) || (X1spr == 8) || (X1spr == 9));
    wire X1isMFSpr = (X1opcode == 31) & (X1xop10 == 339) & ((X1spr == 1) || (X1spr == 8) || (X1spr == 9));
    wire X1isMTCrf = (X1opcode == 31) & (X1xop10 == 144);
    wire X1isAddi = X1opcode == 14;
    wire X1isLd = (X1opcode == 58) & (X1inst[30:31] == 0);
    wire X1isLdu = (X1opcode == 58) & (X1inst[30:31] == 1) & (X1ra != 0) & (X1ra != X1rt);
    wire X1isStd = X1opcode == 62;
    wire X1isSc = (X1opcode == 17) & ((X1lev == 0) | (X1lev == 1)) & X1inst[30];

    /**************/
    /* Write Back */
    /**************/

    // WB0

    reg[0:31] WB0inst = 0;

    // WB1

    reg[0:31] WB1inst = 0;

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
