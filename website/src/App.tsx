import {
  ArrowDown,
  FileArchive,
  Layers,
  LayoutGrid,
  ShieldCheck,
} from "lucide-react"

import logoUrl from "../assets/logo.png"
import { CopyButton } from "@/components/copy-button"
import { GithubButton } from "@/components/github-button"
import { ThemeToggle } from "@/components/theme-toggle"
import { buttonVariants } from "@/components/ui/button"
import { cn } from "@/lib/utils"

const RELEASE = "0.8.0"
const ISO = `ix1-${RELEASE}-x86_64.iso`
const PARTS = [0, 1, 2].map((i) => `${ISO}.part0${i}`)
const BASE = `https://github.com/dxxpcode/ix1/releases/download/v${RELEASE}`

const FEATURES = [
  {
    icon: Layers,
    title: "Atomic updates, instant rollback",
    body: "The whole OS updates as a single signed image. It downloads in the background and you reboot into it. Something wrong? The previous image is still installed — roll back and keep working.",
  },
  {
    icon: ShieldCheck,
    title: "Signed & verified",
    body: "Every image is cryptographically signed. The system refuses anything that doesn't verify before it ever boots.",
  },
  {
    icon: LayoutGrid,
    title: "The apps you need",
    body: "Browser, files, editor, terminal, and a software center backed by the Flatpak catalog. Nothing more, nothing missing.",
  },
]

const STEPS = [
  {
    n: "1",
    t: "Download",
    b: "the ISO parts, join them with cat, and verify the checksum above.",
  },
  {
    n: "2",
    t: "Write it to a USB stick",
    b: "dd if=ix1-0.8.0-x86_64.iso of=/dev/sdX bs=4M status=progress — or Fedora Media Writer / balenaEtcher.",
  },
  {
    n: "3",
    t: "Boot the stick",
    b: "over UEFI. The installer asks for a disk, a username, and a password — nothing else.",
  },
  {
    n: "4",
    t: "Reboot into ix1",
    b: "Updates arrive as signed images; check for them in Settings → Updates.",
  },
]

