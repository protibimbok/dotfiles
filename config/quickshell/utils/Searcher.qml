pragma Singleton
import "scripts/fzf.js" as Fzf
import Quickshell
import QtQuick

Singleton {
    function query(list: var, search: string, opts: var): var {
        const key = opts?.key ?? "name";
        const keys = opts?.keys ?? [key];
        const weights = opts?.weights ?? [1];
        const useFuzzy = opts?.useFuzzy ?? false;
        const extraOpts = opts?.extraOpts ?? {};
        const transformSearch = opts?.transformSearch ?? (s => s);
        const selector = opts?.selector ?? (item => item[key]);

        search = transformSearch(search);
        if (!search || search.length === 0)
            return [...list];

        if (useFuzzy) {
            const q = search.toLowerCase();
            const results = [];
            for (let i = 0; i < list.length; i++) {
                const item = list[i];
                let score = 0;
                for (let k = 0; k < keys.length; k++) {
                    const hay = (item[keys[k]] ?? "").toString().toLowerCase();
                    if (hay.includes(q))
                        score += weights[k];
                }
                if (score > 0)
                    results.push({ score, item });
            }
            results.sort((a, b) => b.score - a.score);
            return results.map(r => r.item);
        }

        try {
            const fzf = new Fzf.Finder(list, Object.assign({ selector }, extraOpts));
            return fzf.find(search).sort((a, b) => {
                if (a.score === b.score)
                    return selector(a.item).trim().length - selector(b.item).trim().length;
                return b.score - a.score;
            }).map(r => r.item);
        } catch (e) {
            const q = search.toLowerCase();
            return list.filter(item => selector(item).toLowerCase().includes(q));
        }
    }
}
