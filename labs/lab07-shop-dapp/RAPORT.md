# Laborator 7: Shop dApp (citirea stării, tranzacții și events din pagina web)

**Erika Plesca**, FMI, anul 3, Blockchain
Mediu: macOS, Foundry 1.9.0, Node.js 26, React 19 + Vite 7, ethers.js v6, MetaMask, anvil (chain ID 31337)

## Structura

```
lab07-shop-dapp/
├── enunt.md                     (enunțul)
├── starter/                     (demo-dapp-ul primit, punctul de plecare)
├── contracts/                   (Foundry: FidelityPoints cu events, scriptul de deploy, teste)
└── src/
    ├── utils/EthersUtils.js     (toate apelurile către contract: aici e cea mai mare parte din exerciții)
    ├── components/Points.jsx    (pagina: sold, valoare, istoric, subscripții)
    ├── components/AdminPanel.jsx   (+ formularul pentru setPointValue)
    ├── components/SpendPanel.jsx   (Ex 3, nou)
    ├── components/History.jsx      (Ex 2, nou)
    └── styles/Points.css
```

## Setup

```bash
cd contracts && forge build && forge test        # 4 teste
anvil                                            # în alt tab
forge script script/DeployFidelityPoints.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xac09...ff80
cd .. && npm install && npm run dev              # http://localhost:5173
```

Scriptul de deploy scrie adresa și ABI-ul în `src/contracts/`, iar de acolo le citește pagina. În MetaMask am adăugat rețeaua Anvil (`http://127.0.0.1:8545`, chain ID 31337) și am importat contul 0 (admin) și contul 1 (client).

![Setup: teste și deploy](screenshots/setup-deploy.png)
![Setup: deploy reușit](screenshots/setup-deploy-2.png)

<!-- screenshot: screenshots/setup-page.png -->

---

## Exercițiul 1: Valoarea punctelor + `PointValueChanged`

Sub numărul de puncte afișez `getTotalValue(account)`, adică `points × pointValue`, în unitatea prețurilor din catalog.

```js
// EthersUtils.js
const getTotalValue = async (address, blockTag = 'latest') =>
    Number(await getContract().getTotalValue(address, {blockTag}));

const subscribeToPointValueChanges = (onChange) => {
    const contract = getContract();
    const filter = contract.filters.PointValueChanged();
    const handle = (...args) => onChange(args[args.length - 1].log.blockNumber);
    contract.on(filter, handle);
    return () => contract.off(filter, handle);
};
```

**Când se actualizează valoarea:**

- **la `PointsAdded` și `PointsSpent` ale contului:** se schimbă numărul de puncte;
- **la `PointValueChanged`:** se schimbă valoarea unui punct.

În ambele cazuri pagina **recitește** din contract, la blocul evenimentului: punctele, `getTotalValue` și `pointValue`. Nu calculez nimic din datele event-ului, așa că starea contractului rămâne singura sursă de adevăr.

**Filtrul nu are cont:** `PointValueChanged(uint oldValue, uint newValue)` nu are niciun parametru `indexed`. Filtrul are doar primul topic (hash-ul semnăturii), deci **toți** clienții primesc evenimentul. E corect, pentru că schimbarea valorii punctului îi afectează pe toți.

Ca admin-ul să poată schimba valoarea din pagină, am adăugat în `AdminPanel` un formular **Set point value**. Merge și cu `cast send ... "setPointValue(uint256)" 20`.

| Moment | Puncte | Valoare punct | Valoare afișată |
|---|---|---|---|
| după `addPoints(client, 100)` | 100 | 10 | **1.000** |
| admin-ul face `setPointValue(20)` | 100 | 20 | **2.000**, în fereastra clientului, fără reload |

<!-- screenshot: screenshots/ex1-value-before.png -->

<!-- screenshot: screenshots/ex1-value-after.png -->

---

## Exercițiul 2: Istoricul punctelor primite

