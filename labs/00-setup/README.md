<sub><code>lab 00 · setup</code></sub>

# Setup · *Foundry pe Mac*

![stare](https://img.shields.io/badge/stare-gata-2c6649?style=flat-square) ![foundry](https://img.shields.io/badge/foundry-1.9.0-1f2a48?style=flat-square)

Instalarea uneltelor pentru toate laboratoarele. Enunțul e pentru Linux, eu am făcut-o pe macOS (Apple Silicon, zsh).

| | |
|---|---|
| enunțul | [`enunt.md`](enunt.md) |
| ce am instalat | Foundry 1.9.0 (`forge`, `cast`, `anvil`, `chisel`), cu PATH în `~/.zshrc` |
| următorul pas | [Lab 02](../lab02-solidity-setup/#setup-pe-mac) pentru MetaMask, Infura și Sepolia |

## Setup pe Mac

Enunțul e pentru Linux. Pe Mac (zsh, Apple Silicon) pașii sunt:

1. **Git.** Verifici cu `git --version`. Dacă nu e instalat, macOS îți propune singur să instalezi *Command Line Tools*. Altfel rulezi `xcode-select --install`.
2. **Foundry:**

   ```bash
   curl -L https://getfoundry.sh/install | bash
   ```

3. **Reîncarci shell-ul.** Enunțul zice `source ~/.bashrc`, dar pe Mac shell-ul e zsh. Cel mai simplu: deschizi un tab nou de Terminal (Cmd+T).
4. **Instalezi uneltele și verifici:**

   ```bash
   foundryup
   forge --version && cast --version && anvil --version && chisel --version
   ```

   Dacă apare `command not found`, mai deschide un tab nou.
5. **Comentariile din comenzi.** În enunțuri, multe comenzi au comentarii la final (`anvil   # în alt tab`). zsh nu le acceptă implicit în terminal, așa că le activezi o dată:

   ```bash
   echo 'setopt interactivecomments' >> ~/.zshrc && source ~/.zshrc
   ```

**Diferențe pe care le vei întâlni în laboratoare:**

| enunțul (Linux) | pe Mac |
|---|---|
| `source ~/.bashrc` | tab nou (Cmd+T) |
| `sed -i 's/a/b/' f` | `sed -i '' 's/a/b/' f` |
| `date -d @1700000000` | `date -r 1700000000` |
| „al doilea terminal” | Cmd+T. Variabilele se setează în fiecare tab |
| Windows / WSL | ignori |

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
