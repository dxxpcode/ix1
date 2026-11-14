import { useState } from "react"
import { Moon, Sun } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import { currentTheme, toggleTheme, type Theme } from "@/theme"

export function ThemeToggle() {
  const [theme, setTheme] = useState<Theme>(() => currentTheme())

  return (
    <Button
      variant="ghost"
      size="icon"
      className="rounded-full transition-transform duration-200 hover:text-foreground active:scale-90"
      aria-label={theme === "dark" ? "Switch to light mode" : "Switch to dark mode"}
      onClick={() => setTheme(toggleTheme())}
    >
      <span className="relative block h-4 w-4">
        <Sun
          className={cn(
            "absolute inset-0 h-4 w-4 transition-all duration-300 ease-out",
            theme === "dark"
              ? "rotate-0 scale-100 opacity-100"
              : "rotate-90 scale-50 opacity-0"
          )}
        />
        <Moon
          className={cn(
            "absolute inset-0 h-4 w-4 transition-all duration-300 ease-out",
            theme === "dark"
              ? "-rotate-90 scale-50 opacity-0"
              : "rotate-0 scale-100 opacity-100"
          )}
        />
      </span>
    </Button>
  )
}
