/*wire isHazard = ((D0isAdd&D1isAdd)&(ra1==rt0|rb1==rt0|ra0==rt1|rb0==rt1))?1:
				((D0isAdd&D1isOr)&(rs1==rt0|rb1==rt0|ra1==ra0|ra1==rb0))?1:
				((D0isAdd&D1isAddi)&(ra1==rt0))?1:
				((D0isAdd&D1isSc)&(rt0==0|rt0==3))?1:
				((D0isOr&D1isAdd)&(rs0==rt1|rb0==rt1|ra0==ra1|ra0==rb1)?1:
				((D0isOr&D1isOr)&())*/

wire isHazard = (D0ReadArg1==D1WriteArg1|D0ReadArg2==D1WriteArg1|
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