```js
// la încărcarea paginii: evenimentele din trecut
const getPointsHistory = async (client) => {
    const contract = getContract();
    const events = await contract.queryFilter(contract.filters.PointsAdded(client), FROM_BLOCK);
    return events.map(toHistoryEntry);      // {id, blockNumber, amount, txHash}
};
```

- **`FROM_BLOCK`** vine din `addresses.json` (`fromBlock`), adică blocul în care a fost deployat contractul. Nu are rost să caut mai devreme.
- **`queryFilter` e echivalentul lui `cast logs`:** un singur `eth_getLogs` cu topic-ul contului. Filtrarea o face nodul.
- **Evenimentele noi** vin din subscripția deja existentă. Am modificat `subscribeToPointsChanges` ca, la `PointsAdded`, să trimită pe lângă numărul blocului și detaliile log-ului, pe care pagina le adaugă în listă.
- **Fără duplicate:** același log ar putea veni și din `queryFilter`, și din subscripție, dacă evenimentul apare chiar în timp ce pagina se încarcă. De aceea fiecare intrare are un id unic, `txHash + "-" + logIndex`, iar pagina ignoră id-urile pe care le are deja.

Rezultat: după reload, istoricul e tot acolo, pentru că vine din logs, nu din memoria paginii. Punctele date altui cont nu apar în lista mea.

<!-- screenshot: screenshots/ex2-history.png -->

---

## Exercițiul 3: `spendPoints`

`SpendPanel.jsx` are un câmp și butonul **Spend points**, care apelează `spendPoints(amount)` cu signer-ul contului conectat. Contractul scade din `points[msg.sender]`, deci fiecare își poate cheltui doar propriile puncte.

**Soldul se actualizează prin event, nu prin cod:** după `tx.wait()` nu modific soldul în pagină. Îl actualizează subscripția, când vine evenimentul `PointsSpent(client, amount)`. Am verificat: 150 → spend 30 → **120**, după câteva secunde.

**Ce se întâmplă dacă clientul cheltuie mai mult decât are?**

> `spendPoints` face `points[msg.sender] -= _points`. În Solidity 0.8 scăderea e verificată, deci 70 − 1000 dă revert cu **`Panic(0x11)`** (underflow).
>
> - **Tranzacția nici nu se trimite.** Înainte să o semneze, MetaMask (prin ethers) face `eth_estimateGas`, iar estimarea pică. Clientul **nu plătește gas** și starea nu se schimbă.
> - În pagină, eroarea vine cu error data `0x4e487b71…11`. Am adăugat în `getErrorMessage` decodarea pentru `Panic`, așa că pagina afișează *"You don't have enough points (the subtraction underflowed: Panic 0x11)."*
> - Contractul din proiect nu are o eroare custom pentru asta, de aceea apare un `Panic`. Cu un `if (available < amount) revert InsufficientPoints(...)` (ca la Lab 4, Ex 7.2), mesajul ar putea spune și câte puncte are clientul.

<!-- screenshot: screenshots/ex3-spend-ok.png -->

<!-- screenshot: screenshots/ex3-spend-too-much.png -->

---

## Exercițiul 4: Fără `contract.off`

Ca să nu șterg codul, am pus un „comutator” în `EthersUtils.js`:

```js
const UNSUBSCRIBE_ON_CLEANUP = true;     // Ex 4: pune false
...
return () => {
    if (!UNSUBSCRIBE_ON_CLEANUP) return;   // nu mai apelăm contract.off
    contract.off(addedFilter, handleAdded);
    contract.off(spentFilter, handleSpent);
};
```

Ca să se vadă efectul, în josul paginii afișez **numărul de subscripții active** ale provider-ului (`provider.listenerCount()`, actualizat la 2 secunde).

**Ce se întâmplă:** în `Points.jsx`, `<Dashboard key={wallet.address} …/>` creează un Dashboard **nou** la fiecare schimbare de cont. Cel vechi e scos de pe ecran, iar React îi rulează funcția de cleanup din `useEffect`. Fără `off`, cleanup-ul nu mai oprește nimic, iar subscripțiile Dashboard-ului vechi rămân active.

