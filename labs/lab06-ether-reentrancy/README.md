<sub><code>lab 06 · ether & re-entrancy</code></sub>

# Lab 06 · *Ether și securitate*

![stare](https://img.shields.io/badge/stare-4%2F4%20exerci%C8%9Bii-2c6649?style=flat-square) ![teste](https://img.shields.io/badge/teste-38%20passing-2c6649?style=flat-square) ![screenshots](https://img.shields.io/badge/screenshots-10-1f2a48?style=flat-square)

Cum primește și trimite ether un contract (`receive`, `fallback`, `transfer`/`send`/`call`), atacul de **re-entrancy** pe o licitație și apărarea: *checks–effects–interactions* + *pull over push*.

| | |
|---|---|
| **raportul meu** | [`RAPORT.md`](RAPORT.md) |
| enunțul | [`enunt.md`](enunt.md) |
| codul primit | [`starter/`](starter/) (`Auction`, `EtherReceiver` + teste) |

**Ce am făcut:**

- `ExN.sol` + `ExN.t.sol` pentru fiecare exercițiu, testele au numărul punctului în nume (`test_3_1_...`);
- `PrizeAttacker` golește licitația prin re-entrancy, `nonReentrant` cu `bool transient locked` îl oprește;
- Push vs Pull cu 5 ofertanți: **230.596** gas (5 tx) vs **427.479** gas (9 tx), dar Pull nu poate fi blocat de un `MaliciousRejecter`.

```bash
cd labs/lab06-ether-reentrancy
forge test                  # 38 de teste
```

## Setup pe Mac

**Ai nevoie de:** Foundry ([00-setup](../00-setup/)). Labul ăsta e doar local: anvil și teste, fără Sepolia.

**Dacă vrei doar să rulezi soluția mea:** după `git clone --recursive`, `cd labs/lab06-ether-reentrancy && forge test`.

**Dacă faci labul de la zero**, după Pasul 1 din enunț. În `starter/` fișierele sunt toate la un loc, fără `src/` și `test/`:

```bash
forge init lab6 --no-git
cd lab6
rm src/Counter.sol test/Counter.t.sol script/Counter.s.sol
cp <folderul cu starter>/EtherReceiver.sol <folderul cu starter>/Auction.sol src/
cp <folderul cu starter>/EtherReceiver.t.sol <folderul cu starter>/Reentrancy.t.sol test/
forge build          # citește warning-urile 3628 (Ex 1.4)
```

**Rețeaua locală (Pașii 2–4):**

```bash
anvil                                          # tab 1
# tab 2:
export ETH_RPC_URL=http://127.0.0.1:8545
ANVIL_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80    # contul 0
MALLORY_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d  # contul 1
ALICE_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a    # contul 2
BOB_KEY=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6      # contul 3
```

> **Două tab-uri:** `anvil` rulează în primul tab și rămâne pornit. Comenzile le dai în al doilea (Cmd+T). Variabilele (`export ETH_RPC_URL=…`, `ANVIL_KEY=…`) trebuie setate din nou în fiecare tab nou.

**Pentru Ex 4.4 (gas Push vs Pull):** `forge test --match-test 5Bidders --isolate --gas-report`.

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
