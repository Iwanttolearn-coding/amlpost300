const Post300 = (() => {
  const api = "/api/post300";
  async function request(path = "", options = {}) {
    const res = await fetch(`${api}${path}`, {
      headers: { "Content-Type": "application/json", ...(options.headers || {}) },
      ...options
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.error || "Request failed");
    return data;
  }
  return {
    list: (type, limit) => request(`?type=${encodeURIComponent(type)}${limit ? `&limit=${limit}` : ""}`),
    create: (type, payload) => request(`?type=${encodeURIComponent(type)}`, { method: "POST", body: JSON.stringify(payload) }),
    update: (type, payload) => request(`?type=${encodeURIComponent(type)}`, { method: "PUT", body: JSON.stringify(payload) }),
    remove: (type, id) => request(`?type=${encodeURIComponent(type)}`, { method: "DELETE", body: JSON.stringify({ id }) }),
    signup: (payload) => request("?action=member-signup", { method: "POST", body: JSON.stringify(payload) }),
    login: (payload) => request("?action=member-login", { method: "POST", body: JSON.stringify(payload) }),
    adminLogin: (password) => request("?action=admin-login", { method: "POST", body: JSON.stringify({ password }) }),
    assistant: (prompt) => request("?action=assistant", { method: "POST", body: JSON.stringify({ prompt }) })
  };
})();

const POST300_PHOTOS = [
  "https://media.base44.com/images/public/6a3d2806f16fa7f06a81b78e/bf3c44271_IMG_7553.jpg",
  "https://media.base44.com/images/public/6a3d2806f16fa7f06a81b78e/aaa850338_IMG_7552.jpg",
  "https://media.base44.com/images/public/6a3d2806f16fa7f06a81b78e/a01186b23_IMG_7551.jpg"
];

function toggleMenu() {
  document.getElementById("mobileMenu")?.classList.toggle("open");
}

function formatDate(value) {
  if (!value) return "";
  return new Date(`${value}T00:00:00`).toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric", year: "numeric" });
}

function escapeHtml(value = "") {
  return String(value).replace(/[&<>"']/g, (m) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" }[m]));
}

function toast(message, type = "ok") {
  const el = document.createElement("div");
  el.className = `toast ${type}`;
  el.textContent = message;
  document.body.appendChild(el);
  setTimeout(() => el.remove(), 3600);
}

function renderCalendar(target, events, date, onSelect) {
  const grid = document.getElementById(target);
  const title = document.querySelector(`[data-calendar-title="${target}"]`);
  const year = date.getFullYear();
  const month = date.getMonth();
  if (title) title.textContent = date.toLocaleDateString("en-US", { month: "long", year: "numeric" });
  const first = new Date(year, month, 1);
  const start = new Date(first);
  start.setDate(1 - first.getDay());
  const today = new Date().toISOString().slice(0, 10);
  let html = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((d) => `<div class="cal-day-header">${d}</div>`).join("");
  for (let i = 0; i < 42; i++) {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    const iso = d.toISOString().slice(0, 10);
    const dayEvents = events.filter((e) => e.event_date === iso || e.requested_date === iso);
    html += `<button class="cal-day ${d.getMonth() !== month ? "other-month" : ""} ${iso === today ? "today" : ""} ${dayEvents.length ? "booked" : ""}" data-date="${iso}">
      <span class="day-num">${d.getDate()}</span>
      ${dayEvents.slice(0, 2).map((e) => `<span class="day-event">${escapeHtml(e.title || e.event_type || e.full_name || "Booked")}</span>`).join("")}
    </button>`;
  }
  grid.innerHTML = html;
  grid.querySelectorAll(".cal-day").forEach((btn) => btn.addEventListener("click", () => onSelect?.(btn.dataset.date)));
}
