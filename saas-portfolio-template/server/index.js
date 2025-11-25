const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const path = require("path");
const projects = require("./projects.json");

const app = express();
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// API: projects
app.get("/api/projects", (req, res) => {
  res.json(projects);
});

// API: contact (demo) — logs the message and returns 200
app.post("/api/contact", (req, res) => {
  const { name, email, message } = req.body;
  console.log("[contact]", { name, email, message });
  // In production: validate and send email or persist
  res.json({ ok: true, message: "Received (demo)" });
});

// Serve client build if exists (optional)
const clientBuild = path.join(__dirname, "..", "client", "dist");
app.use(express.static(clientBuild));
app.get("*", (req, res) => {
  if (req.path.startsWith("/api")) return res.status(404).end();
  res.sendFile(path.join(clientBuild, "index.html"), (err) => {
    if (err) res.status(404).end();
  });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log("Server listening on", PORT));
