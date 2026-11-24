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

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
