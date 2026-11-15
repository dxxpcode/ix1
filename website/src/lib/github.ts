export interface RepoStats {
  stars: number
  forks: number
  issues: number
}

// One flight for every consumer — the hero button and the
// open-source section share the same repo payload.
let cached: Promise<RepoStats | null> | null = null

export function fetchRepoStats(): Promise<RepoStats | null> {
  if (!cached) {
    cached = fetch("https://api.github.com/repos/dxxpcode/ix1")
      .then((r) => (r.ok ? r.json() : null))
      .then((d) =>
        d && typeof d.stargazers_count === "number"
          ? {
              stars: d.stargazers_count,
              forks: typeof d.forks_count === "number" ? d.forks_count : 0,
              issues:
                typeof d.open_issues_count === "number"
                  ? d.open_issues_count
                  : 0,
            }
          : null
      )
      .catch(() => null)
  }
  return cached
}
