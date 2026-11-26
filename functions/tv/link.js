const MAX_CANDIDATES = 5;
const MAX_LINKED = 3;

const normalize = name => (name ?? '').toLowerCase().replace(/[^a-z0-9]/g, '');

function linkCandidates(details, mapped, results) {
  const base = normalize(details.name);
  const mappedIds = new Set(mapped.map(s => s.show.id));
  const after = mapped
    .map(s => s.show.premiered ?? '')
    .sort()
    .at(0);
  return results
    .map(r => r.show)
    .filter(
      show =>
        !mappedIds.has(show.id) &&
        normalize(show.name).startsWith(base) &&
        (show.premiered ?? '') > after,
    )
    .slice(0, MAX_CANDIDATES);
}

function subsets(items, maxSize) {
  const result = [];
  const walk = (start, picked) => {
    if (picked.length) result.push(picked);
    if (picked.length === maxSize) return;
    for (let i = start; i < items.length; i++) {
      walk(i + 1, [...picked, items[i]]);
    }
  };
  walk(0, []);
  return result.sort((a, b) => a.length - b.length);
}

function pickLinkedShows(missing, candidates) {
  const match = subsets(candidates, MAX_LINKED).find(
    set => set.reduce((sum, c) => sum + c.released, 0) === missing,
  );
  return match ? match.map(c => c.id) : null;
}

module.exports = { linkCandidates, pickLinkedShows };
