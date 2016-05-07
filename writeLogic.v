/*
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

    wire[1:0] writeNumParallel = 

    wire Dwrite0 = writeNumParallel > 0;
    wire[4:0] DwriteA = (canParallel & D1write1) ? D1writeB : (canParallel & D1write0) ? D1writeA : D0write1 ? D0writeB : D0write0 ? D0writeA : 0;

    wire Dwrite1 = writeNumParallel > 1;
    wire[4:0] DwriteB = (canParallel & D1write1 & D1write0) ? D1writeA : (canParallel & D1write1 & D0write1) ? D0writeB : (canParallel & D1write1 & D0write0) ? D0writeA : (canParallel & D1write0 & D0write1) : D0writeB : (canParallel & D1write0 & D0write0) ? D0writeA : D1write1 & D1write0 ? DwriteA : 0;
*/
