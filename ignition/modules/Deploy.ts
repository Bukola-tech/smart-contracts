import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const LotteryModule = buildModule("LotteryModule", (m) => {

    const Lottery = m.contract("Lottery" );

    return { Lottery };
});

export default LotteryModule;


