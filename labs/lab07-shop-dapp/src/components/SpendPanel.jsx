import {useState} from 'react';
import {spendPoints, getErrorMessage} from '../utils/EthersUtils.js';

/** Ex 3: the connected account spends some of its own points (spendPoints uses msg.sender). */
export const SpendPanel = ({signer}) => {
    const [amount, setAmount] = useState('');
    const [sending, setSending] = useState(false);
    const [message, setMessage] = useState(null);
    const [error, setError] = useState(null);

    const handleSubmit = async (event) => {
        event.preventDefault();
        setMessage(null);
        setError(null);
        setSending(true);
        try {
            const receipt = await spendPoints(signer, amount);
            // nu actualizez soldul aici: il actualizeaza evenimentul PointsSpent
            setMessage(`${amount.trim()} points spent (block ${receipt.blockNumber}).`);
            setAmount('');
        } catch (err) {
            console.error("spendPoints failed:", err);
            setError(getErrorMessage(err));
        } finally {
            setSending(false);
        }
    };

    return (
        <form className="admin-panel" onSubmit={handleSubmit}>
            <h2>Spend points</h2>
            <label htmlFor="spend-amount">Number of points</label>
            <input
                id="spend-amount"
                type="text"
                inputMode="numeric"
                placeholder="e.g. 30"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                autoComplete="off"
            />
            <button type="submit" className="primary-button" disabled={sending || !amount.trim()}>
                {sending ? 'Sending...' : 'Spend points'}
            </button>
            {message && <div className="success-box">{message}</div>}
            {error && <div className="error-box">{error}</div>}
        </form>
    );
};
