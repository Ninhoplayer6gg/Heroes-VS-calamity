# Heroes VS Calamity

Jogo de sobrevivência em arena no estilo **Brotato** / **Vampire Survivors**. Escolha um herói com poderes próprios, sobreviva a 20 ondas de monstros, fique mais forte a cada nível e na loja, e derrote **A Calamidade**.

Feito com HTML5 Canvas e JavaScript puro: sem dependências, sem build. Funciona no computador e no celular.

## Como jogar

Abra o arquivo `index.html` no navegador. Se preferir rodar um servidor local:

```bash
python3 -m http.server 8000
# depois acesse http://localhost:8000
```

### Controles

| Ação | Teclado | Celular |
| --- | --- | --- |
| Mover | `WASD` ou setas | Arraste o dedo em qualquer lugar da tela |
| Habilidade especial | `Espaço` (ou `E` / `Q`) | Botão redondo no canto inferior direito |
| Pausar | `Esc` ou `P` | Botão ❚❚ |
| Escolher melhoria | `1` `2` `3` `4` | Toque na carta |
| Comprar na loja / trocar ofertas | `1`–`4` / `R` | Toque |

As armas atacam sozinhas. Você só se preocupa em se mover, coletar cristais e usar a habilidade na hora certa.

## Heróis

| Herói | Arma inicial | Habilidade (Espaço) | Atributos |
| --- | --- | --- | --- |
| 🛡️ **Cavaleiro** | Espada Larga | **Escudo Divino**: invulnerável por 3s + onda de choque | +30 vida, +4 armadura, −8% velocidade |
| 🔥 **Maga** | Bola de Fogo | **Chuva de Meteoros** sobre os inimigos | +15% dano, +15% área, −15 vida |
| 🏹 **Arqueira** | Arco Longo | **Tempestade de Flechas**: 3 rajadas em 360° | +15% vel. de ataque, +8% crítico, −10 vida |
| 💨 **Ninja** | Shuriken | **Passo Sombrio**: avanço que corta tudo no caminho (recarga de 6s) | +18% velocidade, +10% esquiva, −20 vida |
| ☠️ **Necromante** | Caveira Teleguiada | **Exército dos Mortos**: esqueletos lutam ao seu lado | +3% roubo de vida, +15% experiência |
| ⚡ **Xamã** | Corrente de Raios | **Fúria da Tempestade**: raios caem por 3,5s | +40 coleta, −15% recarga, +5% velocidade |
| 🪓 **Bárbaro** | Machado Arremessado | **Fúria Sangrenta**: ataque, velocidade e roubo de vida por 6s | +20 vida, +10% dano, −2 armadura |
| 🌟 **Paladina** | Aura Sagrada | **Julgamento Celestial**: cura 30% e pilar de luz em área | +1,5 regeneração, +10 vida, +10% área |

## Como funciona

- **Ondas**: 20 no total. Cada onda dura de 20 a 60 segundos e a vida é restaurada no início da seguinte.
- **Chefes**: o **Arauto da Calamidade** na onda 10 e **A Calamidade** na onda 20. Eles alternam ataques: anel de projéteis, investida, invocação de lacaios e espiral (só a Calamidade). Abaixo de 50% de vida entram em fúria.
- **Elites** (contorno dourado) aparecem a cada 3 ondas e deixam um **baú** com um item grátis.
- **Cristais** dão experiência e ouro. Ao subir de nível você escolhe 1 entre 3 melhorias (atributos, novas armas ou melhorias de arma).
- **Loja** entre ondas: compre itens e armas com ouro, ou troque as ofertas.
- **Raridades**: Comum, Raro, Épico e Lendário. Ondas mais avançadas e a Sorte aumentam a chance das raras.
- **Armas**: até 6 ao mesmo tempo, cada uma até o nível 5. Projéteis extras, área e velocidade de ataque afetam todas.

### Inimigos

Lodo, Morcego (zigue-zague), Brutamontes (tanque), Cultista (atira de longe), Bombinha (explode perto de você), Javali Infernal (avisa e investe em linha reta), Espectro (atravessa os outros) e Golem de Magma.

## Estrutura do projeto

```
index.html            página e telas (menu, loja, pausa…)
css/style.css         visual da interface
js/utils.js           configuração (tamanho da arena, nº de ondas…) e funções matemáticas
js/audio.js           efeitos sonoros sintetizados (WebAudio)
js/input.js           teclado e joystick de toque
js/sprites.js         desenho de heróis, inimigos, projéteis e cenário
js/entities.js        jogador, inimigos, chefes, projéteis, coletáveis e efeitos
js/game.js            laço principal, ondas, spawn, colisões, câmera e renderização
js/ui.js              HUD e telas em HTML
js/data/heroes.js     heróis e habilidades
js/data/weapons.js    armas
js/data/enemies.js    inimigos e chefes
js/data/items.js      melhorias de nível, itens da loja e raridades
```

## Como adicionar conteúdo

### Novo herói

Em `js/data/heroes.js`, copie um herói existente e altere:

```js
{
  id: 'vampira',
  name: 'Vampira',
  title: 'Sede Eterna',
  color: '#9b1d3a',
  dark: '#4a0c1b',
  desc: 'Drena a vida dos inimigos.',
  startWeapon: 'skull',                       // id de uma arma em weapons.js
  mods: { lifesteal: 0.08, maxHp: -10 },      // atributos somados aos valores base
  ability: {
    name: 'Nuvem de Morcegos',
    icon: '🦇',
    cooldown: 12,
    desc: 'Fere todos ao redor e cura você.',
    cast(game, p) {
      const n = game.damageArea(p.x, p.y, 180 * p.stats.area, 30 * game.abilityScale());
      p.heal(n * 2);
      game.addEffect(new RingEffect(p.x, p.y, 180, '#9b1d3a', 0.4, 6));
    },
  },
},
```

Para dar um visual próprio, adicione um `case 'vampira':` em `Sprites.hero` (`js/sprites.js`). Sem isso o herói aparece como um círculo com olhos na cor escolhida.

### Nova arma

Em `js/data/weapons.js`, crie uma entrada com `stats(nivel)` e `fire(game, p, w, s)`. Ferramentas úteis do `game`:

- `nearestEnemy(x, y, alcance)`, `randomEnemy(x, y, alcance)`
- `addProjectile({ kind, x, y, vx, vy, damage, pierce, bounces, explode, homing, gravity })`
- `damageArea(x, y, raio, dano)`, `coneDamage(...)`, `hitEnemy(inimigo, dano)`
- `addEffect(new RingEffect(...))`, `explosion(x, y, raio, cor)`, `shake(força)`, `schedule(segundos, fn)`

A descrição das melhorias de nível ("Dano 21 → 28") é gerada sozinha a partir de `stats()`.

### Novo inimigo ou item

- Inimigos: `js/data/enemies.js` (vida, velocidade, dano, comportamento e a partir de qual onda aparece).
- Itens da loja: `js/data/items.js`, lista `ITEMS` (`tier` 0–3 define a raridade).

## Ideias para continuar

- Desbloquear heróis ao vencer com outros
- Evoluções de arma (duas armas no nível máximo viram uma mais forte)
- Mais chefes e biomas para a arena
- Placar online e modo infinito depois da onda 20
