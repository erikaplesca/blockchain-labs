<sub><code>lab 03 · fidelity points</code></sub>

# Lab 03 · *Punctele de fidelitate*

![stare](https://img.shields.io/badge/stare-de%20recuperat-66645f?style=flat-square)

Bazele Solidity pe două contracte, `FidelityPoints` și `Catalog`: tipuri, data locations, visibility, primul proiect Foundry, teste și deploy pe anvil.

| | |
|---|---|
| enunțul | [`enunt.md`](enunt.md) |
| codul primit | [`starter/`](starter/) (`FidelityPoints.sol`, `Catalog.sol`, `test/FidelityPoints.t.sol`) |
| legătura | soluțiile lui sunt punctul de plecare din [Lab 04](../lab04-contract-interaction/), deci conceptele le-am folosit deja acolo |

## Setup pe Mac

**Ai nevoie de:** Foundry ([00-setup](../00-setup/)). Pentru Pasul 4 (Sepolia), și de setup-ul din [Lab 02](../lab02-solidity-setup/).

1. **Proiectul**, creat în folderul ăsta:

   ```bash
   cd labs/lab03-fidelity-points
   forge init fidelity-points --no-git          # --no-git: repo-ul e deja unul singur, la rădăcină
   cd fidelity-points
   rm src/Counter.sol test/Counter.t.sol script/Counter.s.sol
   cp ../starter/FidelityPoints.sol ../starter/Catalog.sol src/
   cp ../starter/test/FidelityPoints.t.sol test/
   forge build
   forge inspect FidelityPoints abi
   ```

2. **Rețeaua locală (Pasul 2):**

   ```bash
   anvil                                        # tab 1
   export ETH_RPC_URL=http://127.0.0.1:8545     # tab 2
   ANVIL_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80   # contul 0 din anvil
   forge create src/FidelityPoints.sol:FidelityPoints --private-key $ANVIL_KEY --broadcast --constructor-args 10
   ```

3. **Teste (Pasul 3):** `forge test`, `forge test -vvvv`, `forge test --gas-report`.
4. **Sepolia (Pasul 4):** faci `.env` + `[rpc_endpoints]` ca în [Lab 02, pasul 6](../lab02-solidity-setup/#setup-pe-mac), apoi:

   ```bash
   forge create src/FidelityPoints.sol:FidelityPoints \
     --rpc-url sepolia --account sepolia-dev --broadcast --constructor-args 10
   ```

> **Două tab-uri:** `anvil` rulează în primul tab și rămâne pornit. Comenzile le dai în al doilea (Cmd+T). Variabilele (`export ETH_RPC_URL=…`, `ANVIL_KEY=…`) trebuie setate din nou în fiecare tab nou.

> **`forge-std` ca submodul.** Dacă vrei să urci proiectul pe GitHub, adaugă `lib/forge-std` ca submodul din rădăcina repo-ului, cum sunt la Lab 4–7: `git submodule add https://github.com/foundry-rs/forge-std labs/lab03-fidelity-points/fidelity-points/lib/forge-std`.

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
