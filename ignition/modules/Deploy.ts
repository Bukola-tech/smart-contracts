import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const BankModule = buildModule("BankModule", (m) => {

    const Bank = m.contract("Bank" );

    return { Bank };
});

export default BankModule;


