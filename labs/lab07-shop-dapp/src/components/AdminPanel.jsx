import {useState} from 'react';
import {addPoints, setPointValue, getErrorMessage} from '../utils/EthersUtils.js';

const POINTS_PER_CLICK = 100;

/** Shown only to the admin. The contract checks the role again (onlyAdmin). */
export const AdminPanel = ({signer}) => {
    const [customer, setCustomer] = useState('');
    const [sending, setSending] = useState(false);
    const [message, setMessage] = useState(null);
    const [error, setError] = useState(null);

    const handleSubmit = async (event) => {
        event.preventDefault();
        setMessage(null);
        setError(null);
        setSending(true);
        try {
            const receipt = await addPoints(signer, customer.trim(), POINTS_PER_CLICK);
            setMessage(`${POINTS_PER_CLICK} points added to ${customer.trim()} (block ${receipt.blockNumber}).`);
            setCustomer('');
        } catch (err) {
            console.error("addPoints failed:", err);
            setError(getErrorMessage(err));
        } finally {
            setSending(false);
        }
    };

    return (
        <>
        <form className="admin-panel" onSubmit={handleSubmit}>
            <h2>Grant points</h2>
            <label htmlFor="customer">Customer address</label>
            <input
                id="customer"
                type="text"
                placeholder="0x..."
                value={customer}
                onChange={(e) => setCustomer(e.target.value)}
                spellCheck={false}
                autoComplete="off"
            />
            <button type="submit" className="primary-button" disabled={sending || !customer.trim()}>
                {sending ? 'Sending...' : `Add ${POINTS_PER_CLICK} points`}
            </button>
            {message && <div className="success-box">{message}</div>}
            {error && <div className="error-box">{error}</div>}
        </form>
        <PointValueForm signer={signer}/>
        </>
    );
};

/** Ex 1: the administrator changes the value of a point; every page receives PointValueChanged. */
const PointValueForm = ({signer}) => {
    const [value, setValue] = useState('');
    const [sending, setSending] = useState(false);
    const [message, setMessage] = useState(null);
    const [error, setError] = useState(null);

    const handleSubmit = async (event) => {
        event.preventDefault();
        setMessage(null);
        setError(null);
        setSending(true);
        try {
            const receipt = await setPointValue(signer, value);
            setMessage(`Point value set to ${value.trim()} (block ${receipt.blockNumber}).`);
            setValue('');
        } catch (err) {
            console.error("setPointValue failed:", err);
            setError(getErrorMessage(err));
        } finally {
            setSending(false);
        }
    };

    return (
        <form className="admin-panel" onSubmit={handleSubmit}>
            <h2>Point value</h2>
            <label htmlFor="point-value">New value of one point</label>
            <input
                id="point-value"
                type="text"
                inputMode="numeric"
                placeholder="e.g. 20"
                value={value}
                onChange={(e) => setValue(e.target.value)}
                autoComplete="off"
            />
            <button type="submit" className="primary-button" disabled={sending || !value.trim()}>
                {sending ? 'Sending...' : 'Set point value'}
            </button>
            {message && <div className="success-box">{message}</div>}
            {error && <div className="error-box">{error}</div>}
        </form>
    );
};
