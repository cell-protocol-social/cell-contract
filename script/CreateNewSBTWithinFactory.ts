import { ethers, deployments } from "hardhat"

async function main() {
    const [signer] = await ethers.getSigners()
    console.log("-> signer address", signer.address)

    const sbtsFactory = (await ethers.getContractAt(
        "SBTsFactory", 
        (await deployments.get("SBTsFactory")).address
    ))
    console.log("-> SBTsFactory address", sbtsFactory.address)

    // ** Notice ** change these values to the needed
    const name = "SBT-Type-1"
    const symbol = "ST1"
    const baseURI = ""

    const trustSigner = signer.address
    await sbtsFactory.createNewSBT(name, symbol, baseURI, trustSigner)
    
    const lastOne = await sbtsFactory.lengthOfSBTs() - 1
    console.log(`new ${name} SBT contract deployed: `, await sbtsFactory.sbtContracts(lastOne));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});