import deployedAddresses from "../contracts/addresses.json";
import FidelityPointsArtifact from "../contracts/FidelityPoints.json";
import {ethers} from 'ethers';

const FIDELITY_POINTS_ADDRESS = deployedAddresses.fidelityPoints;
const FIDELITY_POINTS_ABI = FidelityPointsArtifact.abi;
const EXPECTED_CHAIN_ID = BigInt(deployedAddresses.chainId);
const FROM_BLOCK = deployedAddresses.fromBlock ?? 0;      // Ex 2: blocul in care a fost deployat contractul

// Ex 4: pune false ca sa vezi ce se intampla daca nu mai apelam contract.off
const UNSUBSCRIBE_ON_CLEANUP = true;

const KNOWN_NETWORKS = {
    31337: {
        chainId: '0x7a69',
        chainName: 'Anvil',
        rpcUrls: ['http://127.0.0.1:8545'],
        nativeCurrency: {name: 'Ether', symbol: 'ETH', decimals: 18}
    }
};

const fidelityInterface = new ethers.Interface(FIDELITY_POINTS_ABI);

let browserProvider = null;

const getProvider = () => {
    if (!window.ethereum) {
        throw new Error("MetaMask is not installed. Please install MetaMask to use this application.");
    }
    if (!browserProvider) {
        browserProvider = new ethers.BrowserProvider(window.ethereum);
    }
    return browserProvider;
};

// Without a signer, the contract can only be read (view functions, events).
// With a signer, it can also send transactions.
const getContract = (runner = getProvider()) =>
    new ethers.Contract(FIDELITY_POINTS_ADDRESS, FIDELITY_POINTS_ABI, runner);

// ---------------------------------------------------------------------------
// Wallet and network
// ---------------------------------------------------------------------------

const ensureCorrectNetwork = async () => {
    const currentChainId = BigInt(await window.ethereum.request({method: 'eth_chainId'}));
    if (currentChainId === EXPECTED_CHAIN_ID) {
        return;
    }

    const chainIdHex = ethers.toQuantity(EXPECTED_CHAIN_ID);
    try {
        await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{chainId: chainIdHex}]
        });
    } catch (error) {
        const code = error?.code ?? error?.data?.originalError?.code;
        const network = KNOWN_NETWORKS[Number(EXPECTED_CHAIN_ID)];
        if (code === 4902 && network) {
            await window.ethereum.request({method: 'wallet_addEthereumChain', params: [network]});
        } else if (code === 4001) {
            throw new Error(`Please switch MetaMask to the network with chain ID ${EXPECTED_CHAIN_ID}.`);
        } else {
            throw error;
        }
    }
    browserProvider = null;
};

const assertContractDeployed = async () => {
    const code = await getProvider().getCode(FIDELITY_POINTS_ADDRESS);
    if (code === '0x') {
        throw new Error(
            `No FidelityPoints contract found at ${FIDELITY_POINTS_ADDRESS} on chain ${EXPECTED_CHAIN_ID}. ` +
            `Deploy the contract and reload the page.`
        );
    }
};

const connectWalletMetamask = async () => {
    if (!window.ethereum) {
        throw new Error("MetaMask is not installed. Please install MetaMask to use this application.");
    }
    await window.ethereum.request({method: 'eth_requestAccounts'});
    await ensureCorrectNetwork();
    await assertContractDeployed();
    return getProvider().getSigner();
};

const getSignerFor = (address) => getProvider().getSigner(address);

const setupMetaMaskListeners = (onAccountChanged, onNetworkChanged) => {
    if (!window.ethereum) {
        return () => {};
    }

    const handleAccountsChanged = (accounts) => {
        onAccountChanged(accounts.length === 0 ? null : accounts[0]);
    };

    const handleChainChanged = (chainId) => {
        browserProvider = null;
        onNetworkChanged(chainId);
    };

    window.ethereum.on('accountsChanged', handleAccountsChanged);
    window.ethereum.on('chainChanged', handleChainChanged);

    return () => {
        window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
        window.ethereum.removeListener('chainChanged', handleChainChanged);
    };
};

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------

const ERROR_MESSAGES = {
    NotAdmin: (args) => `Only the admin can do this (caller: ${args[0]}).`,
    // Ex 3: spendPoints cu mai multe puncte decat are clientul -> scaderea face underflow -> Panic(0x11)
    Panic: (args) => Number(args[0]) === 0x11
        ? "You don't have enough points (the subtraction underflowed: Panic 0x11)."
        : `The contract panicked (code 0x${Number(args[0]).toString(16)}).`
};

const PANIC_SELECTOR = '0x4e487b71';

const findRevertData = (error) => {
    const candidates = [
        error?.data,
        error?.info?.error?.data,
        error?.info?.error?.data?.data,
        error?.error?.data,
        error?.error?.data?.data
    ];
    return candidates.find((data) => typeof data === 'string' && data.startsWith('0x') && data.length >= 10);
};

const decodeContractError = (error) => {
    if (error?.revert?.name) {
        return error.revert;
    }
    const data = findRevertData(error);
    if (!data) return null;
    if (data.startsWith(PANIC_SELECTOR)) {
        const [code] = ethers.AbiCoder.defaultAbiCoder().decode(['uint256'], ethers.dataSlice(data, 4));
        return {name: 'Panic', args: [code]};
    }
    try {
        return fidelityInterface.parseError(data);
    } catch {
        return null;
    }
};

