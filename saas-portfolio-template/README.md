SaaS Portfolio — Web & AI Automation

This repository contains a minimal, responsive portfolio template tailored for web development and AI automation consultancy.

Files

- `client/` — Vite + React single-page app (new)
- `server/` — Express API with demo endpoints (new)
- `index.html`, `style.css`, `script.js` — original static template (kept for reference)

How to run (fullstack)

1. From the `saas-portfolio-template` folder install dependencies:

```bash
npm install
npm --prefix client install
npm --prefix server install
```

2. Start both client and server in development mode:

```bash
npm run dev
```

This runs the Vite dev server for the React client and the Express server (API). The server exposes `GET /api/projects` and `POST /api/contact` (demo).

Quick preview (static)

If you just want to view the original static HTML quickly, open `index.html` in your browser or run:

```bash
python3 -m http.server 8000
```

Notes

- The contact API currently logs messages to the server console (demo). Replace with an email provider or persistence layer for production.
- The client makes requests to `/api/*` during development. The Express server listens on port 4000 by default.
- To deploy, build the client (`npm --prefix client run build`) and serve the `client/dist` directory from the server.

Next steps you might want me to do

- Move styles into component-scoped CSS or Tailwind and refactor components.
- Add authentication, CMS integration, or connect a real email service for contact.
- Add tests and a CI workflow for deploys (Vercel/Netlify/GitHub Pages).

License

Use and modify freely.
