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

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