export default function App() {
  return (
    <div className="min-h-screen bg-background text-foreground">
      {/* nav */}
      <nav className="fixed inset-x-0 top-0 z-20 border-b border-border bg-background/80 backdrop-blur-md">
        <div className="mx-auto flex h-14 max-w-5xl items-center justify-between px-6">
          <a href="#top" aria-label="ix1">
            <img
              src={logoUrl}
              alt="ix1"
              className="h-5 w-auto dark:invert"
            />
          </a>
          <div className="hidden items-center gap-7 text-sm text-muted-foreground sm:flex">
            <a className="transition-colors hover:text-foreground" href="#download">
              Download
            </a>
            <a className="transition-colors hover:text-foreground" href="#install">
              Install
            </a>
            <a className="transition-colors hover:text-foreground" href="releases.html">
              Releases
            </a>
            <a
              className="transition-colors hover:text-foreground"
              href="https://github.com/dxxpcode/ix1"
            >
              GitHub
            </a>
          </div>
          <div className="flex items-center gap-1">
            <ThemeToggle />
            <a
              href="#download"
              className={cn(
                buttonVariants({ size: "sm" }),
                "rounded-full transition-transform duration-200 active:scale-[0.97]"
              )}
            >
              Download
            </a>
          </div>
        </div>
      </nav>

      {/* hero */}
      <header
        id="top"
        className="relative overflow-hidden px-6 pb-32 pt-44 text-center"
      >
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{
            background:
              "radial-gradient(ellipse 52% 44% at 50% 30%, var(--glow), transparent 72%)",
          }}
        />
        <div className="relative">
          <p className="ix1-enter mb-6 text-sm font-medium tracking-[0.02em] text-muted-foreground">
            ix1 — a minimal atomic Linux desktop
          </p>
          <h1 className="ix1-enter ix1-enter-1 mx-auto max-w-3xl bg-gradient-to-b from-zinc-950 via-zinc-950 to-zinc-400 bg-clip-text text-[64px] font-bold leading-[1.02] tracking-[-0.04em] text-transparent sm:text-[88px] dark:from-white dark:via-white dark:to-zinc-500">
            A desktop that just works.
          </h1>
          <p className="ix1-enter ix1-enter-2 mx-auto mt-6 max-w-xl text-lg leading-relaxed text-muted-foreground">
            Every update is one signed image. It installs in the background and
            rolls back instantly.
          </p>
          <div className="ix1-enter ix1-enter-3 mt-10 flex justify-center gap-3">
            <a
              href="#download"
              className={cn(
                buttonVariants({ size: "lg" }),
                "group rounded-full px-7 transition-all duration-200",
                "hover:-translate-y-px hover:shadow-[0_6px_20px_-6px_rgba(0,0,0,0.35)]",
                "dark:hover:shadow-[0_6px_24px_-6px_rgba(255,255,255,0.18)]",
                "active:translate-y-0 active:scale-[0.98] active:shadow-none"
              )}
            >
              <ArrowDown className="transition-transform duration-200 group-hover:translate-y-0.5" />
              Download ix1 {RELEASE}
            </a>
            <GithubButton />
          </div>
        </div>
      </header>

      {/* features — shared-border grid */}
      <main className="mx-auto max-w-5xl px-6">
        <section className="grid grid-cols-1 border border-border sm:grid-cols-3">
          {FEATURES.map((f, i) => (
            <div
              key={f.title}
              className={cn(
                "p-8 transition-colors duration-200 hover:bg-accent/40",
                i > 0 && "border-t border-border sm:border-l sm:border-t-0"
              )}
            >
              <f.icon className="mb-6 h-5 w-5 text-foreground" strokeWidth={1.75} />
              <h3 className="mb-3 font-semibold tracking-tight">{f.title}</h3>
              <p className="text-sm leading-relaxed text-muted-foreground">
                {f.body}
              </p>
            </div>
          ))}
        </section>

        {/* download */}
        <section id="download" className="scroll-mt-20 py-28">
          <h2 className="mb-3 text-3xl font-bold tracking-tight">Download.</h2>
          <p className="mb-10 text-muted-foreground">
            ix1 {RELEASE} — installable ISO for x86_64. Self-contained; no
            internet needed during install.
          </p>
          <div className="border border-border">
            <div className="flex flex-col gap-4 border-b border-border p-6 sm:flex-row sm:items-center sm:justify-between">
              <code className="text-sm">{ISO}</code>
              <span className="text-[13px] text-zinc-600">
                4.3 GB — ships in {PARTS.length} parts
              </span>
            </div>
            <div className="space-y-4 p-6">
              <div>
                <p className="mb-2 text-xs font-medium uppercase tracking-wider text-zinc-600">
                  Download
                </p>
                <div className="flex flex-col gap-1.5">
                  {PARTS.map((p) => (
                    <a
                      key={p}
                      href={`${BASE}/${p}`}
                      className="group flex items-center justify-between gap-4 border border-border px-3.5 py-2.5 transition-colors hover:border-zinc-400 hover:bg-accent/40 dark:hover:border-zinc-600"
                    >
                      <span className="flex min-w-0 items-center gap-2.5">
                        <FileArchive className="h-4 w-4 shrink-0 text-muted-foreground" strokeWidth={1.75} />
                        <code className="truncate text-[13px]">{p}</code>
                      </span>
                      <ArrowDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground transition-transform group-hover:translate-y-0.5" />
                    </a>
                  ))}
                </div>
              </div>
              <div>
                <p className="mb-2 text-xs font-medium uppercase tracking-wider text-zinc-600">
                  Assemble
                </p>
                <div className="flex items-center justify-between gap-4 border border-border bg-card px-3.5 py-2.5">
                  <code className="truncate text-[13px] text-muted-foreground">
                    cat {ISO}.part* &gt; {ISO}
                  </code>
                  <CopyButton text={`cat ${ISO}.part* > ${ISO}`} />
                </div>
              </div>
              <div>
                <p className="mb-2 text-xs font-medium uppercase tracking-wider text-zinc-600">
                  Checksum
                </p>
                <div className="flex items-center justify-between gap-4 border border-border bg-card px-3.5 py-2.5">
                  <code className="truncate text-[13px] text-muted-foreground">
                    sha256sum -c {ISO}.sha256
                  </code>
                  <CopyButton text={`sha256sum -c ${ISO}.sha256`} />
                </div>
              </div>
              <div>
                <p className="mb-2 text-xs font-medium uppercase tracking-wider text-zinc-600">
                  Signature
                </p>
                <div className="flex items-center justify-between gap-4 border border-border bg-card px-3.5 py-2.5">
                  <code className="truncate text-[13px] text-muted-foreground">
                    cosign verify-blob --key ix1.pub --signature {ISO}.sig {ISO}
                  </code>
                  <CopyButton
                    text={`cosign verify-blob --key ix1.pub --signature ${ISO}.sig ${ISO}`}
                  />
                </div>
              </div>
              <div className="flex gap-6 pt-1 text-sm">
                {/* artifact links */}
                <a
                  className="text-muted-foreground underline decoration-border underline-offset-4 transition-colors hover:text-foreground"
                  href={`${BASE}/${ISO}.sha256`}
                >
                  checksum
                </a>
                <a
                  className="text-muted-foreground underline decoration-border underline-offset-4 transition-colors hover:text-foreground"
                  href={`${BASE}/${ISO}.sig`}
                >
                  signature
                </a>
                <a
                  className="text-muted-foreground underline decoration-border underline-offset-4 transition-colors hover:text-foreground"
                  href={`${BASE}/ix1.pub`}
                >
                  public key
                </a>
              </div>
            </div>
          </div>
        </section>

        {/* install */}
        <section id="install" className="scroll-mt-20 pb-28">
          <h2 className="mb-10 text-3xl font-bold tracking-tight">
            Install in four steps.
          </h2>
          <ol>
            {STEPS.map((s) => (
              <li
                key={s.n}
                className="flex items-baseline gap-6 border-t border-border py-5 last:border-b"
              >
                <span className="w-5 shrink-0 text-sm text-zinc-600">{s.n}</span>
                <div className="min-w-0">
                  <p className="text-[15px] text-muted-foreground">
                    <strong className="font-semibold text-foreground">
                      {s.t}
                    </strong>{" "}
                    {s.b.startsWith("dd if=") ? (
                      <>— or Fedora Media Writer / balenaEtcher.</>
                    ) : (
                      s.b
                    )}
                  </p>
                  {s.b.startsWith("dd if=") && (
                    <div className="mt-3 flex items-center justify-between gap-4 border border-border bg-card px-3.5 py-2.5">
                      <code className="truncate text-[13px] text-muted-foreground">
                        dd if={ISO} of=/dev/sdX bs=4M status=progress
                      </code>
                      <CopyButton
                        text={`dd if=${ISO} of=/dev/sdX bs=4M status=progress`}
                      />
                    </div>
                  )}
                </div>
              </li>
            ))}
          </ol>
          <p className="mt-8 text-sm text-zinc-600">
            Requires a UEFI machine with Secure Boot off. Runs well in a VM
            (QEMU/KVM, 2 CPU / 4 GB / 25 GB).
          </p>
        </section>
      </main>

      {/* footer */}
      <footer className="border-t border-border">
        <div className="mx-auto flex max-w-5xl flex-col items-center gap-4 px-6 py-8 text-sm text-muted-foreground sm:flex-row sm:justify-between">
          <img
            src={logoUrl}
            alt="ix1"
            className="h-4 w-auto dark:invert"
          />
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
              href="releases.html"
            >
              Release notes
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
