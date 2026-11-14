# ix1 website

Static site for ix1 — download links, install steps, and release notes.
Built with Vite, React, Tailwind CSS v4, and shadcn/ui components
(monochrome theme, Geist Sans/Mono).

## Develop

```sh
npm install
npm run dev
```

## Build

```sh
npm run build   # outputs static files to dist/
```

`dist/` is self-contained (`base: "./"`) and can be served from any
static host. The site is published via GitHub Pages.

## Deploy (GitHub Pages)

Publish `dist/` to the `gh-pages` branch, then enable Pages on that
branch in the repository settings:

```sh
npm run build
cd dist
git init && git checkout -b gh-pages
git add -A && git commit -m "Publish ix1 website"
git push -f git@github.com:dxxpcode/ix1.git gh-pages
```
