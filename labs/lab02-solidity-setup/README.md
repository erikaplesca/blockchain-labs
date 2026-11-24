<sub><code>lab 02 · solidity & sepolia setup</code></sub>

# Lab 02 · *Primul contract și Sepolia*

![stare](https://img.shields.io/badge/stare-de%20recuperat-66645f?style=flat-square)

Primul contract `FidelityPoints` și setup-ul pentru rețeaua de test: MetaMask, Infura, ether de test, keystore-ul `sepolia-dev`.

| | |
|---|---|
| enunțul | [`enunt.md`](enunt.md) (doar partea de prerequisites, ghidul principal lipsește) |
| codul primit | [`starter/FidelityPoints.sol`](starter/FidelityPoints.sol) |
| de ce contează | fără setup-ul ăsta nu pot face deploy-urile pe Sepolia din Lab 4 (Ex 8) și Lab 5 (Pasul 5) |

## Setup pe Mac

Labul ăsta e de fapt setup-ul pentru tot ce urmează pe **Sepolia**: Lab 3 (Pasul 4), Lab 4 (Ex 8) și Lab 5 (Pasul 5). Îl faci o singură dată.

1. **Foundry la zi:** `foundryup`, apoi `forge --version`. Git trebuie să fie instalat (`git --version`), pentru că `forge init` creează un repo git.
2. **MetaMask**, în Chrome, **doar** de pe [metamask.io/download](https://metamask.io/download/):
   - creezi un wallet nou, **doar pentru curs**, fără bani reali;
   - Secret Recovery Phrase-ul îl scrii pe hârtie, nu în fișiere și nu în repo;
   - activezi rețelele de test (*Settings → Advanced → Show test networks*) și alegi **Sepolia**.
3. **Keystore-ul `sepolia-dev`.** În MetaMask: detaliile contului, apoi *Show private key*. Apoi:

   ```bash
   cast wallet import sepolia-dev --interactive    # lipești cheia, alegi o parolă
   cast wallet address --account sepolia-dev       # trebuie să fie aceeași adresă ca în MetaMask
   clear
   ```

4. **Infura:** îți faci cont pe [developer.metamask.io](https://developer.metamask.io/), verifici că **Ethereum Sepolia** e bifată la API key și copiezi endpoint-ul `https://sepolia.infura.io/v3/<API_KEY>`.
5. **Ether de test.** Îți ajung ~0,05 SepoliaETH. Faucet-uri: [MetaMask](https://developer.metamask.io/faucet), [Google Cloud](https://cloud.google.com/application/web3/faucet/ethereum/sepolia), [pk910 (PoW)](https://sepolia-faucet.pk910.de/). Verifici soldul:

   ```bash
   cast balance $(cast wallet address --account sepolia-dev) --ether \
     --rpc-url https://sepolia.infura.io/v3/<API_KEY>
   ```

6. **În fiecare proiect care face deploy pe Sepolia:** endpoint-ul îl pui în `.env`, care e deja în `.gitignore`, deci **nu ajunge pe GitHub**:

   ```bash
   echo 'SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/<API_KEY>' > .env
   grep -x ".env" .gitignore         # trebuie să afișeze .env
   ```

   Apoi adaugi alias-ul la finalul lui `foundry.toml`:

   ```toml
   [rpc_endpoints]
   sepolia = "${SEPOLIA_RPC_URL}"
   ```

   Și verifici că ești pe Sepolia (chain ID-ul trebuie să fie `11155111`):

   ```bash
   unset ETH_RPC_URL
   cast chain-id --rpc-url sepolia
   ```

> **Cheia privată nu intră niciodată în `.env`.** Tranzacțiile se semnează cu `--account sepolia-dev`, iar Foundry îți cere parola keystore-ului.

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
