import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const FreelanceModule = buildModule("FreelanceModule", (m) => {

    const _freelancerAddress = "0x32F1E0E19AD13Fe3Ff1799012A88bc33b765Ef5C"

    const _contractDeadline = 3600

    const FreelancePayment = m.contract("FreelancePayment" , [_freelancerAddress, _contractDeadline] );

    return { FreelancePayment };
});

export default FreelanceModule;


