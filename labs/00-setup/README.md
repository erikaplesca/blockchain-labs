<sub><code>lab 00 · setup</code></sub>

# Setup · *Foundry pe Mac*

![stare](https://img.shields.io/badge/stare-gata-2c6649?style=flat-square) ![foundry](https://img.shields.io/badge/foundry-1.9.0-1f2a48?style=flat-square)

Instalarea uneltelor pentru toate laboratoarele. Enunțul e pentru Linux, eu am făcut-o pe macOS (Apple Silicon, zsh).

| | |
|---|---|
| enunțul | [`enunt.md`](enunt.md) |
| ce am instalat | Foundry 1.9.0 (`forge`, `cast`, `anvil`, `chisel`), cu PATH în `~/.zshrc` |

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge --version
```

Diferențe pe Mac pe care le-am întâlnit în laboratoare: `sed -i ''` în loc de `sed -i`, `date -r` în loc de `date -d`, iar `setopt interactivecomments` în zsh ca să pot lipi comenzi cu comentarii.

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
