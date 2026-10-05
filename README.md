# Heroes VS Calamity

Jogo de sobrevivência em arena no estilo **Brotato** / **Vampire Survivors**, feito em **Godot 4**. Escolha um super-herói, sobreviva a 20 ondas de monstros, fique mais forte a cada nível e na loja, e derrote **A Calamidade**.

Tudo é desenhado e sintetizado em código (personagens, efeitos, ícones e sons), então o projeto não depende de imagens ou áudios externos.

## Como abrir e jogar

1. Instale o [Godot 4](https://godotengine.org/download) (versão 4.4 ou mais nova; testado na 4.4.1 e na 4.7.2).
2. No Godot, clique em **Importar**, escolha o arquivo `project.godot` desta pasta e abra o projeto.
3. Aperte **F5** (ou o botão ▶) para jogar.

### Controles

| Ação | Teclado | Controle | Toque |
| --- | --- | --- | --- |
| Mover | `WASD` ou setas | Analógico esquerdo / direcional | Arraste o dedo em qualquer lugar |
| Habilidade especial | `Espaço` (ou `E` / `Q`) | `A` / `RB` | Botão redondo no canto |
| Pausar | `Esc` ou `P` | `Start` | Botão `II` |
| Escolher carta / comprar | `1`–`4` | Direcional + `A` | Toque na carta |
| Trocar ofertas da loja | `R` | | |

As armas atacam sozinhas. Você se preocupa em se mover, coletar cristais e usar a habilidade na hora certa.

## Heróis

Os heróis são personagens originais **inspirados** em super-heróis famosos. Eles têm nomes e visuais próprios, sem usar marcas registradas, para que o jogo possa ser publicado.

| Herói | Inspirado em | Arma exclusiva | Habilidade (Espaço) | Atributos |
| --- | --- | --- | --- | --- |
| **Titã Solar** | Superman | Visão Térmica: raios dos olhos que atravessam tudo | **Sopro Congelante**: congela os inimigos num cone | +40 vida, +3 armadura, regeneração |
| **Sentinela Esmeralda** | Lanterna Verde | Construtos do Anel: formas de energia que giram em volta | **Punho Esmeralda**: punho gigante que arremessa tudo | +20% área, −20% recarga, −10 vida |
| **Thorvald** | Thor | Martelo Trovejante: vai, atravessa tudo e volta | **Ira do Trovão**: chuva de raios por 3,5s | +25 vida, +15% dano, −5% velocidade |
| **Armadura Rubra** | Homem de Ferro | Repulsores: rajadas que explodem | **Salva de Micromísseis**: mísseis teleguiados | +5 armadura, +10% vel. de ataque |
| **Relâmpago Escarlate** | Flash | Rastro Elétrico: o caminho por onde corre fere os inimigos | **Câmera Lenta**: o mundo fica a 25% da velocidade | +35% velocidade, +8% esquiva, −20 vida |
| **Amazona Imortal** | Mulher-Maravilha | Laço Dourado: varre um arco longo e prende | **Braceletes Refletores**: devolvem os tiros inimigos | +20 vida, +2 armadura, +8% crítico |
| **Vigia Noturno** | Batman | Bumerangues Táticos: ricocheteiam entre inimigos | **Bomba de Fumaça**: fica invisível e a fumaça fere | +10% crítico, esquiva, +25% ouro, sorte |
| **Aracnídeo** | Homem-Aranha | Lançador de Teia: atravessa e deixa lento | **Rede Gigante**: prende os inimigos no lugar | +15% velocidade, +10% esquiva e vel. de ataque |

Além da arma exclusiva, qualquer herói pode ganhar as armas comuns: Espada de Energia, Granada de Plasma, Drone de Combate, Bobina Tesla, Campo de Força e Satélites Orbitais.

## Como funciona

- **Ondas**: são 20, cada uma dura de 20 a 60 segundos. A vida é restaurada no início de cada onda.
- **Chefes**: o **Arauto da Calamidade** na onda 10 e **A Calamidade** na onda 20. Eles alternam entre anel de projéteis, investida, invocação de lacaios e espiral (só a Calamidade), e entram em fúria com menos de 50% de vida.
- **Elites** (contorno dourado) aparecem a cada 3 ondas e deixam um **baú** com um item grátis.
- **Cristais** dão experiência e ouro. Ao subir de nível, você escolhe 1 entre 3 melhorias: atributos, armas novas ou melhorias de arma.
- **Loja** entre as ondas: compre itens e armas com ouro, ou troque as ofertas.
- **Raridades**: Comum, Raro, Épico e Lendário. Ondas avançadas e Sorte aumentam a chance das melhores.
- **Armas**: até 6 ao mesmo tempo, cada uma até o nível 5.
- **Efeitos de controle**: congelado (não se move nem fere), preso na teia e lento.

## Estrutura do projeto

```
project.godot                 configurações (janela, controles, autoload de som)
scenes/main.tscn              cena principal: mundo, câmera, camadas, interface
scripts/
  game.gd                     laço do jogo: ondas, spawn, combate, coleta, câmera
  world_layer.gd              desenha cada camada do mundo (chão, inimigos, efeitos…)
  floor_painter.gd            pinta o chão da arena uma vez só
  core/config.gd              constantes (tamanho da arena, nº de ondas, cores)
  core/art.gd                 desenho dos inimigos, chefes, projéteis e coletáveis
  core/icons.gd               ícones desenhados em código
  core/sfx.gd                 sons sintetizados (autoload "Sfx")
  core/util.gd, spatial_grid.gd   matemática e busca rápida de vizinhos
  entities/                   jogador, inimigo, chefe, projétil, coletável, efeitos
  heroes/                     um arquivo por herói + hero_db.gd (lista do menu)
  weapons/                    um arquivo por arma + weapon_db.gd (registro)
  data/enemy_db.gd            inimigos e chefes
  data/item_db.gd             itens da loja, melhorias de nível e raridades
  ui/game_ui.gd               menu, HUD, cartas, loja, pausa e fim de jogo
tests/simulate.tscn           simulação automática (veja abaixo)
assets/fonts/                 fontes Bangers e Barlow Semi Condensed (licença OFL)
assets/shaders/vignette.gdshader   vinheta e efeito de câmera lenta
```

## Como adicionar conteúdo

### Novo herói

1. Copie um arquivo de `scripts/heroes/` (por exemplo `thorvald.gd`) e renomeie.
2. Mude `id`, `name`, `title`, `desc`, cores, `mods` (atributos), `start_weapon` e os dados da habilidade.
3. Escreva a habilidade em `cast(game, p)`. Exemplo de um herói que cura e empurra:

```gdscript
func cast(game: Game, p: Player) -> void:
	p.heal(p.stats.max_hp * 0.2)
	game.damage_area(p.position, 200.0, 40.0 * game.ability_scale(), {"knockback": 500.0})
	game.add_fx(Fx.Ring.new(p.position, 200.0, Color.CYAN, 0.4, 8.0))
```

4. Desenhe o visual em `draw_body(...)` (ou apague a função para usar o visual padrão).
5. Adicione o arquivo na lista `SCRIPTS` de `scripts/heroes/hero_db.gd`.

### Nova arma

Crie um script em `scripts/weapons/` que estende `WeaponBase`, com `stats(nivel)` e `fire(game, p, slot, s)`, e registre-o em `scripts/weapons/weapon_db.gd`. Para ser exclusiva de um herói, preencha `hero_only` com o `id` dele. Ferramentas úteis do `game`:

- `nearest_enemy(pos, alcance)`, `random_enemy(pos, alcance)`
- `add_projectile({...})` com `kind`, `pos`, `vel`, `damage`, `pierce`, `bounces`, `explode`, `homing`, `boomerang`, `slow`
- `damage_area(pos, raio, dano, opts)`, `cone_damage(...)`, `line_damage(...)`, `hit_enemy(inimigo, dano, opts)`
- `opts` aceita `knockback`, `slow`/`slow_time`, `freeze` e `root`
- `add_fx(Fx.Ring.new(...))`, `explosion(pos, raio, cor)`, `shake(força)`, `schedule(segundos, callable)`

O texto das melhorias de nível ("Dano 21 → 28") é gerado sozinho a partir de `stats()`.

### Novo inimigo ou item

- Inimigos: `scripts/data/enemy_db.gd` (vida, velocidade, dano, comportamento, a partir de qual onda aparece). O visual fica em `Art.enemy` (`scripts/core/art.gd`).
- Itens: lista `ITEMS` em `scripts/data/item_db.gd` (`tier` de 0 a 3 define a raridade).

## Simulação automática

Um bot joga as 20 ondas com cada herói em "modo deus" (sem morrer) e mostra nível, abates, tempo nas lutas de chefe e quanto dano levou. Serve para achar erros e ajustar o balanceamento:

```bash
godot --headless --path . res://tests/simulate.tscn
godot --headless --path . res://tests/simulate.tscn -- thorvald   # só um herói
```

## Exportar

Em **Projeto → Exportar**, adicione uma predefinição (Windows, Linux, Web ou Android). O Godot pede para baixar os modelos de exportação na primeira vez. O projeto usa o renderizador **Compatibilidade**, que funciona inclusive no navegador.

## Créditos

- Fontes [Bangers](https://fonts.google.com/specimen/Bangers) e [Barlow Semi Condensed](https://fonts.google.com/specimen/Barlow+Semi+Condensed), sob a SIL Open Font License (`assets/fonts/OFL-*.txt`).
