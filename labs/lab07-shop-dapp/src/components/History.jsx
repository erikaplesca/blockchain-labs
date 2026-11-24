/** Ex 2: the PointsAdded events of the connected account, newest first. */
export const History = ({entries}) => (
    <div className="admin-panel history">
        <h2>Points received</h2>
        {entries.length === 0
            ? <p className="points-note">No points received yet.</p>
            : (
                <ul className="history-list">
                    {entries.map((e) => (
                        <li key={e.id}>
                            <span>+{e.amount} points</span>
                            <span className="history-meta">
                                block {e.blockNumber} · <code title={e.txHash}>{e.txHash.substring(0, 10)}…</code>
                            </span>
                        </li>
                    ))}
                </ul>
            )}
    </div>
);
