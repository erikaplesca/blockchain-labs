<sub><code>lab 05 · erc-20 tokens</code></sub>

# Lab 05 · *Punctele devin token*

![stare](https://img.shields.io/badge/stare-2%2F2%20exerci%C8%9Bii-2c6649?style=flat-square) ![teste](https://img.shields.io/badge/teste-58%20passing-2c6649?style=flat-square) ![openzeppelin](https://img.shields.io/badge/OpenZeppelin-5.7.0-1f2a48?style=flat-square)

Token standards cu OpenZeppelin: punctele de fidelitate devin tokenul ERC-20 **FPT**, iar badge-urile sunt NFT-uri ERC-721.

| | |
|---|---|
| **raportul meu** | [`RAPORT.md`](RAPORT.md) |
| enunțul | [`enunt.md`](enunt.md) |
| codul primit | [`starter/`](starter/) (`MyERC20` + teste) |
| ce rămâne | pașii de deploy cu script (local și Sepolia) |

**Ce am făcut:**

- **Ex 1:** `FidelityPoints` rescris peste `FidelityToken` (ERC20 + Burnable + Capped + Ownable), 11 teste;
- **Ex 2:** `FeeToken`, 1% taxă la transferul între clienți, cu un singur `override` pe `_update`, 8 teste.

```bash
cd labs/lab05-erc20-tokens
forge test                  # 58 de teste (34 din laborator + 5 MyERC20 + 19 ale mele)
```

## Setup pe Mac

**Ai nevoie de:** Foundry ([00-setup](../00-setup/)) și acces la github.com, pentru OpenZeppelin. Pentru Pasul 5 (Sepolia), și de setup-ul din [Lab 02](../lab02-solidity-setup/).

**Dacă vrei doar să rulezi soluția mea:** după `git clone --recursive`, `cd labs/lab05-erc20-tokens && forge test`. Dacă `lib/openzeppelin-contracts` e gol, rulezi `git submodule update --init --recursive`.

**Dacă faci labul de la zero**, după Pasul 1 din enunț:

```bash
forge init tokens-lab
cd tokens-lab
rm src/Counter.sol test/Counter.t.sol script/Counter.s.sol
forge install OpenZeppelin/openzeppelin-contracts@v5.7.0
forge remappings > remappings.txt     # @openzeppelin/contracts/ -> lib/openzeppelin-contracts/contracts/
```

Codul pentru `FidelityToken.sol`, `LoyaltyBadge.sol` și `BadgeShop.sol` e în enunț (Pasul 2). `MyERC20` e în [`starter/`](starter/), cu testul lui:

```bash
cp <folderul cu starter>/MyERC20.sol src/ && cp <folderul cu starter>/MyERC20.t.sol test/
forge build && forge test
```

> **De ce `forge init` fără `--no-git` aici:** `forge install` are nevoie de git ca să adauge OpenZeppelin ca submodul. Dacă proiectul stă într-un repo existent, rulezi `forge install` din folderul proiectului și git îl adaugă în repo-ul de deasupra.

**Deploy local (Pasul 4):**

```bash
anvil                                         # tab 1
export ETH_RPC_URL=http://127.0.0.1:8545      # tab 2
ANVIL_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script script/Deploy.s.sol --rpc-url $ETH_RPC_URL --private-key $ANVIL_KEY --broadcast
```

**Sepolia (Pasul 5):** `cp .env.example .env`, completezi `SEPOLIA_RPC_URL` (vezi [Lab 02](../lab02-solidity-setup/#setup-pe-mac)), apoi `forge script script/Deploy.s.sol --rpc-url sepolia --account sepolia-dev --broadcast`.

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
