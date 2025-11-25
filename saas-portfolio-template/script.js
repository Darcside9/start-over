// Minimal interactivity for SaaS portfolio

document.addEventListener("DOMContentLoaded", function () {
  // Nav toggle for small screens
  const navToggle = document.getElementById("nav-toggle");
  const siteNav = document.getElementById("site-nav");
  navToggle &&
    navToggle.addEventListener("click", function () {
      const expanded = this.getAttribute("aria-expanded") === "true";
      this.setAttribute("aria-expanded", String(!expanded));
      siteNav.classList.toggle("open");
    });

  // Simple modal for project case studies
  const modal = document.getElementById("modal");
  const modalBody = document.getElementById("modal-body");
  const modalClose = document.getElementById("modal-close");

  const caseStudies = {
    1: {
      title: "AI-enhanced CRM",
      body: "<p>Implemented LLM-based enrichment and routing. System reduced lead response time by 60% and increased qualified leads.</p><ul><li>Stack: Next.js, Node, PostgreSQL, OpenAI</li><li>Automation: Serverless functions + webhook pipeline</li></ul>",
    },
    2: {
      title: "AutoDocs — docs from code",
      body: "<p>Built an automated documentation generator that extracts examples and produces content from code comments and tests.</p><ul><li>Stack: Python, Sphinx, custom LLM summarizer</li></ul>",
    },
    3: {
      title: "Workflow Automation",
      body: "<p>End-to-end order processing pipeline with ML anomaly detection and multi-channel notifications.</p><ul><li>Stack: Airflow, Docker, Cloud Functions</li></ul>",
    },
  };

  document.querySelectorAll("[data-open]").forEach((btn) => {
    btn.addEventListener("click", function (e) {
      e.preventDefault();
      const id = this.getAttribute("data-open");
      const cs = caseStudies[id];
      if (!cs) return;
      modalBody.innerHTML = `<h3>${cs.title}</h3>${cs.body}`;
      modal.setAttribute("aria-hidden", "false");
      document.body.style.overflow = "hidden";
    });
  });

  modalClose && modalClose.addEventListener("click", closeModal);
  modal.addEventListener("click", function (e) {
    if (e.target === modal) closeModal();
  });
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") closeModal();
  });

  function closeModal() {
    modal.setAttribute("aria-hidden", "true");
    document.body.style.overflow = "";
  }

  // Contact form: simple client-side validation and friendly message
  const form = document.getElementById("contact-form");
  if (form) {
    form.addEventListener("submit", function (e) {
      // prevent actual mailto on submit during demo
      e.preventDefault();
      const name = form.name.value.trim();
      const email = form.email.value.trim();
      const message = form.message.value.trim();
      if (!name || !email || !message) {
        alert("Please complete all fields.");
        return;
      }
      // Show a simple success message
      alert(
        "Thanks " + (name || "there") + "! Your message was received (demo)."
      );
      form.reset();
    });
  }
});
