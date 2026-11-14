import { useEffect, useState } from "react"
import { ArrowUpRight, Star } from "lucide-react"

import { buttonVariants } from "@/components/ui/button"
import { cn } from "@/lib/utils"

function formatStars(n: number) {
  if (n >= 1000) return `${(n / 1000).toFixed(1).replace(/\.0$/, "")}k`
  return String(n)
}

export function GithubButton() {
  const [stars, setStars] = useState<number | null>(null)

  useEffect(() => {
    const ctrl = new AbortController()
    fetch("https://api.github.com/repos/dxxpcode/ix1", { signal: ctrl.signal })
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => {
        if (d && typeof d.stargazers_count === "number") {
          setStars(d.stargazers_count)
        }
      })
      .catch(() => {})
    return () => ctrl.abort()
  }, [])

  return (
    <a
      href="https://github.com/dxxpcode/ix1"
      className={cn(
        buttonVariants({ variant: "outline", size: "lg" }),
        "group rounded-full border-border px-7 transition-all duration-200",
        "hover:-translate-y-px hover:border-zinc-500 dark:hover:border-zinc-500",
        "active:translate-y-0 active:scale-[0.98]"
      )}
    >
      GitHub
      <span
        className={cn(
          "flex items-center gap-1.5 border-l border-border pl-3 text-muted-foreground",
          "transition-colors duration-300 group-hover:text-foreground"
        )}
      >
        <Star
          aria-hidden
          className="h-3.5 w-3.5 fill-amber-400 text-amber-400 transition-transform duration-300 group-hover:scale-110 dark:fill-amber-300 dark:text-amber-300"
        />
        <span className="min-w-[1.5rem] text-center tabular-nums">
          {stars === null ? "—" : formatStars(stars)}
          <span className="sr-only"> stars</span>
        </span>
      </span>
      <ArrowUpRight className="transition-transform duration-200 group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
    </a>
  )
}
