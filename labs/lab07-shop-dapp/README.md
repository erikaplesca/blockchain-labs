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

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
