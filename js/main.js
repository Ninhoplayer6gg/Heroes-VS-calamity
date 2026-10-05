'use strict';
// Ponto de entrada

window.addEventListener('DOMContentLoaded', () => {
  // Libera o áudio no primeiro toque/clique/tecla
  const unlock = () => Sfx.unlock();
  window.addEventListener('pointerdown', unlock, { once: true });
  window.addEventListener('keydown', unlock, { once: true });
  Game.init();
});
