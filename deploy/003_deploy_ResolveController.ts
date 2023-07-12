import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, execute } = deployments
  const { deployer } = await getNamedAccounts()

  const trustSigner = process.env.TRUST_SIGNER_ADDRESS || deployer
  const cellIDRegistry = await deployments.get("CellIDRegistry")
  const cellNameSpace = await deployments.get("CellNameSpace")

  await deploy("ResolveController", {
    from: deployer,
    log: true,
    skipIfAlreadyDeployed: true,
    // proxy: {
    //     owner: deployer,
    //     proxyContract: 'OptimizedTransparentProxy',

    //     execute: {
    //         init: {
    //             methodName: 'initialize',
    //             args: [cellIDRegistry, cellNameSpace, trustSigner]
    //         }
    //     }
    // }

  })

  await execute(
    "ResolveController",
    { from: deployer, log: true },
    "initialize",
    cellIDRegistry.address,
    cellNameSpace.address,
    trustSigner
  )

  await execute(
    "CellIDRegistry",
    { from: deployer, log: true },
    "setController",
    (await deployments.get("ResolveController")).address
  )

  await execute(
    "CellNameSpace",
    { from: deployer, log: true },
    "setController",
    (await deployments.get("ResolveController")).address
  )

}

export default func
func.tags = ["ResolveController"]
func.dependencies = ["CellIDRegistry", "CellNameSpace"]
