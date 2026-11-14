import { useState } from "react"
import { Moon, Sun } from "lucide-react"

import { Button } from "@/components/ui/button"
import { currentTheme, toggleTheme, type Theme } from "@/theme"

export function ThemeToggle() {
  const [theme, setTheme] = useState<Theme>(() => currentTheme())
  const Icon = theme === "dark" ? Sun : Moon

  return (
    <Button
      variant="ghost"
      size="icon"
      className="rounded-full"
      aria-label={theme === "dark" ? "Switch to light mode" : "Switch to dark mode"}
      onClick={() => setTheme(toggleTheme())}
    >
      <Icon />
    </Button>
  )
}
