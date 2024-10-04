import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const SupplyChainModule = buildModule("SupplyChainModule", (m) => {

    // const DEFAULT_ADMIN_ROLE = 3600

    const SupplyChainManager = m.contract("SupplyChainManager");

    return { SupplyChainManager };
});

export default SupplyChainModule;


