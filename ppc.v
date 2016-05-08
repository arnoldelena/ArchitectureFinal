
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
    reg[0:63] TruePc = 0;

    /********************/
    /* Memory interface */
    /********************/

    wire memReadEn0 = 1;
    wire [0:60]memReadAddr0 = pc[0:60];
    wire [0:63]memReadData0;
    wire memReadEn1 = X0isLd|X0isLdu|X1isLd|X1isLdu;
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

    wire regReadEn0 = Dread0;
    wire [0:4]regReadAddr0 = DreadA;
    wire [0:63]regReadData0;

    wire regReadEn1 = Dread1;
    wire [0:4]regReadAddr1 = DreadB;
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

    reg[0:63] queue [0:31];
    reg[0:5] tail = 0;
    reg[0:5] head = 0;

    integer i;
    initial begin 
        for(i=0;i<32;i=i+1) begin
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

    wire[0:4] D0readA = D0isOr?D0rs:
                        D0isSc?0:
                        D0ra;
    wire[0:4] D0readB = D0isSc?3:D0rb;

    // D1

    reg[0:31] D1inst = queue[head+1];

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
    wire D1isB = D1opcode == 18;
    wire D1isBc = D1opcode == 16;
    wire D1isBclr = (D1opcode==19) & (D1xop10==16);


    wire[0:4] D1readA = D1isOr?D1rs:
                        D1isSc?0:
                        D1ra;
    wire[0:4] D1readB = D1isSc?3:D1rb;

    wire D0isBranching = D0isB|((D0isBc|D0isBclr) & D0ctrOk & D0condOk); 
    wire D1isBranching = D1isB|((D1isBc|D1isBclr) & D1ctrOk & D1condOk);
    wire D0ctrOk = D0inst[8]|((ctr-1 != 0)^D0inst[9]);
    wire D1ctrOk = D1inst[8]|((ctr-1 != 0)^D1inst[9]);
    wire D0condOk = D0inst[6]|(newCr[D0ra]==D0inst[7]);
    wire D1condOk = D1inst[6]|(newCr[D1ra]==D1inst[7]);  
    wire [0:63] D0branchTarget = D0isBc?D0bcTarget:
                        D0isB?D0bTarget:
                        D0isBclr?D0bclrTarget:
                        0;
    wire [0:63] D1branchTarget = D1isBc?D1bcTarget:
                        D1isB?D1bTarget:
                        D1isBclr?D1bclrTarget:
                        0;

    //need to do if the parallel instruction sets the cr, then branch in execute stage
    wire [0:63] D0bTarget = D0inst[30]?{{38{D0inst[6]}},D0inst[6:29],2'b00}:{{33{D0inst[6]}},D0inst[6:29],2'b00}+TruePc;
    wire [0:63] D0bclrTarget = {lr[0:61],2'b00};
    wire [0:63] D0bcTarget = D0inst[30]?{{48{D0inst[16]}},D0inst[16:29],2'b00}:{{48{D0inst[16]}},D0inst[16:29],2'b00}+TruePc;

     wire [0:63] D1bTarget = D1inst[30]?{{38{D1inst[6]}},D1inst[6:29],2'b00}:{{33{D1inst[6]}},D1inst[6:29],2'b00}+TruePc;
    wire [0:63] D1bclrTarget = {lr[0:61],2'b00};
    wire [0:63] D1bcTarget = D1inst[30]?{{48{D1inst[16]}},D1inst[16:29],2'b00}:{{48{D1inst[16]}},D1inst[16:29],2'b00}+TruePc;
 
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
    wire D0readAEQWBwriteB = D0readB == WBwriteB;
    wire D0readAUWBwriteB = D0readAEQXWBriteB & WBwrite1;
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
    wire D1readAUD0writeA = D1readAEQXwriteA & D0write0;
    wire D1readAEQD0QXwriteB = D1readB == D0writeB;
    wire D1readAUD0writeB = D1readAEQXwriteB & D0write1;
    wire D1readBEQD0writeA = D1readB == D0writeA;
    wire D1readBUD0writeA = D1readBEQD0writeA & D0write0;
    wire D1readBEQD0writeB = D1readB == D0writeB;
    wire D1readBUD0writeB = D1readBEQD0writeB & D0write1;

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
    wire D1readAEQXwriteB = D1readB == XwriteB;
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
    wire D1readAEQWBwriteB = D1readB == WBwriteB;
    wire D1readAUWBwriteB = D1readAEQXWBriteB & WBwrite1;
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
    wire D1noRead1 = D1read1D0write | D1read1D0read | D1read1Xwrite | D1read1Xread | D1read1WBwrite | D1read1WBread | (D1read0 & (D1readA == D1readB));

    wire[0:2] readNum = (D0read0 & ~D0noRead0) + (D0read1 & ~D0noRead1) + (D1read0 & ~D1noRead0) + (D1read1 & ~D1noRead1);

    wire canParallelReadRegs = readNum < 3;

    wire[0:1] readNumParallel = (D0read0 & ~D0noRead0) + (D0read1 & ~D0noRead1) + (D1read0 & ~D1noRead0 & canParallel) + (D1read1 & ~D1noRead1 & canParallel);

    wire Dread0 = readNumParallel > 0;
    wire[0:4] DreadA = ~D0noRead0 ? D0readA : ~D0noRead1 ? D0readB : (~D1noRead0 & canParallel) ? D1readA : (~D1noRead1 & canParallel) ? D1readB : 0;

    wire Dread1 = readNumParallel > 1;
    wire[0:4] DreadB = (~D0noRead0 & ~D0noRead1) ? D0readB : (~D0noRead0 & ~D1noRead0 & canParallel) ? D1readA : (~D0noRead0 & ~D1noRead1 & canParallel) ? D1readB : (~D0noRead1 & ~D1noRead0 & canParallel) ? D1readA : (~D0noRead1 & ~D1noRead1 & canParallel) ? D1readB : (~D1noRead0 & ~D1noRead1 & canParallel) ? D1readB : 0; 

    // D0 writes D1 writes
    wire D0writeAEQD0writeA = D0writeA == D1writeA;
    wire D0writeAUD0writeA = D0writeAEQD0writeA & D1write0;
    wire D0writeAEQD0writeB = D0writeA == D1writeB;
    wire D0writeAUD0writeB = D0writeAEQD0writeB & D1write1;
    wire D0writeBEQD0writeA = D0writeB == D1writeA;
    wire D0writeBUD0writeA = D0writeBEQD0writeA & D1write0;
    wire D0writeBEQD0writeB = D0writeB == D1writeB;
    wire D0writeBUD0writeB = D0writeBEQD0writeB & D1write1;

    wire D0write0D1write = (D0writeAUD1writeA | D0writeAUD1writeB);
    wire D0write1D1write = (D0writeBUD1writeA | D0writeBUD1writeB);

    wire D0noWrite0 = ~D0write0D1write;
    wire D0noWrite1 = ~D0write1D1write;

    wire[2:0] writeNum = (D0write0 & ~D0noWrite0) + (D0write1 & ~D0noWrite1) + D1write0 + D1write1;

    wire canParallelWriteRegs = writeNum < 3;

    wire[1:0] writeNumParallel = (D0write0 & ~D0noWrite0) + (D0write1 & ~D0noWrite1) + (D1write0 & canParallel) + (D1write1 & canParallel);

    wire Dwrite0 = writeNumParallel > 0;
    wire[4:0] DwriteA = (canParallel & D1write1) ? D1writeB : (canParallel & D1write0) ? D1writeA : D0write1 ? D0writeB : D0write0 ? D0writeA : 0;

    wire Dwrite1 = writeNumParallel > 1;
    wire[4:0] DwriteB = (canParallel & D1write1 & D1write0) ? D1writeA : (canParallel & D1write1 & D0write1) ? D0writeB : (canParallel & D1write1 & D0write0) ? D0writeA : (canParallel & D1write0 & D0write1) ? D0writeB : (canParallel & D1write0 & D0write0) ? D0writeA : D1write1 & D1write0 ? DwriteA : 0;

    // ??????????????????????????????????

    wire isHazard = (D0readA==D1writeA|D0ReadArg2==D1WriteArg1|
					D1ReadArg1==D0WriteArg1|D1ReadArg2==D0WriteArg1|
					D0ReadArg1==D1WriteArg2|D0ReadArg2==D1WriteArg2|
					D1ReadArg1==D0WriteArg2|D1ReadArg2==D0WriteArg2)?1:0;

    wire [0:5]D0WriteArg1 = (D0isAdd | D0isAddi | D0isLd | D0isLdu) ? rt0:
						(D0isOr) ? ra0:
						63;

    wire [0:5]D1WriteArg1 = (D1isAdd | D1isAddi | D1isLd | D1isLdu) ? rt1:
						(D1isOr) ? ra1:
						63;

    wire [0:5]D0WriteArg2 = (D0isLd | D0isLdu) ? ra0:63;

    wire [0:5]D1WriteArg2 = (D1isLd | D1isLdu) ? ra1:63;


    wire isSpecHazard = (D0isAdd & D1isBc | D0isAdd & D1isBclr |
					D0isOr & D1isBc | D0isOr & D1isBclr |
					D1isAdd & D0isBc | D1isAdd & D0isBclr |
					D1isOr & D0isBc | D1isOr & D0isBclr |
					D0isBclr & D1isB | D0isBclr & D1isBc | D0isBclr & D1isBclr |
					D1isBclr & D0isB | D1isBclr & D0isBc | D1isBclr & D0isBclr) ? 1:0;

    //valid bits, to know how many registers the instructions takes
    wire D0reg0valid = (D0isAdd|D0isOr|(D0isAddi|D0isLd)&(D0ra!=0)|D0isSc|D0isLdu);
    wire D0reg1valid = (D0isAdd|D0isOr|D0isSc);

    wire D1reg0valid = (D1isAdd|D1isOr|(D1isAddi|D1isLd)&(D1ra!=0)|D1isSc|D1isLdu);
    wire D1reg1valid = (D1isAdd|D1isOr|D0isSc);

    //do not take into acount if the two instructions are reading/writing to same register
    wire underRegReadLimit = (D0reg0valid+D0reg1valid+D1reg0valid+D1reg1valid)<=2;

    wire underRegWriteLimit = ~((D0isLdu|D1isLdu)&(D0isAdd|D0isAddi|D0isOr|D0isLd|D1isAdd|D1isAddi|D1isOr|D1isLd)); 

    wire canParallel = underRegReadLimit & underRegWriteLimit;

    wire [0:6] Dinst0reg0 = D0isOr?D0rs:
                            D0isSc?0:
                            D0ra;

    wire [0:6] Dinst0reg1 = D0isSc?3:D0rb;

    /************/
    /* Exectute */
    /************/

    // X0

    reg Xwrite0 = 0;
    reg Xwrite1 = 0;

    reg[4:0] XwriteA = 0;
    reg[4:0] XwriteB = 0;

    reg Xread0 = 0;
    reg Xread1 = 0;

    reg[4:0] XreadA = 0;
    reg[4:0] XreadB = 0;

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
 
    //CR logic
    wire [0:3] newCr; 
    
    /**************/
    /* Write Back */
    /**************/

    reg WBwrite0 = 0;
    reg WBwrite1 = 0;

    reg[4:0] WBwriteA = 0;
    reg[4:0] WBwriteB = 0;

    reg WBread0 = 0;
    reg WBread1 = 0;

    reg[4:0] WBreadA = 0;
    reg[4:0] WBreadB = 0;

    // WB0

    reg[0:31] WB0inst = 0;

    wire[0:5] WB0opcode = WB0inst[0:5];
    wire[0:4] WB0rt = WB0inst[6:10];
    wire[0:4] WB0ra = WB0inst[11:15];
    wire[0:7] WB0lev = WB0inst[20:26];
    wire[0:8] WB0xop9 = WB0inst[22:30];
    wire[0:9] WB0xop10 = WB0inst[21:30];
    wire[0:9] WB0spr = {WB0inst[16:20],WB0inst[11:15]};
    wire[0:63] WB0si = {{48{WB0inst[16]}},WB0inst[16:31]};

    wire WB0isOr = (WB0opcode == 31) & (WB0xop10 == 444);
    wire WB0isAdd = (WB0opcode == 31) & (WB0xop9 == 266);
    wire WB0isMFSpr = (WB0opcode == 31) & (WB0xop10 == 339) & ((WB0spr == 1) || (WB0spr == 8) || (WB0spr == 9));
    wire WB0isLd = (WB0opcode == 58) & (WB0inst[30:31] == 0);
    wire WB0isLdu = (WB0opcode == 58) & (WB0inst[30:31] == 1) & (WB0ra != 0) & (WB0ra != WB0rt);
    wire WB0isStd = WB0opcode == 62;
    wire WB0isAddi = WB0opcode == 14;
    wire WB0isSc = (WB0opcode == 17) & ((WB0lev == 0) | (WB0lev == 1)) & WB0inst[30];

    // WB1

    reg[0:31] WB1inst = 0;

    wire[0:5] WB1opcode = WB1inst[0:5];
    wire[0:4] WB1rt = WB1inst[6:10];
    wire[0:4] WB1ra = WB1inst[11:15];
    wire[0:7] WB1lev = WB1inst[20:26];
    wire[0:8] WB1xop9 = WB1inst[22:30];
    wire[0:9] WB1xop10 = WB1inst[21:30];
    wire[0:9] WB1spr = {WB1inst[16:20],WB1inst[11:15]};
    wire[0:63] WB1si = {{48{WB1inst[16]}},WB1inst[16:31]};

    wire WB1isOr = (WB1opcode == 31) & (WB1xop10 == 444);
    wire WB1isAdd = (WB1opcode == 31) & (WB1xop9 == 266);
    wire WB1isMFSpr = (WB1opcode == 31) & (WB1xop10 == 339) & ((WB1spr == 1) || (WB1spr == 8) || (WB1spr == 9));
    wire WB1isLd = (WB1opcode == 58) & (WB1inst[30:31] == 0);
    wire WB1isLdu = (WB1opcode == 58) & (WB1inst[30:31] == 1) & (WB1ra != 0) & (WB1ra != WB1rt);
    wire WB1isStd = WB1opcode == 62;
    wire WB1isAddi = WB1opcode == 14;
    wire WB1isSc = (WB1opcode == 17) & ((WB1lev == 0) | (WB1lev == 1)) & WB1inst[30];

    /**********/
    /* Update */
    /**********/

    wire stopFetch = !(tail==head) & (head-tail)<=2 & (head-tail)>0;
    wire[0:5] nextHead = ~state ? head : canParallel ? head + 2 : head + 1;
    wire[0:5] nextTail = stopFetch ? tail : state ? tail + 2 : tail;
    wire[0:63] pcPlus8 = pc + 8;
    wire[0:63] nextpc = stopFetch ? pc : pcPlus8; //need to advance pc by 8 instead
    wire[0:63] nextTruePc = canParallel?TruePc+8:TruePc+4;//when do we check state?

    always @(posedge clk) begin
        if(D0isBranching) begin
            state<=0;
            pc<=D0branchTarget;
            TruePc<=D0branchTarget;
            if(D0inst[31]==1) begin
                lr<=TruePc+4;
            end
        end else if (D1isBranching) begin
            state<=0;
            pc<=D1branchTarget;
            TruePc<=D1branchTarget;
            if(D1inst[31]==1)begin
                lr<=TruePc+8;   //because TruePc holds pc of inst0
            end  
        end else begin
            head <= nextHead;
            tail <= nextTail;
            pc <= nextpc;
            state<=1;
            TruePc<=nextTruePc;
        end
        if(D0isBranching|D1isBranching) begin
            for(i=0;i<32;i=i+1) begin
                queue[i]<=0;
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
            queue[tail + 1] = fetch[32:63];
            queue[tail] = fetch[0:31];
	end
        WB1inst <= X1inst;
        WB0inst <= X0inst;
        WBread1 <= Xread1;
        WBwrite1 <= Xwrite1;
        WBread0 <= Xread0;
        WBwrite0 <= Xwrite0;
        if (canParallel) begin
            X1inst <= D1inst;
        end else begin
            X1inst <= 0;
        end
        X0inst <= D0inst;
        Xread1 <= Dread1;
        Xwrite1 <= Dwrite1;
        Xread0 <= Dread0;
        Xwrite0 <= Dwrite0;
        // Dinst1 <= queue[head + 1];
        // Dinst0 <= queue[head];
    end

endmodule
