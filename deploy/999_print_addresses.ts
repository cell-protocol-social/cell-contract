import { Deployment } from "hardhat-deploy/dist/types"
import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getUnnamedAccounts, getChainId } = hre
  const { execute, log, read, all } = deployments

  const allContracts: { [p: string]: Deployment } = await all()

  console.table(
    Object.keys(allContracts).map((k) => [k, allContracts[k].address]),
  )
}
export default func
