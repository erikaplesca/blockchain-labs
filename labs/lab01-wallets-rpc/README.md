<sub><code>lab 01 · wallets & rpc</code></sub>

# Lab 01 · *Adrese, wallets și RPC*

![stare](https://img.shields.io/badge/stare-de%20recuperat-66645f?style=flat-square)

Conturi Ethereum, rețele locale cu `anvil` și un exercițiu de echipă (*signer* și *publisher*) despre rolul **chain ID**-ului și al **nonce**-ului.

| | |
|---|---|
| enunțul | [`enunt.md`](enunt.md) |
| șablonul de raport | [`raport-template.md`](raport-template.md) |
| ce rămâne | exercițiul se face în echipă de 2–3, deci îl recuperez cu un coleg |

## Setup pe Mac

**Ai nevoie de:** Foundry, din [00-setup](../00-setup/). Nu-ți trebuie proiect Foundry, totul se face cu `cast` și `anvil`.

1. **Contul `lab1`.** Generezi o cheie, apoi o imporți într-un keystore criptat (îți cere cheia și o parolă):

   ```bash
   cast wallet new
   cast wallet import lab1 --interactive
   cast wallet list
   cast wallet address --account lab1
   ```

2. **Rețeaua locală:**

   ```bash
   anvil                                        # tab 1
   export ETH_RPC_URL=http://127.0.0.1:8545     # tab 2
   ```

3. **Exercițiul de echipă (signer / publisher)** are nevoie de 2–3 oameni. Publisher-ul pornește două rețele, fiecare în tab-ul ei:

   ```bash
   anvil --no-mining                                  # Network 1: chain ID 31337, port 8545
   anvil --no-mining --port 8546 --chain-id 1337      # Network 2: chain ID 1337, port 8546
   ```

   Signer-ul nu pornește niciun nod și nu folosește `--rpc-url`: doar `cast wallet` și `cast mktx`. Raportul se completează în [`raport-template.md`](raport-template.md).

> **Două tab-uri:** `anvil` rulează în primul tab și rămâne pornit. Comenzile le dai în al doilea (Cmd+T). Variabilele (`export ETH_RPC_URL=…`, `ANVIL_KEY=…`) trebuie setate din nou în fiecare tab nou.

<sub>[← înapoi la toate laboratoarele](../../README.md)</sub>