const getErrorMessage = (error) => {
    if (error?.code === 'ACTION_REJECTED') {
        return "The request was rejected in MetaMask.";
    }
    if (error?.code === 'INSUFFICIENT_FUNDS') {
        return "Insufficient funds to pay for gas.";
    }
    const decoded = decodeContractError(error);
    if (decoded && ERROR_MESSAGES[decoded.name]) {
        return ERROR_MESSAGES[decoded.name](decoded.args ?? []);
    }
    // ethers wraps MetaMask errors it cannot classify ("could not coalesce error");
    // the real reason is the inner JSON-RPC error.
    const inner = error?.error?.data?.message || error?.error?.message;
    if (error?.shortMessage === 'could not coalesce error' && inner) {
        return `MetaMask: ${inner}`;
    }
    return error?.shortMessage || error?.reason || error?.message || "Unknown error";
};

// ---------------------------------------------------------------------------
// Reads
// ---------------------------------------------------------------------------

const getAdmin = () => getContract().admin();

const getPoints = async (address, blockTag = 'latest') => {
    const points = await getContract().points(address, {blockTag});
    return Number(points);
};

// Ex 1: valoarea punctelor in unitatea preturilor din catalog (points * pointValue)
const getTotalValue = async (address, blockTag = 'latest') => {
    const value = await getContract().getTotalValue(address, {blockTag});
    return Number(value);
};

const getPointValue = async (blockTag = 'latest') => Number(await getContract().pointValue({blockTag}));

// Ex 2: evenimentele PointsAdded din trecut, pentru contul dat (echivalentul lui cast logs)
const getPointsHistory = async (client) => {
    const contract = getContract();
    const events = await contract.queryFilter(contract.filters.PointsAdded(client), FROM_BLOCK);
    return events.map(toHistoryEntry);
};

const toHistoryEntry = (event) => ({
    id: `${event.transactionHash}-${event.index}`,     // unic pentru fiecare log, ca sa nu apara de doua ori
    blockNumber: event.blockNumber,
    amount: Number(event.args.amount),
    txHash: event.transactionHash
});

// Ex 4: cate subscriptii are provider-ul in acest moment
const countSubscriptions = () => getProvider().listenerCount();

// ---------------------------------------------------------------------------
// Transactions
// ---------------------------------------------------------------------------

const addPoints = async (signer, client, amount) => {
    if (!ethers.isAddress(client)) {
        throw new Error("Please enter a valid customer address.");
    }
    const tx = await getContract(signer).addPoints(ethers.getAddress(client), amount);
    return tx.wait();
};

// Ex 3
const spendPoints = async (signer, amount) => {
    const value = parseAmount(amount);
    const tx = await getContract(signer).spendPoints(value);
    return tx.wait();
};

// Ex 1: ca administratorul sa poata schimba valoarea unui punct din pagina
const setPointValue = async (signer, newValue) => {
    const value = parseAmount(newValue);
    const tx = await getContract(signer).setPointValue(value);
    return tx.wait();
};

const parseAmount = (amount) => {
    const text = String(amount).trim();
    if (!/^[0-9]+$/.test(text) || BigInt(text) === 0n) {
        throw new Error("Please enter a positive whole number.");
    }
    return BigInt(text);
};

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/**
 * Calls onChange(blockNumber) whenever the balance of `client` changes, i.e.
 * when the contract emits PointsAdded or PointsSpent for this client.
 * `client` is an indexed parameter, so the filtering is done by the node,
 * on the second topic of the logs. Returns a function that unsubscribes.
 */
const subscribeToPointsChanges = (client, onChange) => {
    const contract = getContract();
    const addedFilter = contract.filters.PointsAdded(client);
    const spentFilter = contract.filters.PointsSpent(client);

    // The last argument of an ethers listener is the event payload,
    // which contains the log (block number, transaction hash, ...).
    // Ex 2: pentru PointsAdded trimit si detaliile log-ului, ca pagina sa le adauge in istoric
    const handleAdded = (...args) => {
        const payload = args[args.length - 1];
        onChange(payload.log.blockNumber, toHistoryEntry(payload.log));
    };
    const handleSpent = (...args) => {
        const payload = args[args.length - 1];
        onChange(payload.log.blockNumber, null);
    };

    contract.on(addedFilter, handleAdded);
    contract.on(spentFilter, handleSpent);
    return () => {
        if (!UNSUBSCRIBE_ON_CLEANUP) return;            // Ex 4
        contract.off(addedFilter, handleAdded);
        contract.off(spentFilter, handleSpent);
    };
};

/**
 * Ex 1: calls onChange(blockNumber) when the administrator changes the value of a point.
 * PointValueChanged has no indexed parameter, so the filter has only the first topic
 * (the hash of the signature): every change is received, by every client.
 */
const subscribeToPointValueChanges = (onChange) => {
    const contract = getContract();
    const filter = contract.filters.PointValueChanged();
    const handle = (...args) => onChange(args[args.length - 1].log.blockNumber);
    contract.on(filter, handle);
    return () => {
        if (!UNSUBSCRIBE_ON_CLEANUP) return;            // Ex 4
        contract.off(filter, handle);
    };
};

export {
    FIDELITY_POINTS_ADDRESS,
    getProvider,
    connectWalletMetamask,
    getSignerFor,
    setupMetaMaskListeners,
    getErrorMessage,
    getAdmin,
    getPoints,
    getTotalValue,
    getPointValue,
    getPointsHistory,
    countSubscriptions,
    addPoints,
    spendPoints,
    setPointValue,
    subscribeToPointsChanges,
    subscribeToPointValueChanges
};
