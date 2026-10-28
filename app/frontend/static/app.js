const backendStatus = document.querySelector("#backend-status");
const backendHostname = document.querySelector("#backend-hostname");
const databaseStatus = document.querySelector("#database-status");
const databaseCount = document.querySelector("#database-count");
const runCheckButton = document.querySelector("#run-check");
const message = document.querySelector("#message");

function setStatus(element, text, healthy) {
  element.textContent = text;
  element.className = `status ${healthy ? "healthy" : "unhealthy"}`;
}

async function request(path, options = {}) {
  const response = await fetch(path, options);
  const body = await response.json();

  if (!response.ok) {
    throw new Error(body.detail || `Request failed with status ${response.status}`);
  }

  return body;
}

async function loadBackendHealth() {
  try {
    const result = await request("/api/health");
    setStatus(backendStatus, result.status, result.status === "healthy");
    backendHostname.textContent = result.hostname;
  } catch (error) {
    setStatus(backendStatus, "Unavailable", false);
    backendHostname.textContent = "unknown";
    message.textContent = error.message;
  }
}

async function loadDatabaseStatus() {
  try {
    const result = await request("/api/db");
    setStatus(databaseStatus, result.status, result.status === "connected");
    databaseCount.textContent = result.check_count;
  } catch (error) {
    setStatus(databaseStatus, "Unavailable", false);
    databaseCount.textContent = "—";
    message.textContent = error.message;
  }
}

async function runDatabaseCheck() {
  runCheckButton.disabled = true;
  message.textContent = "Running database check…";

  try {
    const result = await request("/api/db/check", { method: "POST" });
    setStatus(databaseStatus, result.status, result.status === "connected");
    databaseCount.textContent = result.check_count;
    message.textContent = `Database check ${result.check_id} recorded at ${result.checked_at}.`;
  } catch (error) {
    setStatus(databaseStatus, "Unavailable", false);
    message.textContent = error.message;
  } finally {
    runCheckButton.disabled = false;
  }
}

runCheckButton.addEventListener("click", runDatabaseCheck);
loadBackendHealth();
loadDatabaseStatus();
