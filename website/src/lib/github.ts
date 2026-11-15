export interface RepoStats {
  stars: number
  forks: number
  issues: number
}

const REPO = "https://api.github.com/repos/dxxpcode/ix1"

// open_issues_count counts pull requests too — subtract the real PR
// total. per_page=1 keeps the payload tiny; the Link header's last
// page carries the count when it paginates.
async function fetchOpenPulls(): Promise<number | null> {
  try {
    const r = await fetch(`${REPO}/pulls?state=open&per_page=1`)
    if (!r.ok) return null
    const last = r.headers
      .get("Link")
      ?.match(/[?&]page=(\d+)>;\s*rel="last"/)
    if (last) return parseInt(last[1], 10)
    const arr = await r.json()
    return Array.isArray(arr) ? arr.length : null
  } catch {
    return null
  }
}

// One flight for every consumer — the hero button and the
// open-source section share the same repo payload.
let cached: Promise<RepoStats | null> | null = null

export function fetchRepoStats(): Promise<RepoStats | null> {
  if (!cached) {
    cached = Promise.all([
      fetch(REPO).then((r) => (r.ok ? r.json() : null)),
      fetchOpenPulls(),
    ])
      .then(([d, pulls]) =>
        d && typeof d.stargazers_count === "number"
          ? {
              stars: d.stargazers_count,
              forks: typeof d.forks_count === "number" ? d.forks_count : 0,
              issues:
                typeof d.open_issues_count === "number"
                  ? Math.max(0, d.open_issues_count - (pulls ?? 0))
                  : 0,
            }
          : null
      )
      .catch(() => null)
  }
  return cached
}
