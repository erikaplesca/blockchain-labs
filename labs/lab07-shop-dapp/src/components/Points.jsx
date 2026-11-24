import {useEffect, useRef, useState} from 'react';
import {useWallet} from '../utils/WalletContext.js';
import {
    connectWalletMetamask,
    getSignerFor,
    setupMetaMaskListeners,
    getErrorMessage,
    getProvider,
    getAdmin,
    getPoints,
    getTotalValue,
    getPointValue,
    getPointsHistory,
    countSubscriptions,
    subscribeToPointsChanges,
    subscribeToPointValueChanges,
    FIDELITY_POINTS_ADDRESS
} from '../utils/EthersUtils.js';
import {AdminPanel} from './AdminPanel.jsx';
import {SpendPanel} from './SpendPanel.jsx';
import {History} from './History.jsx';
import '../styles/Points.css';
import '../styles/Common.css';

const formatAddress = (address) => `${address.substring(0, 6)}...${address.substring(address.length - 4)}`;

/** Single page of the application: connect button, or the points of the connected account. */
export const Points = () => {
    const {wallet, initializeWallet} = useWallet();
    const [connecting, setConnecting] = useState(false);
    const [error, setError] = useState(null);

    // When the user selects another account in MetaMask, switch to it;
    // when the network changes, ask the user to connect again.
    useEffect(() => {
        const handleAccountChanged = (account) => {
            if (!account) {
                initializeWallet(null);
                return;
            }
            getSignerFor(account).then(initializeWallet).catch(() => initializeWallet(null));
        };
        return setupMetaMaskListeners(handleAccountChanged, () => initializeWallet(null));
    }, [initializeWallet]);

    const handleConnect = async () => {
        setError(null);
        setConnecting(true);
        try {
            initializeWallet(await connectWalletMetamask());
        } catch (err) {
            console.error("Failed to connect wallet:", err);
            setError(getErrorMessage(err));
        } finally {
            setConnecting(false);
        }
    };

    if (!wallet) {
        return (
            <div className="points-container">
                <div className="points-card">
                    <h1>Fidelity Points</h1>
                    <p className="points-subtitle">Connect your wallet to see your fidelity points</p>
                    <button className="primary-button" onClick={handleConnect} disabled={connecting}>
                        {connecting ? 'Connecting...' : 'Connect With MetaMask'}
                    </button>
                    {error && <div className="error-box">{error}</div>}
                </div>
            </div>
        );
    }

    // The key recreates the dashboard, with fresh state, when the account changes.
    return <Dashboard key={wallet.address} signer={wallet}/>;
};

const Dashboard = ({signer}) => {
    const account = signer.address;
    const [points, setPoints] = useState(null);
    const [totalValue, setTotalValue] = useState(null);       // Ex 1
    const [pointValue, setPointValue] = useState(null);       // Ex 1
    const [history, setHistory] = useState([]);               // Ex 2
    const [subscriptions, setSubscriptions] = useState(null); // Ex 4
    const [isAdmin, setIsAdmin] = useState(false);
    const [error, setError] = useState(null);
    const [lastUpdate, setLastUpdate] = useState(null);

    // Block number of the value currently displayed. A read made at an older
    // block (for example, a slow initial read) must not overwrite a newer value.
    const shownBlock = useRef(-1);

    useEffect(() => {
        let active = true;

        // Citesc din nou starea contractului la blocul evenimentului:
        // contractul ramane singura sursa de adevar (nu adun amount la ce e pe ecran).
        const refresh = async (blockNumber) => {
            try {
                const [value, total, perPoint] = await Promise.all([
                    getPoints(account, blockNumber),
                    getTotalValue(account, blockNumber),
                    getPointValue(blockNumber)
                ]);
                if (active && blockNumber >= shownBlock.current) {
                    shownBlock.current = blockNumber;
                    setPoints(value);
                    setTotalValue(total);
                    setPointValue(perPoint);
                    setLastUpdate(blockNumber);
                }
            } catch (err) {
                if (active) setError(getErrorMessage(err));
            }
        };

        // Ex 2: adaug in istoric fara duplicate (acelasi log poate veni si din queryFilter si din subscriptie)
        const addToHistory = (entries) => {
            setHistory((old) => {
                const seen = new Set(old.map((e) => e.id));
                const fresh = entries.filter((e) => !seen.has(e.id));
                return [...old, ...fresh].sort((a, b) => b.blockNumber - a.blockNumber);
            });
        };

        // Initial read of the balance, of the admin address and of the past events.
        (async () => {
            try {
                const [blockNumber, admin, past] = await Promise.all([
                    getProvider().getBlockNumber(),
                    getAdmin(),
                    getPointsHistory(account)
                ]);
                if (!active) return;
                setIsAdmin(admin.toLowerCase() === account.toLowerCase());
                addToHistory(past);
                await refresh(blockNumber);
            } catch (err) {
                if (active) setError(getErrorMessage(err));
            }
        })();

        // Live updates: every PointsAdded / PointsSpent event of this account
        // triggers a new read of the balance at the block of the event.
        const unsubscribePoints = subscribeToPointsChanges(account, (blockNumber, entry) => {
            if (entry && active) addToHistory([entry]);
            refresh(blockNumber);
        });
        // Ex 1: the value changes also when the administrator changes pointValue
        const unsubscribeValue = subscribeToPointValueChanges(refresh);

        return () => {
            active = false;
            unsubscribePoints();
            unsubscribeValue();
        };
    }, [account]);

    // Ex 4: afisez numarul de subscriptii active ale provider-ului
    useEffect(() => {
        const update = () => countSubscriptions().then(setSubscriptions).catch(() => {});
        update();
        const timer = setInterval(update, 2000);
        return () => clearInterval(timer);
    }, []);

    return (
        <div className="points-container">
            <div className="points-card">
                <h1>Fidelity Points</h1>
                <p className="points-account">
                    Connected as <code title={account}>{formatAddress(account)}</code>
                    {isAdmin && <span className="admin-badge">Admin</span>}
                </p>

                <div className="points-balance">
                    <span className="points-value">{points === null ? '…' : points}</span>
                    <span className="points-label">points</span>
                </div>
                <p className="points-total-value">
                    Value: <strong>{totalValue === null ? '…' : totalValue}</strong>
                    {pointValue !== null && <> ({points} × {pointValue} per point)</>}
                </p>
                <p className="points-note">
                    Updated automatically when points are added or spent, or when the point value changes
                    {lastUpdate !== null && <> · block {lastUpdate}</>}
                </p>

                {error && <div className="error-box">{error}</div>}

                <SpendPanel signer={signer}/>

                {isAdmin && <AdminPanel signer={signer}/>}

                <History entries={history}/>

                <p className="points-contract">
                    Contract <code>{FIDELITY_POINTS_ADDRESS}</code>
                    {subscriptions !== null && <> · active subscriptions: <strong>{subscriptions}</strong></>}
                </p>
            </div>
        </div>
    );
};
