<sub><code>lab 07 · shop dapp</code></sub>

# Lab 07 · *Contractul ajunge în browser*

![stare](https://img.shields.io/badge/stare-4%2F4%20%C2%B7%20screenshots-855712?style=flat-square) ![teste](https://img.shields.io/badge/teste-4%20passing-2c6649?style=flat-square) ![stack](https://img.shields.io/badge/React%2019%20%2B%20ethers%20v6-1f2a48?style=flat-square)

O pagină React care citește starea lui `FidelityPoints`, trimite tranzacții prin MetaMask și se actualizează singură din events.

| | |
|---|---|
| **raportul meu** | [`RAPORT.md`](RAPORT.md) |
| enunțul | [`enunt.md`](enunt.md) |
| codul primit | [`starter/`](starter/) (demo-dapp-ul de la care am pornit) |
| ce rămâne | 8 screenshots în raport |

**Ce am făcut:**

- **Ex 1:** valoarea punctelor (`getTotalValue`), actualizată și la `PointValueChanged`;
- **Ex 2:** istoricul `PointsAdded` cu `queryFilter` de la `fromBlock`, plus cele noi din subscripție;
- **Ex 3:** `SpendPanel` pentru `spendPoints`, cu eroarea afișată când clientul cere prea mult;
- **Ex 4:** fără `contract.off`, după 4 schimbări de cont: 17 subscripții în loc de 6, adică un request leak.

```bash
cd labs/lab07-shop-dapp/contracts && forge test     # 4 teste
anvil                                               # în alt tab
forge script script/DeployFidelityPoints.s.sol --rpc-url http://127.0.0.1:8545 --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80   # contul 0 din anvil
cd .. && npm install && npm run dev                 # http://localhost:5173
```

## Setup pe Mac

**Ai nevoie de:**
- Foundry ([00-setup](../00-setup/));
- **Node.js 20.19+**: `brew install node` sau installer-ul de pe [nodejs.org](https://nodejs.org/). Verifici cu `node --version`;
- **MetaMask** în Chrome (vezi [Lab 02](../lab02-solidity-setup/#setup-pe-mac)). Aici folosești doar rețeaua locală, fără Sepolia.

**1. Contractul: build și teste**

```bash
cd labs/lab07-shop-dapp/contracts
forge build && forge test          # 4 teste
```

Dacă `lib/forge-std` lipsește: `git submodule update --init --recursive`, din rădăcina repo-ului.

**2. anvil, în alt tab (Cmd+T), lăsat pornit**

```bash
anvil
```

**3. Deploy.** Scriptul scrie adresa și ABI-ul în `src/contracts/`, de unde le citește pagina:

```bash
forge script script/DeployFidelityPoints.s.sol --rpc-url http://127.0.0.1:8545 --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**4. MetaMask**

1. *Add network manually*: nume `Anvil`, RPC URL `http://127.0.0.1:8545`, chain ID `31337`, monedă `ETH`.
2. *Import account* cu cheile publice ale lui anvil:

   | cont | adresă | cheie privată |
   |---|---|---|
   | 0, admin | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` |
   | 1, client | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` |

   Cheile astea sunt publice, deci le folosești **doar** pe anvil.

**5. Pagina**

```bash
cd labs/lab07-shop-dapp
npm install
npm run dev                        # http://localhost:5173
```

Te conectezi cu MetaMask. Ca să vezi subscripția la events, deschizi o a doua fereastră (sau alt profil Chrome cu MetaMask), cu contul admin, și dai **Add 100 points** clientului.

**După ce repornești anvil:**
1. Rulezi din nou deploy-ul (pasul 3).
2. În MetaMask: *Settings → Advanced → Clear activity tab data*. Altfel tranzacțiile pică cu *nonce too high*.

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
