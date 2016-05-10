//make regs.bin work...
module main();

    initial begin
        $dumpfile("ppc.vcd");
        $dumpvars(0,main);
    end

    wire clk;
    wire halt = (WB0isSc & (WB0va == 1)) | (WB1isSc & (WB1va == 1));

    clock clock0(halt,clk);

    reg[0:63] pc = 0;
    reg[0:63] lr = 0;
    reg[0:63] ctr = 0;
    reg[0:31] cr = 0;
    reg[0:31] xer = 0; //0 is SO 

    reg state = 0;
    reg state1 = 0;
    reg weight = 0;
    reg ignore = 0;
    reg ignore1 = 0;
    reg[0:63] TruePc = 0;

    /********************/
    /* Memory interface */
    /********************/

    wire memReadEn0 = 1;
    wire [0:60]memReadAddr0 = pc[0:60];
    wire [0:63]memReadData0;
    wire memReadEn1 = X0isLd|X0isLdu|X1isLd|X1isLdu;
    wire [0:60]memReadAddr1 = X1isLd | X1isLdu ? X1ea[0:60] : X0isLd | X0isLdu ? X0ea[0:60] : 0;
    wire [0:63]memReadData1;
    wire memWriteEn = 0;
    wire [0:60]memWriteAddr = 0;
    wire [0:63]memWriteData;

    mem mem0(clk,
        memReadEn0,memReadAddr0,memReadData0,
        memReadEn1,memReadAddr1,memReadData1,
        memWriteEn,memWriteAddr,memWriteData);

    /********/
    /* regs */
    /********/

    wire regReadEn0 = Dread0;
    wire [0:4]regReadAddr0 = DreadA;
    wire [0:63]regReadData0;

    wire regReadEn1 = Dread1;
    wire [0:4]regReadAddr1 = DreadB;
    wire [0:63]regReadData1;

    wire regWriteEn0 = WBwrite0;
    wire [0:4]regWriteAddr0 = WBwriteA;
    wire [0:63]regWriteData0 = WBwriteDataA;

    wire regWriteEn1 = WBwrite1;
    wire [0:4]regWriteAddr1 = WBwriteB;
    wire [0:63]regWriteData1 = WBwriteDataB;

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

    reg[0:31] queue [0:64];
    reg[0:5] tail = 0;
    reg[0:5] head = 0;

    integer i;
    initial begin 
        for(i=0;i<64;i=i+1) begin
            queue[i]<=0;
        end
    end

    /*********/
    /* Fetch */
    /*********/

    wire[0:63] fetch = ~state ? 0 : memReadData0; // Might want to stop fetching at some point.

    /**********/
    /* Decode */
    /**********/

    // D0

    wire[0:31] D0inst = queue[head];

    wire[0:5] D0opcode = D0inst[0:5];
    wire[0:4] D0rs = D0inst[6:10];
    wire[0:4] D0rt = D0inst[6:10];
    wire[0:4] D0ra = D0inst[11:15];
    wire[0:4] D0rb = D0inst[16:20];
    wire[0:7] D0lev = D0inst[20:26];
    wire[0:8] D0xop9 = D0inst[22:30];
    wire[0:9] D0xop10 = D0inst[21:30];
    wire[0:9] D0spr = {D0inst[16:20],D0inst[11:15]};
    wire D0aa = D0inst[30];
    wire[0:63] D0li = {{38{D0inst[6]}},D0inst[6:29],2'b00};
    wire[0:63] D0bd = {{48{D0inst[16]}},D0inst[16:29],2'b00};

    wire D0isOr = (D0opcode == 31) & (D0xop10 == 444);
    wire D0isAdd = (D0opcode == 31) & (D0xop9 == 266);
    wire D0isMTSpr = (D0opcode == 31) & (D0xop10 == 467) & ((D0spr == 1) || (D0spr == 8) || (D0spr == 9));
    wire D0isMTCrf = (D0opcode == 31) & (D0xop10 == 144);
    wire D0isLd = (D0opcode == 58) & (D0inst[30:31] == 0);
    wire D0isLdu = (D0opcode == 58) & (D0inst[30:31] == 1) & (D0ra != 0) & (D0ra != D0rt);
    wire D0isStd = D0opcode == 62;
    wire D0isAddi = D0opcode == 14;
    wire D0isSc = (D0opcode == 17) & ((D0lev == 0) | (D0lev == 1)) & D0inst[30];
    wire D0isB = D0opcode == 18;
    wire D0isBc = D0opcode == 16;
    wire D0isBclr = (D0opcode==19) & (D0xop10==16);

   //added check for if ld has an ra==0 
    wire D0read0 = D0isAdd|(D0isAddi&(D0ra!=0))|D0isOr|(D0isLd&(D0ra!=0))|D0isLdu|D0isSc;
    wire D0read1 = D0isAdd|D0isOr|D0isSc;
    wire[0:4] D0readA = D0isOr?D0rs:
                        D0isSc?0:
                        D0ra;
    wire[0:4] D0readB = D0isSc?3:D0rb;
    wire D0write0 = D0isAdd|D0isAddi|D0isOr|D0isLd|D0isLdu;
    wire D0write1 = D0isLdu;
    wire[0:4] D0writeA = D0isOr?D0ra:D0rt;
    wire[0:4] D0writeB = D0ra;

    // D1

    wire[0:31] D1inst = queue[head+1];

    wire[0:5] D1opcode = D1inst[0:5];
    wire[0:4] D1rs = D1inst[6:10];
    wire[0:4] D1rt = D1inst[6:10];
    wire[0:4] D1ra = D1inst[11:15];
    wire[0:4] D1rb = D1inst[16:20];
    wire[0:7] D1lev = D1inst[20:26];
    wire[0:8] D1xop9 = D1inst[22:30];
    wire[0:9] D1xop10 = D1inst[21:30];
    wire[0:9] D1spr = {D1inst[16:20],D0inst[11:15]};
    wire D1aa = D1inst[30];
    wire[0:63] D1li = {{38{D1inst[6]}},D1inst[6:29],2'b00};
    wire[0:63] D1bd = {{48{D1inst[16]}},D1inst[16:29],2'b00};

   

    wire D1isOr = (D1opcode == 31) & (D1xop10 == 444);
    wire D1isAdd = (D1opcode == 31) & (D1xop9 == 266);
    wire D1isMTSpr = (D1opcode == 31) & (D1xop10 == 467) & ((D1spr == 1) || (D1spr == 8) || (D1spr == 9));
    wire D1isMTCrf = (D1opcode == 31) & (D1xop10 == 144);
    wire D1isLd = (D1opcode == 58) & (D1inst[30:31] == 0);
    wire D1isLdu = (D1opcode == 58) & (D1inst[30:31] == 1) & (D1ra != 0) & (D1ra != D1rt);
    wire D1isStd = D1opcode == 62;
    wire D1isAddi = D1opcode == 14;
    wire D1isSc = (D1opcode == 17) & ((D1lev == 0) | (D1lev == 1)) & D1inst[30];
    wire D1isB = D1opcode == 18;
    wire D1isBc = D1opcode == 16;
    wire D1isBclr = (D1opcode==19) & (D1xop10==16);

    wire D1read0 = D1isAdd|(D1isAddi&(D1ra!=0))|D1isOr|(D1isLd&(D1ra!=0))|D1isLdu|D1isSc;
    wire D1read1 = D1isAdd|D1isOr|D1isSc; 
    wire[0:4] D1readA = D1isOr?D1rs:
                        D1isSc?0:
                        D1ra;
    wire[0:4] D1readB = D1isSc?3:D1rb;
    wire D1write0 = D1isAdd|D1isAddi|D1isOr|D1isLd|D1isLdu;
    wire D1write1 = D1isLdu;
    wire[0:4] D1writeA = D1isOr?D1ra:D1rt;
    wire[0:4] D1writeB = D1ra;


    wire D0isBranching = D0isB|((D0isBc|D0isBclr) & D0ctrOk & D0condOk); 
    wire D1isBranching = D1isB|((D1isBc|D1isBclr) & D1ctrOk & D1condOk);
    wire D0ctrOk = D0inst[8]|((ctr-1 != 0)^D0inst[9]);
    wire D1ctrOk = D1inst[8]|((ctr-1 != 0)^D1inst[9]);

    wire [0:31] TrueCr = (X1isAdd|X1isOr) & X1rc?X1newCr: (X0isAdd|X0isOr)&X0rc?X0newCr:cr;
    wire D0condOk = D0inst[6]|(TrueCr[D0ra]==D0inst[7]);
    wire D1condOk = D1inst[6]|(TrueCr[D1ra]==D1inst[7]);  
    wire [0:63] D0branchTarget = D0isBc?D0bcTarget:
                        D0isB?D0bTarget:
                        D0isBclr?D0bclrTarget:
                        0;
    wire [0:63] D1branchTarget = D1isBc?D1bcTarget:
                        D1isB?D1bTarget:
                        D1isBclr?D1bclrTarget:
                        0;

    //need to do if the parallel instruction sets the cr, then branch in execute stage
    wire [0:63] D0bTarget = D0aa?D0li:D0li+TruePc;
    wire [0:63] D0bclrTarget = {lr[0:61],2'b00};
    wire [0:63] D0bcTarget = D0aa?D0bd:D0bd+TruePc;

    wire [0:63] D1bTarget = D1aa?D1li:D1li+TruePc+4;
    wire [0:63] D1bclrTarget = (D1isB|D1isBc|D1isBclr)&(D1inst[31])?TruePc+4:{lr[0:61],2'b00};
    wire [0:63] D1bcTarget = D1aa ?D1bd: D0inst==0?D1bd+TruePc:D1bd+TruePc+4;
 
    // Data Hazard/Forwarding??

    // D0 reads X writes

    //AEQ = register A equals ...
    //AUX = register A updates X??
    //Xwrite0 is enable built
    wire D0readAEQXwriteA = D0readA == XwriteA;
    wire D0readAUXwriteA = D0readAEQXwriteA & Xwrite0;
    wire D0readAEQXwriteB = D0readA == XwriteB;
    wire D0readAUXwriteB = D0readAEQXwriteB & Xwrite1;
    wire D0readBEQXwriteA = D0readB == XwriteA;
    wire D0readBUXwriteA = D0readBEQXwriteA & Xwrite0;
    wire D0readBEQXwriteB = D0readB == XwriteB;
    wire D0readBUXwriteB = D0readBEQXwriteB & Xwrite1;

    wire D0read0Xwrite = (D0readAUXwriteA | D0readAUXwriteB);
    wire D0read1Xwrite = (D0readBUXwriteA | D0readBUXwriteB);

    // D0 reads X reads
    // RX means reads X, checking enable bit
    wire D0readAEQXreadA = D0readA == XreadA;
    wire D0readARXreadA = D0readAEQXreadA & Xread0;
    wire D0readAEQXreadB = D0readA == XreadB;
    wire D0readARXreadB = D0readAEQXreadB & Xread1;
    wire D0readBEQXreadA = D0readB == XreadA;
    wire D0readBRXreadA = D0readBEQXreadA & Xread0;
    wire D0readBEQXreadB = D0readB == XreadB;
    wire D0readBRXreadB = D0readBEQXreadB & Xread1;

    wire D0read0Xread = (D0readARXreadA | D0readARXreadB);
    wire D0read1Xread = (D0readBRXreadA | D0readBRXreadB);

    // D0 reads WB writes
    wire D0readAEQWBwriteA = D0readA == WBwriteA;
    wire D0readAUWBwriteA = D0readAEQWBwriteA & WBwrite0;
    wire D0readAEQWBwriteB = D0readA == WBwriteB;
    wire D0readAUWBwriteB = D0readAEQWBwriteB & WBwrite1;
    wire D0readBEQWBwriteA = D0readB == WBwriteA;
    wire D0readBUWBwriteA = D0readBEQWBwriteA & WBwrite0;
    wire D0readBEQWBwriteB = D0readB == WBwriteB;
    wire D0readBUWBwriteB = D0readBEQWBwriteB & WBwrite1;

    wire D0read0WBwrite = (D0readAUWBwriteA | D0readAUWBwriteB);
    wire D0read1WBwrite = (D0readBUWBwriteA | D0readBUWBwriteB);

    // D0 reads WB reads
    wire D0readAEQWBreadA = D0readA == WBreadA;
    wire D0readARWBreadA = D0readAEQWBreadA & WBread0;
    wire D0readAEQWBreadB = D0readA == WBreadB;
    wire D0readARWBreadB = D0readAEQWBreadB & WBread1;
    wire D0readBEQWBreadA = D0readB == WBreadA;
    wire D0readBRWBreadA = D0readBEQWBreadA & WBread0;
    wire D0readBEQWBreadB = D0readB == WBreadB;
    wire D0readBRWBreadB = D0readBEQWBreadB & WBread1;

    wire D0read0WBread = (D0readARWBreadA | D0readARWBreadB);
    wire D0read1WBread = (D0readBRWBreadA | D0readBRWBreadB);

    //checking if D0 uses any/how many registers
    wire D0noRead0 = D0read0Xwrite | D0read0Xread | D0read0WBwrite | D0read0WBread;
    wire D0noRead1 = D0read1Xwrite | D0read1Xread | D0read1WBwrite | D0read1WBread | (D0readA & (D0readA == D0readB));

    // D1 reads D0 writes
    wire D1readAEQD0writeA = D1readA == D0writeA;
    wire D1readAUD0writeA = D1readAEQD0writeA & D0write0 & D1read0;
    wire D1readAEQD0writeB = D1readA == D0writeB;
    wire D1readAUD0writeB = D1readAEQD0writeB & D0write1 & D1read0;
    wire D1readBEQD0writeA = D1readB == D0writeA;
    wire D1readBUD0writeA = D1readBEQD0writeA & D0write0 & D1read1;
    wire D1readBEQD0writeB = D1readB == D0writeB;
    wire D1readBUD0writeB = D1readBEQD0writeB & D0write1 & D1read1;  

    wire D1read0D0write = (D1readAUD0writeA | D1readAUD0writeB);
    wire D1read1D0write = (D1readBUD0writeA | D1readBUD0writeB);

    // D1 reads D0 reads
    wire D1readAEQD0readA = D1readA == D0readA;
    wire D1readARD0readA = D1readAEQD0readA & D0read0;
    wire D1readAEQD0readB = D1readA == D0readB;
    wire D1readARD0readB = D1readAEQD0readB & D0read1;
    wire D1readBEQD0readA = D1readB == D0readA;
    wire D1readBRD0readA = D1readBEQD0readA & D0read0;
    wire D1readBEQD0readB = D1readB == D0readB;
    wire D1readBRD0readB = D1readBEQD0readB & D0read1;

    wire D1read0D0read = (D1readARD0readA | D1readARD0readB);
    wire D1read1D0read = (D1readBRD0readA | D1readBRD0readB);

    // D1 reads X writes
    wire D1readAEQXwriteA = D1readA == XwriteA;
    wire D1readAUXwriteA = D1readAEQXwriteA & Xwrite0;
    wire D1readAEQXwriteB = D1readA == XwriteB;
    wire D1readAUXwriteB = D1readAEQXwriteB & Xwrite1;
    wire D1readBEQXwriteA = D1readB == XwriteA;
    wire D1readBUXwriteA = D1readBEQXwriteA & Xwrite0;
    wire D1readBEQXwriteB = D1readB == XwriteB;
    wire D1readBUXwriteB = D1readBEQXwriteB & Xwrite1;

    wire D1read0Xwrite = (D1readAUXwriteA | D1readAUXwriteB);
    wire D1read1Xwrite = (D1readBUXwriteA | D1readBUXwriteB);

    // D1 reads X reads
    wire D1readAEQXreadA = D1readA == XreadA;
    wire D1readARXreadA = D1readAEQXreadA & Xread0;
    wire D1readAEQXreadB = D1readA == XreadB;
    wire D1readARXreadB = D1readAEQXreadB & Xread1;
    wire D1readBEQXreadA = D1readB == XreadA;
    wire D1readBRXreadA = D1readBEQXreadA & Xread0;
    wire D1readBEQXreadB = D1readB == XreadB;
    wire D1readBRXreadB = D1readBEQXreadB & Xread1;

    wire D1read0Xread = (D1readARXreadA | D1readARXreadB);
    wire D1read1Xread = (D1readBRXreadA | D1readBRXreadB);

    // D1 reads WB writes
    wire D1readAEQWBwriteA = D1readA == WBwriteA;
    wire D1readAUWBwriteA = D1readAEQWBwriteA & WBwrite0;
    wire D1readAEQWBwriteB = D1readA == WBwriteB;
    wire D1readAUWBwriteB = D1readAEQWBwriteB & WBwrite1;
    wire D1readBEQWBwriteA = D1readB == WBwriteA;
    wire D1readBUWBwriteA = D1readBEQWBwriteA & WBwrite0;
    wire D1readBEQWBwriteB = D1readB == WBwriteB;
    wire D1readBUWBwriteB = D1readBEQWBwriteB & WBwrite1;

    wire D1read0WBwrite = (D1readAUWBwriteA | D1readAUWBwriteB);
    wire D1read1WBwrite = (D1readBUWBwriteA | D1readBUWBwriteB);

    // D1 reads WB reads
    wire D1readAEQWBreadA = D1readA == WBreadA;
    wire D1readARWBreadA = D1readAEQWBreadA & WBread0;
    wire D1readAEQWBreadB = D1readA == WBreadB;
    wire D1readARWBreadB = D1readAEQWBreadB & WBread1;
    wire D1readBEQWBreadA = D1readB == WBreadA;
    wire D1readBRWBreadA = D1readBEQWBreadA & WBread0;
    wire D1readBEQWBreadB = D1readB == WBreadB;
    wire D1readBRWBreadB = D1readBEQWBreadB & WBread1;

    wire D1read0WBread = (D1readARWBreadA | D1readARWBreadB);
    wire D1read1WBread = (D1readBRWBreadA | D1readBRWBreadB);

    wire D1noRead0 = D1read0D0write | D1read0D0read | D1read0Xwrite | D1read0Xread | D1read0WBwrite | D1read0WBread;
    wire D1noRead1 = D1read1D0write | D1read1D0read | D1read1Xwrite | D1read1Xread | D1read1WBwrite | D1read1WBread | (D1read1 & (D1readA == D1readB));

    wire[0:3] readNum = (D0read0 & ~D0noRead0) + (D0read1 & ~D0noRead1) + (D1read0 & ~D1noRead0) + (D1read1 & ~D1noRead1);

    wire canParallelReadRegs = readNum < 3;

    wire[0:3] readNumParallel = (D0read0 & ~D0noRead0) + (D0read1 & ~D0noRead1) + (D1read0 & ~D1noRead0 & canParallel) + (D1read1 & ~D1noRead1 & canParallel);

    wire Dread0 = readNumParallel > 0;
    wire[0:4] DreadA = D0read0 & ~D0noRead0 ? D0readA : D0read1 & ~D0noRead1 ? D0readB : (D1read0 & ~D1noRead0 & canParallel) ? D1readA : (D1read1 & ~D1noRead1 & canParallel) ? D1readB : 0;

    wire Dread1 = readNumParallel > 1;
    wire[0:4] DreadB = (D0read0 & ~D0noRead0 & D0read1 & ~D0noRead1) ? D0readB : (D0read0 & ~D0noRead0 & D1read0 & ~D1noRead0 & canParallel) ? D1readA : (D0read0 & ~D0noRead0 & D1read1 & ~D1noRead1 & canParallel) ? D1readB : (D0read1 & ~D0noRead1 & D1read0 & ~D1noRead0 & canParallel) ? D1readA : (D0read1 & ~D0noRead1 & D1read1 & ~D1noRead1 & canParallel) ? D1readB : (D1read0 & ~D1noRead0 & D1read1& ~D1noRead1 & canParallel) ? D1readB : 0; 

    // D0 writes D1 writes
    //checks that both are writing now
    wire D0writeAEQD1writeA = D0writeA == D1writeA;
    wire D0writeAUD1writeA = D0writeAEQD1writeA & D1write0;
    wire D0writeAEQD1writeB = D0writeA == D1writeB;
    wire D0writeAUD1writeB = D0writeAEQD1writeB & D1write1;
    wire D0writeBEQD1writeA = D0writeB == D1writeA;
    wire D0writeBUD1writeA = D0writeBEQD1writeA & D1write0;
    wire D0writeBEQD1writeB = D0writeB == D1writeB;
    wire D0writeBUD1writeB = D0writeBEQD1writeB & D1write1;

    wire D0write0D1write = (D0writeAUD1writeA | D0writeAUD1writeB);
    wire D0write1D1write = (D0writeBUD1writeA | D0writeBUD1writeB);

//got was double negative, made it D0write0D1write instead of ~D0write0D1write
    wire D0noWrite0 = D0write0D1write & canParallel;
    wire D0noWrite1 = D0write1D1write & canParallel;

//changed these wire sizes to 4 bits instead of 1/2
    wire[0:3] writeNum = (D0write0 & ~D0noWrite0) + (D0write1 & ~D0noWrite1) + D1write0 + D1write1;

    wire canParallelWriteRegs = writeNum < 3;

    wire[0:3] writeNumParallel = (D0write0 & ~D0noWrite0) + (D0write1 & ~D0noWrite1) + (D1write0 & canParallel) + (D1write1 & canParallel);

    wire Dwrite0 = writeNumParallel > 0;
    wire[0:4] DwriteA = (canParallel & D1write1) ? D1writeB : (canParallel & D1write0) ? D1writeA : D0write1 ? D0writeB : D0write0 ? D0writeA : 0;

//changed to ==2 instead of >1
    wire Dwrite1 = writeNumParallel == 2;
    wire[0:4] DwriteB = (canParallel & D1write1 & D1write0) ? D1writeA : (canParallel & D1write1 & D0write1) ? D0writeB : (canParallel & D1write1 & D0write0) ? D0writeA : (canParallel & D1write0 & D0write1) ? D0writeB : (canParallel & D1write0 & D0write0) ? D0writeA : D0isLdu?D0writeA: D1write1 & D1write0 ? DwriteA : 0;

    // State logic

    // wire D0readAUXwriteA = D0readAEQXwriteA & Xwrite0;
    // wire D0vaState <= DtargetAU0 ? 4 : DtargetAU1 ? 3 : DtargetAUWB0 ? 2 : DtargetAUWB1 ? 1 : 0;
    wire[0:3] D0vaState = D0readAUXwriteA ? 8 : D0readAUXwriteB ? 7 : D0readARXreadA ? 6 : D0readARXreadB ? 5 : D0readAUWBwriteA ? 4 : D0readAUWBwriteB ? 3 : D0readARWBreadA ? 2 : D0readARWBreadB ? 1 : 0;
    wire[0:3] D0vbState = D0readBUXwriteA ? 8 : D0readBUXwriteB ? 7 : D0readBRXreadA ? 6 : D0readBRXreadB ? 5 : D0readBUWBwriteA ? 4 : D0readBUWBwriteB ? 3 : D0readBRWBreadA ? 2 : D0readBRWBreadB ? 1 : 0;

    wire[0:3] D1vaState = D1readAUD0writeA ? 10 : D1readAUD0writeB ? 9 : D1readAUXwriteA ? 8 : D1readAUXwriteB ? 7 : D1readARXreadA ? 6 : D1readARXreadB ? 5 : D1readAUWBwriteA ? 4 : D1readAUWBwriteB ? 3 : D1readARWBreadA ? 2 : D1readARWBreadB ? 1 : 0;
    wire[0:3] D1vbState = D1readBUD0writeA ? 10 : D1readBUD0writeB ? 9 : D1readBUXwriteA ? 8 : D1readBUXwriteB ? 7 : D1readBRXreadA ? 6 : D1readBRXreadB ? 5 : D1readBUWBwriteA ? 4 : D1readBUWBwriteB ? 3 : D1readBRWBreadA ? 2 : D1readBRWBreadB ? 1 : 0;

    wire canParallel = canParallelReadRegs & canParallelWriteRegs & ~specHazard & ~D0isBranching;
    wire specHazard = ((D1isAdd | D1isOr) & D1inst[31] & ((D1vaState == 10) | (D1vaState == 9) | (D1vbState == 10) | (D1vbState == 9))) | ((D0isAdd|D0isOr)&D0inst[31]&(D1isBc|D1isBclr))|((D0isLd|D0isLdu)&(D1isLd|D1isLdu)) | ((D1isLd|D1isLdu) & ((D1vaState == 10) | (D1vaState == 9) | (D1vbState == 10) | (D1vbState == 9)));

    /************/
    /* Execute */
    /************/

    reg Xwrite0 = 0;
    reg Xwrite1 = 0;

    reg[0:4] XwriteA = 0;
    reg[0:4] XwriteB = 0;

    reg Xread0 = 0;
    reg Xread1 = 0;

    reg[0:4] XreadA = 0;
    reg[0:4] XreadB = 0;

    // X0

    reg[0:31] X0inst = 0;

    reg[0:3] X0vaState = 0;
    reg[0:3] X0vbState = 0;

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

//change to X0readA etc
    wire[0:4] X0regA = X0isOr?X0rs:
                        X0isSc?0:
                        X0ra;

    wire[0:4] X0regB = X0isSc ? 3 : X0rb;

    wire X0regAEQXA = X0regA == XreadA;
    wire X0regARXA = X0regAEQXA & Xread0;
    wire X0regAEQXB = X0regA == XreadB;
    wire X0regARXB = X0regAEQXB & Xread1;

    wire[0:63] X0readva = X0regARXA ? regReadData0 : X0regARXB ? regReadData1 : 0;

    wire[0:63] X0va = (X0vaState == 8) ? WBwriteDataA : (X0vaState == 7) ? WBwriteDataB : (X0vaState == 6) ? WBva : (X0vaState == 5) ? WBvb : (X0vaState == 4) ? oldWBwriteDataA : (X0vaState == 3) ? oldWBwriteDataB : (X0vaState == 2) ? oldWBva : (X0vaState == 1) ? oldWBvb : X0readva;

    wire X0regBEQXA = X0regB == XreadA;
    wire X0regBRXA = X0regBEQXA & Xread0;
    wire X0regBEQXB = X0regB == XreadB;
    wire X0regBRXB = X0regBEQXB & Xread1;

    wire[0:63] X0readvb = X0regBRXA ? regReadData0 : X0regBRXB ? regReadData1 : 0;

    wire[0:63] X0vb = (X0vbState == 8) ? WBwriteDataA : (X0vbState == 7) ? WBwriteDataB : (X0vbState == 6) ? WBva : (X0vbState == 5) ? WBvb :
                (X0vbState == 4) ? oldWBwriteDataA : (X0vbState == 3) ? oldWBwriteDataB : (X0vbState == 2) ? oldWBva : (X0vbState == 1) ? oldWBvb : X0readvb;

    wire[0:63] X0result = X0isAdd?X0va+X0vb: X0isOr?X0va|X0vb: 0; // X0isAddi?X0va+{{48{X0si[0]}},X0si}: 0;
    
//changed to take ld, ra ==0 into account
    wire[0:63] X0ea = X0isLd&(X0ra==0)?X0ds:X0va+X0ds;
    // X1

    reg[0:31] X1inst = 0;

    reg[0:3] X1vaState = 0;
    reg[0:3] X1vbState = 0;

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

//needs to be X1readA?? 
    wire[0:4] X1regA = X1isOr?X1rs:
                        X1isSc?0:
                        X1ra;

    wire[0:4] X1regB = X1isSc ? 3 : X1rb;

    wire X1regAEQXA = X1regA == XreadA;
    wire X1regARXA = X1regAEQXA & Xread0;
    wire X1regAEQXB = X1regA == XreadB;
    wire X1regARXB = X1regAEQXB & Xread1;

    wire[0:63] X1readva = X1regARXA ? regReadData0 : X1regARXB ? regReadData1 : 0;

    wire[0:63] X1va = (X1vaState == 8) ? WBwriteDataA : (X1vaState == 7) ? WBwriteDataB : (X1vaState == 6) ? WBva : (X1vaState == 5) ? WBvb :
                (X1vaState == 4) ? oldWBwriteDataA : (X1vaState == 3) ? oldWBwriteDataB : (X1vaState == 2) ? oldWBva : (X1vaState == 1) ? oldWBvb : X1readva;

    wire X1regBEQXA = X1regB == XreadA;
    wire X1regBRXA = X1regBEQXA & Xread0;
    wire X1regBEQXB = X1regB == XreadB;
    wire X1regBRXB = X1regBEQXB & Xread1;

    wire[0:63] X1readvb = X1regBRXA ? regReadData0 : X1regBRXB ? regReadData1 : 0;

    wire[0:63] X1vb = (X1vbState == 8) ? WBwriteDataA : (X1vbState == 7) ? WBwriteDataB : (X1vbState == 6) ? WBva : (X1vbState == 5) ? WBvb :
                (X1vbState == 4) ? oldWBwriteDataA : (X1vbState == 3) ? oldWBwriteDataB : (X1vbState == 2) ? oldWBva : (X1vbState == 1) ? oldWBva : X1readvb;

    wire[0:63] X1result = X1isAdd?X1va+X1vb: X1isOr?X1va|X1vb: 0; // X1isAddi?X1va+{{48{X1si[0]}},X1si}: 0;
    wire[0:63] X1ea = X1isLd&(X1ra==0)?X1ds:X1va+X1ds;
 

    //CR logic

    wire X0lt = X0result[0];
    wire X0eq = X0result == 0;
    wire X0gt = ~X0lt & ~X0eq;

    wire X0ov = X0va[0] ^ X0vb[0] ? 0 : X0va[0] ^ X0result[0];

    wire X0so = xer[0];
    wire X0nextso = X0so | X0ov;
    wire[0:31] X0nextxer = (X0isAdd & X0oe)?{X0nextso,X0ov,xer[2:31]}:xer;

    wire [0:31] X0newCr = ((X0isAdd | X0isOr) & X0rc) ? {X0lt,X0gt,X0eq,X0nextxer[0],cr[4:31]} : cr; 

    wire X1ov = X1va[0] ^ X1vb[0] ? 0 : X1va[0] ^ X1result[0];
    wire X1lt = X1result[0];
    wire X1eq = X1result == 0;
    wire X1gt = ~X1lt & ~X1eq;

    wire X1so = xer[0];
    wire X1nextso = X1so | X1ov;

    wire[0:31] X1nextxer = (X1isAdd & X1oe)?{X1nextso,X1ov,X0nextxer[2:31]}:X0nextxer;

 

    wire [0:31] X1newCr = ((X1isAdd | X1isOr) & X1rc) ? {X1lt,X1gt,X1eq,X1nextxer[0],cr[4:31]} : cr; 

    /**************/
    /* Write Back */
    /**************/

    reg WBwrite0 = 0;
    reg WBwrite1 = 0;

    reg[0:4] WBwriteA = 0;
    reg[0:4] WBwriteB = 0;

    reg WBread0 = 0;
    reg WBread1 = 0;

    reg[0:4] WBreadA = 0;
    reg[0:4] WBreadB = 0;

    reg[0:63] WBva = 0;
    reg[0:63] WBvb = 0;

    // WB0

    reg[0:31] WB0inst = 0;

    reg[0:3] WB0vaState = 0;
    reg[0:3] WB0vbState = 0;

    reg[0:63] WB0va = 0;
    reg[0:63] WB0vb = 0;

    wire[0:5] WB0opcode = WB0inst[0:5];
    wire[0:4] WB0rt = WB0inst[6:10];
    wire[0:4] WB0ra = WB0inst[11:15];
    wire[0:7] WB0lev = WB0inst[20:26];
    wire[0:8] WB0xop9 = WB0inst[22:30];
    wire[0:9] WB0xop10 = WB0inst[21:30];
    wire[0:9] WB0spr = {WB0inst[16:20],WB0inst[11:15]};
    wire[0:63] WB0si = {{48{WB0inst[16]}},WB0inst[16:31]};
    wire[0:63] WB0ds = {{48{WB0inst[16]}},{WB0inst[16:29] << 2}};

    wire WB0isOr = (WB0opcode == 31) & (WB0xop10 == 444);
    wire WB0isAdd = (WB0opcode == 31) & (WB0xop9 == 266);
    wire WB0isMFSpr = (WB0opcode == 31) & (WB0xop10 == 339) & ((WB0spr == 1) || (WB0spr == 8) || (WB0spr == 9));
    wire WB0isLd = (WB0opcode == 58) & (WB0inst[30:31] == 0);
    wire WB0isLdu = (WB0opcode == 58) & (WB0inst[30:31] == 1) & (WB0ra != 0) & (WB0ra != WB0rt);
    wire WB0isStd = WB0opcode == 62;
    wire WB0isAddi = WB0opcode == 14;
    wire WB0isSc = (WB0opcode == 17) & ((WB0lev == 0) | (WB0lev == 1)) & WB0inst[30];
    wire[0:4] WB0writeA = WB0isOr?WB0ra:WB0rt;
    wire[0:4] WB0writeB = WB0ra;
    wire WB0write0 = WB0isAdd|WB0isAddi|WB0isOr|WB0isLd|WB0isLdu;
    wire WB0write1 = WB0isLdu;

//changed addi to check if ra is 0, did same for WB1isAddi
    wire[0:63] WB0writeDataA = WB0isAdd ? WB0va + WB0vb : WB0isOr ? WB0va | WB0vb : (WB0isAddi & WB0ra==0) ? WB0si : (WB0isAddi & WB0ra!=0) ? WB0va + WB0si : (WB0isLd | WB0isLdu) ? memReadData1 :  0;
    wire[0:63] WB0writeDataB = WB0va + WB0ds;

    // WB1

    reg[0:31] WB1inst = 0;

    reg[0:3] WB1vaState = 0;
    reg[0:3] WB1vbState = 0;

    reg[0:63] WB1vaUnchecked = 0;
    reg[0:63] WB1vbUnchecked = 0;

    wire[0:5] WB1opcode = WB1inst[0:5];
    wire[0:4] WB1rt = WB1inst[6:10];
    wire[0:4] WB1ra = WB1inst[11:15];
    wire[0:7] WB1lev = WB1inst[20:26];
    wire[0:8] WB1xop9 = WB1inst[22:30];
    wire[0:9] WB1xop10 = WB1inst[21:30];
    wire[0:9] WB1spr = {WB1inst[16:20],WB1inst[11:15]};
    wire[0:63] WB1si = {{48{WB1inst[16]}},WB1inst[16:31]};
    wire[0:63] WB1ds = {{48{WB1inst[16]}},{WB1inst[16:29] << 2}};


    wire WB1isOr = (WB1opcode == 31) & (WB1xop10 == 444);
    wire WB1isAdd = (WB1opcode == 31) & (WB1xop9 == 266);
    wire WB1isMFSpr = (WB1opcode == 31) & (WB1xop10 == 339) & ((WB1spr == 1) || (WB1spr == 8) || (WB1spr == 9));
    wire WB1isLd = (WB1opcode == 58) & (WB1inst[30:31] == 0);
    wire WB1isLdu = (WB1opcode == 58) & (WB1inst[30:31] == 1) & (WB1ra != 0) & (WB1ra != WB1rt);
    wire WB1isStd = WB1opcode == 62;
    wire WB1isAddi = WB1opcode == 14;
    wire WB1isSc = (WB1opcode == 17) & ((WB1lev == 0) | (WB1lev == 1)) & WB1inst[30];

    wire WB1write0 = WB1isAdd|WB1isAddi|WB1isOr|WB1isLd|WB1isLdu;
    wire WB1write1 = WB1isLdu;
    wire[0:4] WB1writeA = WB1isOr?WB1ra:WB1rt;
    wire[0:4] WB1writeB = WB1ra;


    wire[0:63] WB1va = (WB1vaState == 10) ? WB0writeDataA : (WB1vaState == 9) ? WB0writeDataB : WB1vaUnchecked;
    wire[0:63] WB1vb = (WB1vbState == 10) ? WB0writeDataA : (WB1vbState == 9) ? WB0writeDataB : WB1vbUnchecked;

    wire[0:63] WB1writeDataA = WB1isAdd ? WB1va + WB1vb : WB1isOr ? WB1va | WB1vb : (WB1isAddi & WB1ra==0) ? WB1si : (WB1isAddi & WB1ra!=0) ? WB1va + WB1si : (WB1isLd | WB1isLdu) ? memReadData1 :  0;
    wire[0:63] WB1writeDataB = WB1va + WB1ds;

    wire[0:63] WBwriteDataA = (WB1writeA == WBwriteA) & WB1write0 ? WB1writeDataA : (WB1writeB == WBwriteA) & WB1write1 ? WB1writeDataB : (WB0writeA == WBwriteA) & WB0write0 ? WB0writeDataA : (WB0writeB == WBwriteA) & WB0write1 ? WB0writeDataB : 0;
    wire[0:63] WBwriteDataB = (WB1writeA == WBwriteB) & WB1write0 ? WB1writeDataA : (WB1writeB == WBwriteB) & WB1write1 ? WB1writeDataB : (WB0writeA == WBwriteB) & WB0write0 ? WB0writeDataA : (WB0writeB == WBwriteB) & WB0write1 ? WB0writeDataB : 0;

    reg[0:63] oldWBva = 0;
    reg[0:63] oldWBvb = 0;

    reg[0:63] oldWBwriteDataA = 0;
    reg[0:63] oldWBwriteDataB = 0;

    /**********/
    /* Update */
    /**********/

    wire stopFetch = !(tail==head) & (head-tail)<=3 & (head-tail)>1;
    wire[0:5] nextHead = (~state|head==tail) ? head : canParallel ? head + 2 : head + 1;
    wire[0:5] nextTail = stopFetch ? tail : state ? tail + 2 : tail;
    wire[0:63] pcPlus8 = pc + 8;
    wire[0:63] nextpc = stopFetch ? pc : pcPlus8; //need to advance pc by 8 instead
    wire[0:63] nextTruePc = ~state1?TruePc:(canParallel & ~ignore1)?TruePc+8:TruePc+4;//when do we check state?

    always @(posedge clk) begin
        if(D0isBranching) begin
            state<=0;
            state1<=0;
            pc<=D0branchTarget;
            TruePc<=D0branchTarget;
        end else if (canParallel & D1isBranching) begin
            state<=0;
            state1<=0;
            pc<=D1branchTarget;
            TruePc<=D1branchTarget;
        end else begin 
            head <= nextHead;
            tail <= nextTail;
            pc <= nextpc;
            weight<=0;
            ignore1<=ignore;
            ignore <= weight;
            state<=1;
            state1<=state;
            TruePc<=nextTruePc;
        end

        //can we run two branches at same time?
        if((D1isB|D1isBc|D1isBclr) & D1inst[31] & canParallel) begin
            lr<=TruePc+8;
        end else if((D0isB|D0isBc|D0isBclr) & D0inst[31]) begin
            lr<=TruePc+4;
        end
       if(D0isBranching|(D1isBranching&canParallel)) begin
            for(i=0;i<32;i=i+1) begin
                queue[i]<=0;
            end
            if(D0isBranching & D0branchTarget[61]) begin
                weight<=1;
                ignore<=1;
                ignore1<=1;
            end
            else 
            if(D1isBranching & D1branchTarget[61]) begin
                weight<=1;
                ignore<=1;
                ignore1<=1;
            end else begin
                weight<=0;
                ignore<=0;
                ignore1<=0;
            end
            head<=0;
            tail<=0;
        end
        if (WB0isSc) begin
            if (WB0va == 0) begin
                $display("%c",WB0vb[56:63]);
            end else if (WB0va == 1) begin
                $finish;
            end else if (WB0va == 2) begin
                $display("%x",WB0vb);
            end
        end
        if (WB1isSc) begin
            if (WB1va == 0) begin
                $display("%c",WB1vb[56:63]);
            end else if (WB1va == 1) begin
                $finish;
            end else if (WB1va == 2) begin
                $display("%x",WB1vb);
            end
        end
	if(!stopFetch) begin
            queue[tail + 1] <= fetch[32:63];
            if (~ignore) begin
                queue[tail] <= fetch[0:31];
            end
	end
        oldWBwriteDataB <= WBwriteDataB;
        oldWBwriteDataA <= WBwriteDataA;
        oldWBvb <= WBvb;
        oldWBva <= WBva;
        WB1inst <= X1inst;
        WB1vbUnchecked <= X1vb;
        WB1vaUnchecked <= X1va;
        WB1vbState <= X1vbState;
        WB1vaState <= X1vaState;
        WB0inst <= X0inst;
        WB0vb <= X0vb;
        WB0va <= X0va;
        WB0vbState <= X0vbState;
        WB0vaState <= X0vaState;
        WBvb <= regReadData1;
        WBva <= regReadData0;
        WBreadB <= XreadB;
        WBwriteB <= XwriteB;
        WBreadA <= XreadA;
        WBwriteA <= XwriteA;
        WBread1 <= Xread1;
        WBwrite1 <= Xwrite1;
        WBread0 <= Xread0;
        WBwrite0 <= Xwrite0;
        xer<=X1nextxer;
        cr<=TrueCr;
        if (canParallel) begin
            X1inst <= D1inst;
        end else begin
            X1inst <= 0;
        end
        // Might want to look into how the state is handled when you don't run in parallel.
        X1vbState <= D1vbState;
        X1vaState <= D1vaState;
        X0inst <= D0inst;
        X0vbState <= D0vbState;
        X0vaState <= D0vaState;
        XreadB <= DreadB;
        XwriteB <= DwriteB;
        XreadA <= DreadA;
        XwriteA <= DwriteA;
        Xread1 <= Dread1;
        Xwrite1 <= Dwrite1;
        Xread0 <= Dread0;
        Xwrite0 <= Dwrite0;
        // Dinst1 <= queue[head + 1];
        // Dinst0 <= queue[head];
    end

wire [0:63] queue0 = queue[0];
wire [0:63] queue1 = queue[1];
wire [0:63] queue2 = queue[2];

endmodule
