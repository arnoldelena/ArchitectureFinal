/*

//valid bits, to know how many registers the instructions takes
wire D0reg0valid = (D0isAdd|D0isOr|(D0isAddi|D0isLd)&(D0ra!=0)|D0isSc|D0isLdu);
wire D0reg1valid = (D0isAdd|D0isOr|D0isSc);

wire D1reg0valid = (D1isAdd|D1isOr|(D1isAddi|D1isLd)&(D1ra!=0)|D1isSc|D1isLdu);
wire D1reg1valid = (D1isAdd|D1isOr|D0isSc);

//do not take into acount if the two instructions are reading/writing to same register
wire underRegReadLimit = (D0reg0valid+D0reg1valid+D1reg0valid+D1reg1valid)<=2;

wire underRegWriteLimit = ~((D0isLdu|D1isLdu)&(D0isAdd|D0isAddi|D0isOr|D0isLd|D1isAdd|D1isAddi|D1isOr|D1isLd)); 


wire [0:6] Dinst0reg0 = D0isOr?D0rs:
                        D0isSc?0:
                        D0ra;

wire [0:6] Dinst0reg1 = D0isSc?3:D0rb;

*/
