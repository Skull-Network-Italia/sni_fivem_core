const video = document.getElementById('bg-video');
const audio = document.getElementById('bg-audio');

const volUp = document.getElementById('vol-up');
const volDown = document.getElementById('vol-down');
const muteBtn = document.getElementById('mute');

// Stato iniziale
audio.volume = 0.4;
audio.muted = true;

// FiveM: serve un input reale
document.addEventListener('mousedown', () => {
    audio.muted = false;
    audio.play().catch(() => {});
}, { once: true });

volUp.onclick = (e) => {
    e.stopPropagation();
    audio.muted = false;
    audio.volume = Math.min(audio.volume + 0.1, 1);
};

volDown.onclick = (e) => {
    e.stopPropagation();
    audio.volume = Math.max(audio.volume - 0.1, 0);
};

muteBtn.onclick = (e) => {
    e.stopPropagation();
    audio.muted = !audio.muted;
    muteBtn.textContent = audio.muted ? '🔈' : '🔇';
};