Am măsurat cu un test al funcțiilor din `EthersUtils.js` pe un anvil separat:

| | cu `off` | fără `off`, după 4 schimbări de cont |
|---|---|---|
| subscripții active (`listenerCount`) | 6 | **17** |
| cereri `eth_getFilterChanges` la fiecare polling (4 s) | 3 | **5** |
| apelări ale handler-ului pentru **un** `PointValueChanged` | 1 | **4** |

<!-- screenshot: screenshots/ex4-subscriptions.png -->

<!-- screenshot: screenshots/ex4-anvil-requests.png -->

**Explicație:**

- **Provider-ul face polling:** la fiecare 4 secunde întreabă nodul dacă sunt logs noi pentru **fiecare filtru**. Filtrele vechi (`PointsAdded(contulVechi)` etc.) rămân în listă, deci cererile se înmulțesc cu fiecare cont prin care am trecut. ethers grupează listenerii cu același filtru, de aceea cererile cresc mai încet decât numărul de subscripții.
- **Handler-ele vechi rulează și ele:** un singur event apelează handler-ul tuturor Dashboard-urilor vechi. Fiecare recitește soldul din contract (`eth_call`), chiar dacă rezultatul e aruncat, pentru că `active = false` pe un Dashboard care nu mai e pe ecran. Asta înseamnă cereri degeaba.
- **Asta e un memory/request leak:** cu cât schimbi contul de mai multe ori, cu atât pagina face mai multe cereri. Se oprește doar la reload.
- **React StrictMode agravează problema.** În modul dev, StrictMode montează fiecare componentă de 2 ori, ca să prindă exact astfel de greșeli. Fără `off`, chiar de la prima încărcare rămâne o subscripție în plus.

**Unde se văd cererile:** în tab-ul *Network* al paginii **nu** apar. Cu `BrowserProvider`, cererile JSON-RPC sunt trimise prin extensia MetaMask, nu direct de pagină. Le-am văzut în terminalul lui `anvil`, care afișează fiecare metodă RPC primită: `eth_getLogs`, `eth_blockNumber`…

---

## Întrebări pe care mi le-ar putea pune

**Care e diferența dintre o citire și o tranzacție din pagină?**
O citire (`contract.points(account)`) e un `eth_call`: e gratuită, imediată și nu are nevoie de signer. O tranzacție (`contract.connect(signer).addPoints(...)`) e semnată de MetaMask, costă gas, iar rezultatul îl știu abia după ce e minată (`await tx.wait()`).

**Ce e provider, signer, ABI?**
- **Provider:** obiectul care trimite cereri la nod. Aici e MetaMask (`window.ethereum`), învelit de ethers.
- **Signer:** contul care semnează tranzacțiile.
- **ABI:** descrierea JSON a funcțiilor și a event-urilor. Din ABI, ethers generează câte o metodă JavaScript pentru fiecare funcție a contractului.

**Cum „primește” pagina un event?**
Nodul nu trimite nimic singur. Provider-ul face **polling** la 4 secunde și întreabă de logs noi care se potrivesc cu filtrul. De aceea actualizarea apare cu câteva secunde întârziere, iar events dinainte de subscripție nu vin, ci se iau cu `queryFilter` (Ex 2).

**De ce recitesc soldul în loc să adun `amount`?**
Ca un event duplicat sau întârziat să nu dea un total greșit. Contractul e singura sursă de adevăr. Citesc la blocul evenimentului (`{blockTag: blockNumber}`), iar o citire mai veche nu suprascrie una mai nouă (`shownBlock`).

**Ascunderea formularului de admin protejează contractul?**
Nu. E doar pentru comoditate. Oricine poate apela `addPoints` cu `cast send`. Protecția e `onlyAdmin` din contract: am încercat cu cheia clientului și am primit `NotAdmin`.

**De ce filtrez după `client`?**
Pentru că e `indexed`, deci e al doilea topic al log-ului. Nodul îmi trimite doar evenimentele contului meu. Punctele date altei adrese nu generează nicio cerere în pagina mea.
