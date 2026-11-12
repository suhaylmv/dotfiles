.pragma library
// Tiny fuzzy matcher for the launcher. score() returns 0 for no match, else
// higher is better: whole-text prefix > word start > substring > the query's
// letters in order (better when they sit on word starts and close together).

function isWordStart(t, i) {
    return i === 0 || " -_./".includes(t[i - 1])
}

function score(query, text) {
    if (!query || !text) return 0
    const q = query.toLowerCase(), t = text.toLowerCase()

    // shorter names win among prefix matches ("Zed" before "Zed Preview")
    if (t.startsWith(q)) return 100 - Math.min(t.length - q.length, 20) / 2
    const at = t.indexOf(q)
    if (at > 0) return isWordStart(t, at) ? 80 : 60

    // letters in order: "lcalc" finds "LibreOffice Calc"
    let from = 0, points = 0
    for (const c of q) {
        const j = t.indexOf(c, from)
        if (j < 0) return 0
        points += isWordStart(t, j) ? 3 : (j === from ? 2 : 1)
        from = j + 1
    }
    return Math.min(50, 10 + 10 * points / q.length)
}
