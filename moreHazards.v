/* 
   // D0 reads X writes
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

    wire D1read0Xwrite = (D1readAUD0writeA | D1readAUD0writeB);
    wire D1read1Xwrite = (D1readBUD0writeA | D1readBUD0writeB);

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

    wire[2:0] readNum = (D0read0 & ~D0noRead0) + (D0read1 & ~D0noRead1) + (D1read0 & ~D1noRead0) + (D1read1 & ~D1noRead1);

    wire canParallelRegs = readNum < 3;

    wire[1:0] readNumParallel = (D0read0 & ~D0noRead0) + (D0read1 & ~D0noRead1) + (D1read0 & ~D1noRead0 & canParallel) + (D1read1 & ~D1noRead1 & canParallel);

    wire Dread0 = readNumParallel > 0;
    wire[4:0] DreadA = ~D0noRead0 ? D0readA : ~D0noRead1 ? D0readB : (~D1noRead0 & canParallel) ? D1readA : (~D1noRead1 & canParallel) ? D1readB : 0;

    wire Dread1 = readNumParallel > 1;
    wire[4:0] DreadB = (~D0noRead0 & ~D0noRead1) ? D0readB : (~D0noRead0 & ~D1noRead0 & canParallel) ? D1readA : (~D0noRead0 & ~D1noRead1 & canParallel) ? D1readB : (~D0noRead1 & ~D1noRead0 & canParallel) ? D1readA : (~D0noRead1 & ~D1noRead1 & canParallelw) ? D1readB : (~D1noRead0 & ~D1noRead1 & canParallel) ? D1readB : 0;

*/ 
