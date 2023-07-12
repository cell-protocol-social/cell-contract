import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, execute } = deployments
  const { deployer } = await getNamedAccounts()

  const treasury = process.env.TREASURY_ADDRESS || deployer
  const trustSigner = process.env.TRUST_SIGNER_ADDRESS || deployer

  await deploy("CellNameSpace", {
    from: deployer,
    log: true,
    skipIfAlreadyDeployed: true,
    proxy: {
        owner: deployer,
        proxyContract: 'OptimizedTransparentProxy',

        execute: {
            init: {
                methodName: 'initialize',
                args: ["Cell NameSpace", "CNS", treasury, trustSigner]
            }
        }
    }
  })

}

export default func
func.tags = ["CellNameSpace"]
