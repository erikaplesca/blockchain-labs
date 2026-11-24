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

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
