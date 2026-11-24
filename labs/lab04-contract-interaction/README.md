<sub><code>lab 04 · contract interaction</code></sub>

# Lab 04 · *Contractele vorbesc între ele*

![stare](https://img.shields.io/badge/stare-7%2F8%20exerci%C8%9Bii-855712?style=flat-square) ![teste](https://img.shields.io/badge/teste-41%20passing-2c6649?style=flat-square) ![screenshots](https://img.shields.io/badge/screenshots-37-1f2a48?style=flat-square)

Clientul își folosește punctele ca să cumpere din catalog: `FidelityPoints.redeem` cheamă `Catalog`. Pe drum: events, custom errors, `try`/`catch`, storage layout și optimizări de gas.

| | |
|---|---|
| **raportul meu** | [`RAPORT.md`](RAPORT.md) |
| enunțul | [`enunt.md`](enunt.md) |
| codul primit | [`starter/`](starter/) (soluțiile Lab 3) |
| ce rămâne | Ex 8, deploy pe Sepolia (am nevoie de setup-ul din Lab 2) |

**Ce am măsurat:**

- **packing:** `addProduct` de la 159.075 la 115.509 gas, `startProductPromo` de la 98.909 la 53.692;
- **`try`/`catch`:** cele trei feluri de eșec (`Error`, `Panic` 0x11, custom error) prinse separat;
- **arrays:** `removeProduct` cu *swap and pop* și `productIndex` (poziție + 1).

```bash
cd labs/lab04-contract-interaction
forge test                  # 41 de teste
forge test --gas-report
```

```
src/    Catalog.sol · FidelityPoints.sol · FidelityPointsRequire.sol (7.4)
test/   un fișier per exercițiu, ex. Redeem.t.sol (Ex 4), RemoveProduct.t.sol (6.3)
```

## Setup pe Mac

**Ai nevoie de:** Foundry ([00-setup](../00-setup/)). Pentru Ex 8 (Sepolia), și de setup-ul din [Lab 02](../lab02-solidity-setup/).

**Dacă vrei doar să rulezi soluția mea:** după `git clone --recursive`, `cd labs/lab04-contract-interaction && forge test`.

**Dacă faci labul de la zero**, după Pasul 1 din enunț:

```bash
forge init fidelity-shop --no-git
cd fidelity-shop
rm src/Counter.sol test/Counter.t.sol script/Counter.s.sol
cp <folderul cu starter>/FidelityPoints.sol src/FidelityPoints.sol
cp <folderul cu starter>/Catalog.sol src/Catalog.sol
forge build
```

În enunț fișierele se numesc `FidelityPointsFinal.sol` și `CatalogFinal.sol` și le redenumești cu `sed`. În `starter/` au deja numele bune, deci pasul cu `sed` nu mai e necesar. Dacă îl rulezi totuși, pe Mac e `sed -i '' 's/…/…/' fișier`.

**Rețeaua locală:**

```bash
anvil                                         # tab 1
# tab 2:
export ETH_RPC_URL=http://127.0.0.1:8545
ANVIL_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80    # contul 0 (admin)
CLIENT=0x70997970C51812dc3A010C7d01b50e0d17dc79C8                               # contul 1
CLIENT_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

> **Două tab-uri:** `anvil` rulează în primul tab și rămâne pornit. Comenzile le dai în al doilea (Cmd+T). Variabilele (`export ETH_RPC_URL=…`, `ANVIL_KEY=…`) trebuie setate din nou în fiecare tab nou.

**Alte diferențe pe Mac în labul ăsta:** `date -r <timestamp>` în loc de `date -d @<timestamp>` (la promoții). Starea lui anvil o poți salva cu `anvil --dump-state anvil-state.json` și relua cu `--load-state`. Fișierul nu intră în git.

**Ex 8 (Sepolia):** faci `.env` + `[rpc_endpoints]` ca în [Lab 02, pasul 6](../lab02-solidity-setup/#setup-pe-mac). Apoi `forge create … --rpc-url sepolia --account sepolia-dev --broadcast`.

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
