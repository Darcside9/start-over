import React, { useEffect, useState } from "react";
import { Routes, Route, Link } from "react-router-dom";
import axios from "axios";

function Nav() {
  return (
    <header className="site-header">
      <div className="container header-inner">
        <div className="brand">
          <Link to="/">Darc</Link>
        </div>
        <nav className="site-nav">
          <ul>
            <li>
              <Link to="/">Home</Link>
            </li>
            <li>
              <Link to="/projects">Projects</Link>
            </li>
            <li>
              <Link to="/contact">Contact</Link>
            </li>
          </ul>
        </nav>
      </div>
    </header>
  );
}

function Home() {
  return (
    <main>
      <section className="hero container">
        <h1>Build smarter web apps with AI automation</h1>
        <p className="lead">
          I design and develop SaaS products and automation pipelines that help
          teams ship faster.
        </p>
        <p>
          <Link to="/projects" className="btn btn-primary">
            See my work
          </Link>
          <Link
            to="/contact"
            className="btn btn-ghost"
            style={{ marginLeft: 12 }}
          >
            Hire me
          </Link>
        </p>
      </section>

      <section className="section container">
        <h2>Services</h2>
        <div className="cards-grid">
          <div className="card">
            <h3>Product Engineering</h3>
            <p>Full-stack SaaS development and architecture.</p>
          </div>
          <div className="card">
            <h3>AI Automation</h3>
            <p>LLM pipelines, agents and data automation.</p>
          </div>
          <div className="card">
            <h3>Integrations</h3>
            <p>APIs, webhooks and cloud automation.</p>
          </div>
        </div>
      </section>
    </main>
  );
}

function Projects() {
  const [projects, setProjects] = useState([]);
  useEffect(() => {
    axios
      .get("/api/projects")
      .then((r) => setProjects(r.data))
      .catch(() => {});
  }, []);
  return (
    <section className="section container">
      <h2>Projects</h2>
      <div className="projects-grid">
        {projects.map((p) => (
          <article key={p.id} className="project-card">
            <div className="thumb">{p.title}</div>
            <h3>{p.title}</h3>
            <p>{p.description}</p>
            <p>
              <a
                className="link"
                href={p.link || "#"}
                target="_blank"
                rel="noreferrer"
              >
                Open
              </a>
            </p>
          </article>
        ))}
      </div>
    </section>
  );
}

function Contact() {
  const [status, setStatus] = useState(null);
  async function handleSubmit(e) {
    e.preventDefault();
    const fd = new FormData(e.target);
    const data = Object.fromEntries(fd);
    try {
      await axios.post("/api/contact", data);
      setStatus("sent");
      e.target.reset();
    } catch (err) {
      setStatus("error");
    }
  }
  return (
    <section className="section container">
      <h2>Contact</h2>
      <form onSubmit={handleSubmit} className="contact-form">
        <label>
          Name
          <input name="name" required />
        </label>
        <label>
          Email
          <input name="email" type="email" required />
        </label>
        <label>
          Message<textarea name="message" rows={5} required></textarea>
        </label>
        <div className="form-actions">
          <button className="btn btn-primary" type="submit">
            Send message
          </button>
        </div>
        {status === "sent" && (
          <p className="muted">Thanks — message sent (demo)</p>
        )}
        {status === "error" && <p className="muted">Error sending message.</p>}
      </form>
    </section>
  );
}

export default function App() {
  return (
    <div>
      <Nav />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/projects" element={<Projects />} />
        <Route path="/contact" element={<Contact />} />
      </Routes>
      <footer className="site-footer container">
        <div>&copy; 2025 Darc — Web & AI Automation</div>
      </footer>
    </div>
  );
}
