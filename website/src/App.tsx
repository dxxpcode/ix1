import { ArrowDown, ArrowUpRight } from "lucide-react"

import { buttonVariants } from "@/components/ui/button"
import { cn } from "@/lib/utils"

const RELEASE = "0.8.0"
const ISO = `ix1-${RELEASE}-x86_64.iso`
const PARTS = [0, 1, 2].map((i) => `${ISO}.part0${i}`)
const BASE = `https://github.com/dxxpcode/ix1/releases/download/v${RELEASE}`

const FEATURES = [
  {
    title: "Atomic updates, instant rollback",
    body: "The whole OS updates as a single signed image. It downloads in the background and you reboot into it. Something wrong? The previous image is still installed — roll back and keep working.",
  },
  {
    title: "Signed & verified",
    body: "Every image is cryptographically signed. The system refuses anything that doesn't verify before it ever boots.",
  },
  {
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
          <a href="#top" className="flex items-center gap-2 font-bold tracking-tight">
            <svg width="15" height="15" viewBox="0 0 15 15" fill="currentColor" aria-hidden>
              <path d="M7.5 1.5 14 13.5H1Z" />
            </svg>
            ix1
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
          <a
            href="#download"
            className={cn(buttonVariants({ size: "sm" }), "rounded-full")}
          >
            Download
          </a>
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
            backgroundImage:
              "radial-gradient(circle at 1px 1px, rgba(255,255,255,0.12) 1px, transparent 0)",
            backgroundSize: "32px 32px",
            maskImage:
              "radial-gradient(ellipse 70% 60% at 50% 40%, black 30%, transparent 75%)",
            WebkitMaskImage:
              "radial-gradient(ellipse 70% 60% at 50% 40%, black 30%, transparent 75%)",
          }}
        />
        <div className="relative">
          <p className="mb-6 text-sm font-medium tracking-wide text-muted-foreground">
            ix1 — a minimal atomic Linux desktop
          </p>
          <h1 className="mx-auto max-w-3xl bg-gradient-to-b from-white via-white to-zinc-500 bg-clip-text text-[64px] font-bold leading-[1.02] tracking-[-0.04em] text-transparent sm:text-[88px]">
            A desktop that just works.
          </h1>
          <p className="mx-auto mt-6 max-w-xl text-lg leading-relaxed text-muted-foreground">
            Every update is one signed image. It installs in the background and
            rolls back instantly.
          </p>
          <div className="mt-10 flex justify-center gap-3">
            <a
              href="#download"
              className={cn(
                buttonVariants({ size: "lg" }),
                "rounded-full px-7"
              )}
            >
              <ArrowDown />
              Download ix1 {RELEASE}
            </a>
            <a
              href="https://github.com/dxxpcode/ix1"
              className={cn(
                buttonVariants({ variant: "outline", size: "lg" }),
                "rounded-full border-border px-7"
              )}
            >
              GitHub
              <ArrowUpRight />
            </a>
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
                "p-8",
                i > 0 && "border-t border-border sm:border-l sm:border-t-0"
              )}
            >
              <p className="mb-6 text-[13px] font-medium text-zinc-600">
                0{i + 1}
              </p>
              <h3 className="mb-3 font-semibold tracking-tight">{f.title}</h3>
              <p className="text-sm leading-relaxed text-muted-foreground">
                {f.body}
              </p>
            </div>
          ))}
        </section>

        {/* download */}
        <section id="download" className="py-28">
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
                <p className="mb-1.5 text-xs font-medium uppercase tracking-wider text-zinc-600">
                  Download
                </p>
                <div className="flex flex-col gap-1.5">
                  {PARTS.map((p) => (
                    <a
                      key={p}
                      href={`${BASE}/${p}`}
                      className="w-fit text-[13px] text-muted-foreground underline decoration-border underline-offset-4 transition-colors hover:text-foreground"
                    >
                      <code>{p}</code>
                    </a>
                  ))}
                </div>
              </div>
              <div>
                <p className="mb-1.5 text-xs font-medium uppercase tracking-wider text-zinc-600">
                  Assemble
                </p>
                <code className="text-[13px] text-muted-foreground">
                  cat {ISO}.part* &gt; {ISO}
                </code>
              </div>
              <div>
                <p className="mb-1.5 text-xs font-medium uppercase tracking-wider text-zinc-600">
                  Checksum
                </p>
                <code className="text-[13px] text-muted-foreground">
                  sha256sum -c {ISO}.sha256
                </code>
              </div>
              <div>
                <p className="mb-1.5 text-xs font-medium uppercase tracking-wider text-zinc-600">
                  Signature
                </p>
                <code className="text-[13px] text-muted-foreground">
                  cosign verify-blob --key ix1.pub --signature {ISO}.sig {ISO}
                </code>
              </div>
              <div className="flex gap-6 pt-1 text-sm">
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
        <section id="install" className="pb-28">
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
                <p className="text-[15px] text-muted-foreground">
                  <strong className="font-semibold text-foreground">
                    {s.t}
                  </strong>{" "}
                  {s.b.startsWith("dd if=") ? (
                    <>
                      —{" "}
                      <code className="text-[13px] text-foreground">
                        dd if={ISO} of=/dev/sdX bs=4M status=progress
                      </code>
                      , or Fedora Media Writer / balenaEtcher.
                    </>
                  ) : (
                    s.b
                  )}
                </p>
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
          <span className="flex items-center gap-2 font-bold tracking-tight text-foreground">
            <svg width="12" height="12" viewBox="0 0 15 15" fill="currentColor" aria-hidden>
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
