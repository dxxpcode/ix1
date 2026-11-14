import { ArrowLeft, ArrowUpRight } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { buttonVariants } from "@/components/ui/button"
import { cn } from "@/lib/utils"

const RELEASES = [
  {
    version: "0.8.0",
    date: "2026-11-14",
    tag: "v0.8.0",
    notes: [
      "First public MVP release.",
      "Self-contained installer ISO — no internet needed during install.",
      "Atomic signed updates with instant rollback; updates managed in Settings → Updates.",
      "ix1 shell: dock, launcher, quick settings, lock screen, notifications.",
      "Essential apps included: browser, files, editor, terminal, system monitor, software center (Flatpak).",
    ],
    known: [
      "Secure Boot must be off.",
      "Online updates require the public image registry (ghcr.io/dxxpcode/ix1-os) — publishes with the release pipeline; the ISO itself installs and runs fully offline.",
    ],
  },
]

export default function Releases() {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <nav className="fixed inset-x-0 top-0 z-20 border-b border-border bg-background/80 backdrop-blur-md">
        <div className="mx-auto flex h-14 max-w-5xl items-center justify-between px-6">
          <a
            href="./index.html"
            className="flex items-center gap-2 font-bold tracking-tight"
          >
            <svg
              width="15"
              height="15"
              viewBox="0 0 15 15"
              fill="currentColor"
              aria-hidden
            >
              <path d="M7.5 1.5 14 13.5H1Z" />
            </svg>
            ix1
          </a>
          <a
            href="./index.html"
            className={cn(
              buttonVariants({ variant: "outline", size: "sm" }),
              "rounded-full"
            )}
          >
            <ArrowLeft />
            Back
          </a>
        </div>
      </nav>

      <main className="mx-auto max-w-3xl px-6 pb-28 pt-32">
        <h1 className="mb-14 text-4xl font-bold tracking-tight">Releases.</h1>
        {RELEASES.map((r) => (
          <article key={r.tag} className="border-t border-border py-10">
            <div className="mb-6 flex items-baseline justify-between">
              <div className="flex items-center gap-3">
                <h2 className="text-2xl font-semibold tracking-tight">
                  ix1 {r.version}
                </h2>
                <Badge variant="secondary">latest</Badge>
              </div>
              <span className="text-sm text-zinc-600">{r.date}</span>
            </div>
            <ul className="mb-6 list-disc space-y-2 pl-5 text-[15px] text-muted-foreground">
              {r.notes.map((n) => (
                <li key={n}>{n}</li>
              ))}
            </ul>
            <p className="mb-2 text-xs font-medium uppercase tracking-wider text-zinc-600">
              Known limitations
            </p>
            <ul className="list-disc space-y-2 pl-5 text-sm text-zinc-500">
              {r.known.map((k) => (
                <li key={k}>{k}</li>
              ))}
            </ul>
            <div className="mt-6 flex gap-6 text-sm">
              <a
                className="flex items-center gap-1 text-muted-foreground underline decoration-border underline-offset-4 transition-colors hover:text-foreground"
                href={`https://github.com/dxxpcode/ix1/releases/tag/${r.tag}`}
              >
                Download on GitHub
                <ArrowUpRight className="h-3.5 w-3.5" />
              </a>
            </div>
          </article>
        ))}
      </main>

      <footer className="border-t border-border">
        <div className="mx-auto flex max-w-5xl flex-col items-center gap-4 px-6 py-8 text-sm text-muted-foreground sm:flex-row sm:justify-between">
          <span className="flex items-center gap-2 font-bold tracking-tight text-foreground">
            <svg
              width="12"
              height="12"
              viewBox="0 0 15 15"
              fill="currentColor"
              aria-hidden
            >
              <path d="M7.5 1.5 14 13.5H1Z" />
            </svg>
            ix1
          </span>
          <div className="flex gap-6">
            <a
              className="transition-colors hover:text-foreground"
              href="https://github.com/dxxpcode/ix1"
            >
              GitHub
            </a>
            <a
              className="transition-colors hover:text-foreground"
              href="https://github.com/dxxpcode/ix1/issues"
            >
              Report an issue
            </a>
            <a
              className="transition-colors hover:text-foreground"
              href="https://github.com/dxxpcode/ix1/blob/main/LICENSE"
            >
              MIT License
            </a>
          </div>
          <span className="text-[13px] text-zinc-600">
            © 2026 ix1 contributors
          </span>
        </div>
      </footer>
    </div>
  )
}
