# Cell Contract
The smart contracts behind Cell Protocol.

:building_construction:The contracts are compiled with [Hardhat](https://hardhat.org/getting-started/), and tested using [Foundry](https://hardhat.org/hardhat-runner/plugins/nomicfoundation-hardhat-foundry).



## Overview



## Usage

### Pre Requisites

Before being able to run any command, you need to create a `.env` file and set environment variables. You can follow the example in `.env.example`.

Then, proceed with installing dependencies:

```
$ yarn install
```



### Compile

Compile the smart contracts with Hardhat:

```
$ yarn hardhat compile
```



### Test

Run the tests with Hardhat-foundry:

```
$ forge test
```



### Deploy

Deploy the contracts to Hardhat Network:

```
$ yarn hardhat --network <network> deploy
```



## License

The primary license for Cell Protocol is the MIT License, see [MIT LICENSE](https://github.com/cell-protocol-social/cell-contract/blob/main/LICENSE).
