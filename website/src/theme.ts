export type Theme = "light" | "dark"

const KEY = "ix1-theme"

export function applyTheme(theme: Theme) {
  document.documentElement.classList.toggle("dark", theme === "dark")
  localStorage.setItem(KEY, theme)
}

export function currentTheme(): Theme {
  return document.documentElement.classList.contains("dark")
    ? "dark"
    : "light"
}

export function toggleTheme(): Theme {
  const next: Theme = currentTheme() === "dark" ? "light" : "dark"
  applyTheme(next)
  return next
}
