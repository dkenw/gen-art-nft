import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-contract-sizer';
import 'hardhat-storage-layout';
import { HardhatUserConfig, task } from 'hardhat/config';

task('layout', 'Print contract storage layout', async (_args, hre) => {
  await hre.run('compile');
  await hre.storageLayout.export();
});

task('compile-size-contracts', 'Compile and measure contract size', async (_args, hre) => {
  await hre.run('compile');
  await hre.run('size-contracts');
});

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      accounts: { accountsBalance: '1000000000000000000000000000000000000000000000' }, // 1e45
      initialBaseFeePerGas: 0,
      gasPrice: 0,
    },
  },
  solidity: {
    compilers: [
      {
        version: '0.8.10',
        settings: {
          optimizer: { enabled: true, runs: 9999 },
        },
      },
    ],
    overrides: {},
  },
};

export default config;
