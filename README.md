# EUBIng: the next-generation way to hold shares in the insurance company

EUBIng is the next-generation way to hold shares in the insurance company. EUBIng follows the ERC-1726 standard for dividends-paying tokens.
The Ethereum version can have dividends paid in the USDC stablecoin, which make EUBIng tokens similar to shares, while the MintME version pays dividends using MintME.
The MintME version contains a DeFi presaler, while the Ethereum version don't. A trustee service will be launched 7 days after deployment on each blockchains.
The trustee service allows creation of revocable/irrevocable trusts.

## Auction rules

You send MintME to the EUBIDEFI smart contract (not the EUBIng one). The EUBIDEFI smart contract sends you back EUBIng tokens.

We used a slightly modified version of the dutch auction that is blockchain-friendly: The price is calculated at the time of purchase, and is adjusted for demmand. Whenever someone buys EUBIng tokens at lower than the maximum price of 500 MintME, the price goes up a bit. If the EUBIDEFI dutch auction is behind the sale goal by more than 500 EUBIng tokens, a discount will apply, and if it is behind the sale goal by more than 1000 EUBIng tokens, the minimum price of 250 MintME will be used.

We used the dutch auction since it is very lightweight on gas (only 59700 gas per buy order), and is more blockchain-friendly than the vickrey/english auction.

## Token migration

Up to 1 Million EUBI classic (deployed and traded on MintMe.com) tokens can be upgraded into EUBIng tokens. All you need to do is to approve the EUBIng smart contract to spend some of your old EUBI classic tokens. Your old EUBI tokens will be migrated when you run out of EUBIng tokens. Let's say you have 1 EUBIng token and 2 EUBI classic tokens. If you try to spend 1.5 EUBIng after having approved the EUBIng smart contract to spend your EUBI classic tokens, the EUBIng smart contract would first try to spend 1 EUBIng. Since we don't have sufficent balance to complete the transaction, the EUBIng smart contract would migrate all our EUBI classic tokens, leaving us with a balance of 1.5 EUBIng after the transaction. Also, you can send to your own address to force migrate the tokens. Note that your indicated balnce is your EUBIng balance + EUBI classic available for migration. The old EUBI classic tokens will be burned.

[Information about the ERC-20 approve function](https://docs.openzeppelin.com/contracts/2.x/api/token/erc20#IERC20-approve-address-uint256-)

## Roadmap

18/05/2021: MintME deployment and EUBIDEFI deployment

Address of EUBIng token contract: 0xfc502c4126fe45456ccc261ad26bca6bca7c4735
Address of EUBIDEFI token contract: 0xF46C1781aab1962f428Ff79E013fc446e79A8D8E

25/05/2021: MintME trustee service launch

18/06/2021: Ethereum deployment

19/06/2021: Uniswap V2 pair creation on Ethereum

25/06/2021: Ethereum trustee service launch
