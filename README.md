# EUBIng: the next-generation way to hold shares in the insurance company

EUBIng is the next-generation way to hold shares in the insurance company. EUBIng follows the ERC-1726 standard for dividends-paying tokens.
The Ethereum version can have dividends paid in the USDC stablecoin, which make EUBIng tokens similar to shares, while the MintME version pays dividends using MintME.
The MintME version contains a DeFi presaler, while the Ethereum version don't. A trustee service will be launched 7 days after deployment on each blockchains.
The trustee service allows creation of revocable/irrevocable trusts.

## Auction rules

You send MintME to the EUBIDEFI smart contract (not the EUBIng one). The EUBIDEFI smart contract sends you back EUBIng tokens.

We used a slightly modified version of the dutch auction that is blockchain-friendly: The price is calculated at the time of purchase, and is adjusted for demmand. Whenever someone buys EUBIng tokens at lower than the maximum price of 500 MintME, the price goes up a bit. If the EUBIDEFI dutch auction is behind the sale goal by more than 500 EUBIng tokens, a discount will apply, and if it is behind the sale goal by more than 1000 EUBIng tokens, the minimum price of 250 MintME will be used.

## Roadmap

18/05/2021: MintME deployment and EUBIDEFI deployment

25/05/2021: MintME trustee service launch

18/06/2021: Ethereum deployment

19/06/2021: Uniswap V2 pair creation on Ethereum

25/06/2021: Ethereum trustee service launch
