const SERVER_HOST = "ucminecraft.artisen.xyz";

fetch(`https://api.mcsrvstat.us/2/${SERVER_HOST}`, { cache: "no-store" })
  .then(r => r.json())
  .then(data => {
    const statusEl = document.getElementById("server-status");
    const playerEl = document.getElementById("player-count");

    if (!statusEl || !playerEl) return;

    if (data.online) {
      statusEl.textContent = "Online";
      statusEl.className = "font-semibold text-green-600";

      const online = data.players?.online ?? 0;
      const max = data.players?.max ?? "?";

      playerEl.textContent = `${online} / ${max}`;
    } else {
      statusEl.textContent = "Offline";
      statusEl.className = "font-semibold text-red-600";
      playerEl.textContent = "0 / 0";
    }
  })
  .catch(err => {
    console.error("Server status check failed:", err);

    const statusEl = document.getElementById("server-status");
    const playerEl = document.getElementById("player-count");

    if (statusEl) {
      statusEl.textContent = "Offline";
      statusEl.className = "font-semibold text-red-600";
    }
    if (playerEl) {
      playerEl.textContent = "0 / 0";
    }
  });
