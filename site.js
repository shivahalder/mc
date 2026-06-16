(function () {
  const theme = window.UCTheme;
  if (!theme) return;

  function showToast(message) {
    let toast = document.getElementById("toast");
    if (!toast) {
      toast = document.createElement("div");
      toast.id = "toast";
      document.body.appendChild(toast);
    }
    toast.textContent = message;
    toast.classList.add("active");
    window.clearTimeout(showToast.timer);
    showToast.timer = window.setTimeout(function () {
      toast.classList.remove("active");
    }, 3000);
  }

  function bedrockAddress() {
    return theme.server.bedrock.host + ":" + theme.server.bedrock.port;
  }

  function syncJoinPanel() {
    const rows = document.querySelectorAll(".join-row");
    if (rows.length < 2) return;

    const javaAddress = rows[0].querySelector(".join-address");
    const bedrockEl = rows[1].querySelector(".join-address");
    if (javaAddress) javaAddress.textContent = theme.server.java.host;
    if (bedrockEl) bedrockEl.textContent = bedrockAddress();
  }

  function bindCopyButtons() {
    const rows = document.querySelectorAll(".join-row");
    rows.forEach(function (row, index) {
      const button = row.querySelector(".mc-btn--gold");
      if (!button || button.dataset.bound === "true") return;
      button.dataset.bound = "true";
      button.addEventListener("click", function () {
        const text = index === 0 ? theme.server.java.host : bedrockAddress();
        const label = index === 0 ? "Java IP" : "Bedrock address";
        navigator.clipboard.writeText(text).then(function () {
          showToast(label + " copied");
        });
      });
    });
  }

  async function updateStats() {
    const statValues = document.querySelectorAll(".hero-stat-value");
    if (statValues.length < 2) return;

    try {
      const response = await fetch(
        "https://api.mcsrvstat.us/3/" + theme.server.statusHost
      );
      const data = await response.json();
      statValues[0].textContent = data.online ? String(data.players.online) : "Offline";
    } catch {
      statValues[0].textContent = "Offline";
    }

    try {
      const response = await fetch(
        "https://discord.com/api/v10/invites/" +
          theme.social.discord.inviteCode +
          "?with_counts=true"
      );
      const data = await response.json();
      if (data.approximate_member_count !== undefined) {
        statValues[1].textContent = data.approximate_member_count.toLocaleString();
      } else {
        statValues[1].textContent = "Join";
      }
    } catch {
      statValues[1].textContent = "Join";
    }
  }

  syncJoinPanel();
  bindCopyButtons();
  updateStats();
  window.setInterval(updateStats, 60000);
})();
