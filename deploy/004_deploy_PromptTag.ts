import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

// !!! A example deploy script of prompt tag

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, execute } = deployments
  const { deployer } = await getNamedAccounts()

  await deploy("PromptTagSomeOne", {
    contract: "PromptTag",
    from: deployer,
    log: true,
    skipIfAlreadyDeployed: true,
    args: ["Tag-Someone", "T-SOMEONE"],
  })

}

export default func
func.tags = ["PromptTagSomeOne"]
