; === DEFINIÇÃO DAS RAÇAS =====
breed [queens queen]           ; Rainha do formigueiro
breed [worker-ants worker-ant] ; Formigas operárias (podem subir em móveis)
breed [ground-ants ground-ant] ; Formigas que só coletam comida do chão
breed [frogs frog]

; === DEFINIÇÃO DE VARIÁVEIS ===
turtles-own [
  carrying-food?    ; Indica se a formiga está carregando comida
  on-fire?          ; Indica se a formiga está pegando fogo
  fire-timer        ; Controla a duração da animação de fogo
]

queens-own [
  energy            ; Energia da rainha
  lifespan          ; Tempo de vida da rainha
  reproduction-timer ; Timer para controlar a reprodução
]

worker-ants-own [
  energy            ; Energia da formiga operária
  lifespan          ; Tempo de vida da formiga operária
]

ground-ants-own [
  energy            ; Energia da formiga de solo
  lifespan          ; Tempo de vida da formiga de solo
]

patches-own [
  chemical           ; Intensidade do rastro químico deixado pelas formigas
  food               ; Quantidade de comida presente no patch
  nest?              ; Indica se o patch faz parte do ninho
  nest-scent         ; Intensidade do cheiro do ninho para orientação das formigas
  food-source-number ; Número identificador da fonte de comida (1 a 5)
  food-counter?      ; Indica se o patch contém resto de comida (em móveis)
  trash?             ; Indica se o patch representa uma lixeira
  obstacle?          ; Indica se há obstáculo no patch
  altura             ; Altura do obstáculo (importante para saber se a formiga pode subir)
  pode-subir?        ; Indica se a formiga pode subir neste patch
  movel?             ; Indica se o patch pertence a um móvel (mesa, pia, sofá etc.)
]

; == VARIÁVEIS DOS SAPOS ==
frogs-own[
  energy              ; nível de energia atual
  hunting-radius      ; raio de detecção de formigas
]

; === VARIÁVEIS GLOBAIS ===
globals [
  total-food-collected ; Total de comida coletada pelo formigueiro
  min-ants             ; Número mínimo de formigas no formigueiro
]

; === PROCEDIMENTOS DE CONFIGURAÇÃO ===
to setup
  clear-all                               ; Limpa o mundo

  set min-ants 40                         ; Define o mínimo de formigas como 20
  set total-food-collected 0              ; Inicializa o contador de comida

  ; Define formatos para as formigas
  set-default-shape queens "ant 2"    ; Forma de borboleta para a rainha
  set-default-shape worker-ants "bug"     ; Forma de inseto para operárias
  set-default-shape ground-ants "ant"     ; Forma de formiga para formigas do solo

  ; Cria a rainha no centro do ninho
  create-queens 1 [
    set size 4                            ; Rainha maior que as outras
    set color magenta                     ; Cor diferente para identificar a rainha
    setxy 0 0                             ; Posiciona no centro do ninho
    set energy 100                        ; Define energia inicial
    set lifespan 1000                     ; Rainha vive mais
    set reproduction-timer 0              ; Inicializa timer de reprodução
    set carrying-food? false              ; Rainha não carrega comida
    set on-fire? false                    ; Inicializa como não pegando fogo
    set fire-timer 0                      ; Inicializa timer de fogo
  ]

  ; Cria formigas operárias iniciais
  create-worker-ants round (population * 0.6) [
    set size 2                            ; Define tamanho
    set color red                         ; Define cor inicial (vermelha)
    setxy 0 0                             ; Começa no ninho
    set energy 5                         ; Define energia inicial
    set lifespan 500                      ; Define tempo de vida
    set carrying-food? false              ; Inicialmente não carrega comida
    set on-fire? false                    ; Inicializa como não pegando fogo
    set fire-timer 0                      ; Inicializa timer de fogo
  ]

  ; Cria formigas de solo iniciais
  create-ground-ants round (population * 0.4) [
    set size 1.5                          ; Define tamanho (um pouco menor)
    set color orange                      ; Define cor inicial (laranja)
    setxy 0 0                             ; Começa no ninho
    set energy 4                         ; Define energia inicial
    set lifespan 400                      ; Define tempo de vida (menor)
    set carrying-food? false              ; Inicialmente não carrega comida
    set on-fire? false                    ; Inicializa como não pegando fogo
    set fire-timer 0                      ; Inicializa timer de fogo
  ]

  setup-patches                           ; Inicializa os patches

  ; Criação dos sapos
  set-default-shape frogs "frog top"
  create-frogs num-frogs [
    set shape "frog top"
    set color green
    set size 3
    set energy frog-energy
    set hunting-radius frog-hunting-radius
    ; Posiciona fora do ninho
    setxy random-xcor random-ycor
    while [ [nest?] of patch-here ] [ setxy random-xcor random-ycor ]
    set on-fire? false                    ; Inicializa como não pegando fogo
    set fire-timer 0                      ; Inicializa timer de fogo
  ]

  reset-ticks                             ; Reseta o contador de tempo
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; INICIALIZAÇÃO DOS PATCHES ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-patches
  ask patches [
    set food-counter? false           ; Inicializa sem restos de comida
    set trash? false                  ; Inicializa sem lixo
    set obstacle? false               ; Inicializa sem obstáculo
    set pode-subir? false             ; Inicializa como não podendo subir
    set movel? false                  ; Inicializa como não sendo móvel
    setup-nest                        ; Configura o ninho
    setup-food                        ; Define fontes de comida
  ]
  setup-kitchen                       ; Configura objetos da cozinha
  setup-food-remnants                 ; Adiciona restos de comida em móveis
  ask patches [
    recolor-patch                     ; Atualiza a cor do patch conforme conteúdo
  ]
end

; Adiciona restos de comida nos móveis
to setup-food-remnants
  ; Mesa
  ask patches with [pxcor >= 15 and pxcor <= 35 and pycor >= -8 and pycor <= 8] [
    if random-float 1 < 0.2 [         ; 20% de chance de ter comida na mesa
      set food one-of [1 2]           ; Define comida
      set food-counter? true          ; Marca como resto
      set pcolor yellow               ; Cor amarela
    ]
  ]

  ; Pia
  ask patches with [pxcor >= -6 and pxcor <= 10 and pycor >= max-pycor - 6 and pycor <= max-pycor] [
    if random-float 1 < 0.3 [         ; 30% de chance de ter comida
      set food one-of [1 2]
      set food-counter? true
      set pcolor yellow
    ]
  ]

  ; Sofá
  ask patches with [(pxcor >= -30 and pxcor <= -10 and pycor >= -13 and pycor <= -5) or
                   (pxcor >= -30 and pxcor <= -10 and pycor >= -5 and pycor <= -2)] [
    if random-float 1 < 0.1 [         ; 10% de chance
      set food one-of [1 2]
      set food-counter? true
      set pcolor yellow
    ]
  ]
end

to setup-nest
  set nest? (distancexy 0 0) < 5            ; Define patches dentro de um raio de 5 unidades como ninho
  set nest-scent 200 - distancexy 0 0       ; Valor maior próximo ao ninho, decrescendo com a distância
end

to setup-kitchen
  ask patches [
    ; Geladeira
    if (pxcor > max-pxcor - 11) and (pycor > max-pycor - 10) [
      set obstacle? true
      set altura 3
      set pcolor gray - 2
      set movel? true
    ]

    ; Porta da geladeira
    if pxcor >= 25 and pxcor <= 35 and pycor >= max-pycor - 9 and pycor <= max-pycor - 9  [
      set obstacle? true
      set altura 3
      set pcolor gray - 1
      set movel? true
    ]

    ; Fogão
    if pxcor >= 14 and pxcor <= 22 and pycor >= max-pycor - 7 and pycor <= max-pycor [
      set obstacle? true
      set altura 1
      set pode-subir? true
      set pcolor gray - 1
      set movel? true
    ]

    ; Lixeira
    if pxcor >= -15 and pxcor <= -10 and pycor >= max-pycor - 5 and pycor <= max-pycor [
      set trash? true
      set food 1
      set food-source-number 5
    ]

    ; Cadeiras
    if (pxcor >= 18 and pxcor <= 23 and pycor >= 9 and pycor <= 10) or
       (pxcor >= 26 and pxcor <= 31 and pycor >= 9 and pycor <= 10) or
       (pxcor >= 18 and pxcor <= 23 and pycor >= -10 and pycor <= 10) or
       (pxcor >= 26 and pxcor <= 31 and pycor >= -10 and pycor <= 10) [
      set obstacle? true
      set altura 3
      set pcolor gray - 2
      set movel? true
    ]

    ; Mesa
    if pxcor >= 15 and pxcor <= 35 and pycor >= -8 and pycor <= 8 [
      set obstacle? true
      set altura 1
      set pode-subir? true
      set pcolor brown - 1
      set movel? true
    ]

    ; Pia
    if pxcor >= -6 and pxcor <= 10 and pycor >= max-pycor - 6 and pycor <= max-pycor [
      set obstacle? true
      set altura 1
      set pode-subir? true
      set pcolor gray + 2
      set movel? true
    ]

    ; Sofá
    if pxcor >= -30 and pxcor <= -10 and pycor >= -13 and pycor <= -5 [
      set obstacle? true
      set altura 1
      set pode-subir? true
      set pcolor red - 2
      set movel? true
    ]
    if pxcor >= -30 and pxcor <= -10 and pycor >= -5 and pycor <= -2 [
      set obstacle? true
      set altura 1
      set pode-subir? true
      set pcolor red - 3
      set movel? true
    ]
  ]
end

to setup-food
  ; Configura três fontes de alimento em posições específicas
  if (distancexy (0.9 * max-pxcor) 0) < 2 [
    set food-source-number 1
  ]
  if (distancexy (-0.6 * max-pxcor) (-0.5 * max-pycor)) < 3 [
    set food-source-number 2
  ]
  if (distancexy (-0.8 * max-pxcor) (0.9 * max-pycor)) < 5 [
    set food-source-number 3
  ]
  if (distancexy (-0.8 * min-pxcor) (-0.8 * max-pycor)) < 5 [
    set food-source-number 4
  ]
  ; Se o patch faz parte de uma fonte de alimento, atribui uma quantidade de comida (1 ou 2)
  if food-source-number > 0 [
    set food one-of [1 2]
  ]
end

to recolor-patch
  ifelse nest? [
    set pcolor violet                      ; Cor do ninho
  ][
    ifelse (food > 0 or food-counter?) [
      ; Patches com comida
      if food-source-number = 1 [ set pcolor cyan ]
      if food-source-number = 2 [ set pcolor sky ]
      if food-source-number = 3 [ set pcolor blue ]
      if food-source-number = 4 [ set pcolor lime ]
      if food-counter? [ set pcolor yellow ]
      if trash? [ set pcolor brown ]
    ][
      ; Patches sem comida
      ifelse movel? [
        ; Aplica cor dos móveis
        if pcolor = brown - 1 [ set pcolor brown - 1 ]
        if pcolor = gray + 1 [ set pcolor gray + 1 ]
        if pcolor = red - 2 [ set pcolor red - 2 ]
        if pcolor = gray - 1 [ set pcolor gray - 1 ]
        if pcolor = gray - 2 [ set pcolor gray - 2 ]
      ][
        set pcolor scale-color green chemical 0.1 5 ; Cor varia com o rastro químico
      ]
    ]
  ]
end

; === PROCEDIMENTO PRINCIPAL ===
to go
  ; Verifica se há comida suficiente para a rainha produzir novas formigas
  check-population

  ; Comportamento da rainha
  ask queens [
    move-queen
    reproduce
  ]

  ; Comportamento das formigas operárias
  ask worker-ants [
    ifelse on-fire? [
      ; Se estiver pegando fogo, executa animação de fogo
      animate-fire
    ][
      ; Comportamento normal da formiga
      if who >= ticks [ stop ]         ; Sincroniza a saída das formigas do ninho com o tempo
      ifelse carrying-food? = false [  ; Procura por comida se não estiver carregando
        look-for-food-worker
      ][
        return-to-nest                 ; Retorna ao ninho se estiver carregando comida
      ]
      wiggle                           ; Movimento aleatório para simular procura
      fd 1                             ; Move-se para frente
      decrease-lifespan                ; Diminui o tempo de vida

      ; Verifica se está no fogão - NOVO CÓDIGO
      check-stove
    ]
  ]

  ; Comportamento das formigas de solo
  ask ground-ants [
    ifelse on-fire? [
      ; Se estiver pegando fogo, executa animação de fogo
      animate-fire
    ][
      ; Comportamento normal da formiga
      if who >= ticks [ stop ]         ; Sincroniza a saída das formigas do ninho com o tempo
      ifelse carrying-food? = false [  ; Procura por comida se não estiver carregando
        look-for-food-ground
      ][
        return-to-nest                 ; Retorna ao ninho se estiver carregando comida
      ]
      wiggle                           ; Movimento aleatório para simular procura
      fd 1                             ; Move-se para frente
      decrease-lifespan                ; Diminui o tempo de vida

      ; Verifica se está no fogão - NOVO CÓDIGO
      check-stove
    ]
  ]

  ; Comportamento dos sapos predadores
  ask frogs [
    hunt-ants
    lose-energy
    reproduce-frogs
  ]

  diffuse chemical (diffusion-rate / 100) ; Difusão do rastro químico
  ask patches [
    set chemical chemical * (100 - evaporation-rate) / 100 ; Evaporação
    recolor-patch
  ]
  tick                                  ; Avança um passo de tempo
end

; === NOVOS PROCEDIMENTOS PARA ANIMAÇÃO DE FOGO ===

; Verifica se a formiga está no fogão
to check-stove
  ; Verifica se o patch atual é parte do fogão
  if [pxcor >= 14 and pxcor <= 22 and pycor >= max-pycor - 7 and pycor <= max-pycor] of patch-here [
    ; Inicia o processo de pegar fogo
    set on-fire? true
    set fire-timer 10  ; Define a duração da animação (10 ciclos)
    set color orange   ; Muda cor para laranja (início do fogo)
  ]
end

; Procedimento para animar formiga pegando fogo
to animate-fire
  ; Diminui o timer a cada ciclo
  set fire-timer fire-timer - 1

  ; Faz um movimento errático para simular a formiga pegando fogo
  rt random 90
  lt random 90
  fd 0.5

  ; Alterna entre cores de fogo (vermelho e laranja)
  ifelse fire-timer mod 2 = 0 [
    set color red
  ][
    set color orange
  ]

  ; Muda o tamanho para efeito visual
  set size size * 0.9

  ; Quando o timer acaba, a formiga morre
  if fire-timer <= 0 [
    die
  ]
end

; === RAINHA: REPRODUÇÃO E MOVIMENTAÇÃO ===
to move-queen
  ; A rainha movimenta-se apenas dentro do ninho
  ifelse not [nest?] of patch-here [
    face patch 0 0  ; Volta para o centro do ninho
    fd 1
  ][
    ; Movimento lento e limitado dentro do ninho
    rt random 20
    lt random 20
    fd 0.1
  ]
end

to reproduce
  ; Incrementa o timer de reprodução
  set reproduction-timer reproduction-timer + 1

  ; Verifica se é hora de reproduzir (a cada 50 ticks)
  if reproduction-timer >= 50 [
    set reproduction-timer 0  ; Reseta o timer

    ; Verifica condições para reprodução:
    ; 1. População abaixo do mínimo OU
    ; 2. Há comida suficiente no formigueiro (medido pelo total coletado)
    if (count worker-ants + count ground-ants < min-ants) or (total-food-collected >= 10) [

      ; Decide qual tipo de formiga criar com base nas necessidades
      ifelse count worker-ants < count ground-ants [
        ; Cria uma formiga operária
        hatch-worker-ants 1 [
          set size 2
          set color red
          set energy 50
          set lifespan 500
          set carrying-food? false
          set on-fire? false          ; Inicializa como não pegando fogo
          set fire-timer 0            ; Inicializa timer de fogo
          ; Move-se para longe da rainha
          rt random 360
          fd 1
        ]
      ] [
        ; Cria uma formiga de solo
        hatch-ground-ants 1 [
          set size 1.5
          set color orange
          set energy 40
          set lifespan 400
          set carrying-food? false
          set on-fire? false          ; Inicializa como não pegando fogo
          set fire-timer 0            ; Inicializa timer de fogo
          ; Move-se para longe da rainha
          rt random 360
          fd 1
        ]
      ]

      ; Consumir recursos
      set total-food-collected total-food-collected - 5
      if total-food-collected < 0 [ set total-food-collected 0 ]
    ]
  ]
end

; === VERIFICAÇÃO DE POPULAÇÃO ===
to check-population
  ; Se a população estiver abaixo do mínimo, força a reprodução
  if count worker-ants + count ground-ants < min-ants [
    ask one-of queens [
      set reproduction-timer 50  ; Força o timer para que a reprodução aconteça no próximo ciclo
    ]
  ]
end

; === FORMIGAS: DIMINUIÇÃO DO TEMPO DE VIDA ===
to decrease-lifespan
  set lifespan lifespan - 1
  if lifespan <= 0 [ die ]
end

; === FORMIGAS OPERÁRIAS: BUSCA POR COMIDA ===
to look-for-food-worker
  ; Formigas operárias podem pegar comida de qualquer lugar (chão ou móveis)
  if ([food] of patch-here > 0) or ([food-counter?] of patch-here) [

    if ([food-counter?] of patch-here) [
      ask patch-here [
        set food 1
        set food-counter? false

        ; Corrige a cor do patch após consumir resto de comida
        if (pxcor >= 15 and pxcor <= 35 and pycor >= -8 and pycor <= 8) [
          set pcolor brown - 1
        ]
        if (pxcor >= -6 and pxcor <= 10 and pycor >= max-pycor - 6 and pycor <= max-pycor) [
          set pcolor gray + 2
        ]
        if (pxcor >= -30 and pxcor <= -10 and pycor >= -13 and pycor <= -5) [
          set pcolor red - 2
        ]
        if (pxcor >= -30 and pxcor <= -10 and pycor >= -5 and pycor <= -2) [
          set pcolor red - 3
        ]
      ]
    ]

    ask patch-here [
      set food food - 1
      if food <= 0 [
        set food 0
        if food-source-number > 0 [ set food-source-number 0 ]
      ]
    ]

    set carrying-food? true            ; Indica que está carregando comida
    set color yellow                   ; Muda a cor para indicar que está carregando comida
    rt 180                             ; Vira 180 graus para retornar ao ninho
    stop                               ; Finaliza o procedimento atual
  ]

  if (chemical >= 0.05) and (chemical < 2) [
    uphill-chemical                    ; Segue o rastro de feromônio
  ]
end

; === FORMIGAS DE SOLO: BUSCA POR COMIDA ===
to look-for-food-ground
  ; Formigas de solo só podem pegar comida do chão (não em móveis)
  if not [movel?] of patch-here [
    if ([food] of patch-here > 0) [
      ask patch-here [
        set food food - 1
        if food <= 0 [
          set food 0
          if food-source-number > 0 [ set food-source-number 0 ]
        ]
      ]

      set carrying-food? true          ; Indica que está carregando comida
      set color yellow                 ; Muda a cor para indicar que está carregando comida
      rt 180                           ; Vira 180 graus para retornar ao ninho
      stop                             ; Finaliza o procedimento atual
    ]
  ]

  if (chemical >= 0.05) and (chemical < 2) [
    uphill-chemical                    ; Segue o rastro de feromônio
  ]
end

to return-to-nest
  ifelse nest? [
    set carrying-food? false

    ; Formigas operárias são vermelhas
    if breed = worker-ants [
      set color red
    ]

    ; Formigas de solo são laranjas
    if breed = ground-ants [
      set color orange
    ]

    ; Incrementa o contador de comida coletada
    set total-food-collected total-food-collected + 1

    rt 180                              ; Vira 180 graus para sair novamente
  ][
    set chemical chemical + 60          ; Deposita feromônio no caminho de volta
    uphill-nest-scent                   ; Move-se em direção ao ninho seguindo o gradiente
  ]
end

; === MOVIMENTAÇÃO ===
to uphill-chemical
  let scent-ahead chemical-scent-at-angle 0
  let scent-right chemical-scent-at-angle 45
  let scent-left chemical-scent-at-angle -45
  if (scent-right > scent-ahead) or (scent-left > scent-ahead) [
    ifelse scent-right > scent-left [
      rt 45                                ; Vira 45 graus à direita
    ][
      lt 45                                ; Vira 45 graus à esquerda
    ]
  ]
end

to uphill-nest-scent
  let scent-ahead nest-scent-at-angle 0
  let scent-right nest-scent-at-angle 45
  let scent-left nest-scent-at-angle -45
  if (scent-right > scent-ahead) or (scent-left > scent-ahead) [
    ifelse scent-right > scent-left [
      rt 45                               ; Vira 45 graus à direita
    ][
      lt 45                               ; Vira 45 graus à esquerda
    ]
  ]
end

to wiggle
  rt random 40                             ; Vira um ângulo aleatório à direita
  lt random 40                             ; Vira um ângulo aleatório à esquerda
  if not can-move? 1 or obstacle-ahead? [
    rt 180                                ; Se não puder se mover, vira 180 graus
  ]
end

; === FUNÇÕES AUXILIARES ===
to-report nest-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]               ; Se não houver patch, retorna 0
  report [nest-scent] of p                 ; Retorna o valor de 'nest-scent' do patch
end

to-report chemical-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]               ; Se não houver patch, retorna 0
  report [chemical] of p                   ; Retorna o valor de 'chemical' do patch
end

to-report obstacle-ahead?
  let p patch-ahead 1
  if p = nobody [ report true ]

  ; Para formigas operárias (podem subir em móveis)
  if breed = worker-ants [
    report ([obstacle?] of p) and (not [pode-subir?] of p) and ([altura] of p >= 2)
  ]

  ; Para formigas de solo (não podem subir em móveis)
  if breed = ground-ants [
    report ([obstacle?] of p) or ([movel?] of p)
  ]

  ; Para outros agentes (rainha, sapos)
  report ([obstacle?] of p)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PROCEDIMENTOS DOS SAPOS: CAÇA E REPRODUÇÃO   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Se há formiga num raio de detecção, dirige-se a ela;
; se colide, "come" (mata) e ganha energia.
; Se não encontra, movimenta-se aleatoriamente.
to hunt-ants
  ; Caça qualquer tipo de formiga (operária ou de solo) que não esteja carregando comida
  let target one-of (turtle-set worker-ants ground-ants) with [carrying-food? = false] in-radius hunting-radius

  ifelse target != nobody [                   ; Se encontrou ao menos uma formiga
    face target                               ; Vira-se na direção da formiga alvo
    fd 1                                      ; Avança 1 unidade em direção a ela

    ; Verifica se há formigas operárias aqui
    if any? worker-ants-here with [carrying-food? = false] [
      ask one-of worker-ants-here with [carrying-food? = false] [ die ]
      set energy energy + 20
    ]

    ; Verifica se há formigas de solo aqui
    if any? ground-ants-here with [carrying-food? = false] [
      ask one-of ground-ants-here with [carrying-food? = false] [ die ]
      set energy energy + 15  ; Formigas de solo dão menos energia
    ]
  ] [
    ; Caso não tenha encontrado nenhuma formiga
    ; Gira aleatoriamente até 60° para a direita
    rt random 60
    lt random 60  ; E até 60° para a esquerda
    fd 1          ; Avança 1 unidade (vagueando)
  ]
end

to lose-energy             ; A cada passo, sapo consome 1 de energia (morre se chega a zero).
  set energy energy - 1    ; Decrementa energia em 1
  if energy <= 0 [ die ]   ; Se a energia chegar a 0 ou menos, o sapo morre
end

; Quando acumula energia extra, há pequena chance de gerar descendente,
; dividindo sua energia.
to reproduce-frogs
  ; Condição para reprodução: energia acima de frog-energy + 20
  ; e teste aleatório com 1% de chance
  if energy > frog-energy + 20 and random-float 1 < 0.01 [
    hatch-frogs 1 [              ; Gera um novo sapo no mesmo patch
      set energy frog-energy     ; O filhote inicia com energia padrão
      rt random 360              ; Gira em direção aleatória
      fd 1                       ; Anda 1 unidade para não ficar exatamente sobre o pai
    ]
    set energy energy / 2        ; Divide a energia restante igualmente entre pai e filho
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
257
10
762
516
-1
-1
7.0
1
10
1
1
1
0
0
0
1
-35
35
-35
35
1
1
1
ticks
30.0

BUTTON
46
71
126
104
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
31
106
221
139
diffusion-rate
diffusion-rate
0.0
99.0
10.0
1.0
1
NIL
HORIZONTAL

SLIDER
31
141
221
174
evaporation-rate
evaporation-rate
0.0
99.0
7.0
1.0
1
NIL
HORIZONTAL

BUTTON
136
71
211
104
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
31
36
221
69
population
population
0.0
200.0
72.0
1.0
1
NIL
HORIZONTAL

PLOT
5
197
248
476
Food in each pile
time
food
0.0
50.0
0.0
120.0
true
false
"" ""
PENS
"food-in-pile1" 1.0 0 -11221820 true "" "plotxy ticks sum [food] of patches with [pcolor = cyan]"
"food-in-pile2" 1.0 0 -13791810 true "" "plotxy ticks sum [food] of patches with [pcolor = sky]"
"food-in-pile3" 1.0 0 -13345367 true "" "plotxy ticks sum [food] of patches with [pcolor = blue]"

SLIDER
768
12
940
45
num-frogs
num-frogs
1
50
1.0
1
1
NIL
HORIZONTAL

SLIDER
768
51
940
84
frog-energy
frog-energy
1
100
34.0
1
1
NIL
HORIZONTAL

SLIDER
768
88
940
121
frog-hunting-radius
frog-hunting-radius
1
20
7.0
1
1
NIL
HORIZONTAL

MONITOR
770
127
847
172
NIL
count frogs
2
1
11

PLOT
979
10
1291
177
total-food-collected
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

MONITOR
768
176
879
221
qtd Formigas
min-ants
17
1
11

@#$#@#$#@
## WHAT IS IT?

In this project, a colony of ants forages for food. Though each ant follows a set of simple rules, the colony as a whole acts in a sophisticated way.

## HOW IT WORKS

When an ant finds a piece of food, it carries the food back to the nest, dropping a chemical as it moves. When other ants "sniff" the chemical, they follow the chemical toward the food. As more ants carry food to the nest, they reinforce the chemical trail.

## HOW TO USE IT

Click the SETUP button to set up the ant nest (in violet, at center) and three piles of food. Click the GO button to start the simulation. The chemical is shown in a green-to-white gradient.

The EVAPORATION-RATE slider controls the evaporation rate of the chemical. The DIFFUSION-RATE slider controls the diffusion rate of the chemical.

If you want to change the number of ants, move the POPULATION slider before pressing SETUP.

## THINGS TO NOTICE

The ant colony generally exploits the food source in order, starting with the food closest to the nest, and finishing with the food most distant from the nest. It is more difficult for the ants to form a stable trail to the more distant food, since the chemical trail has more time to evaporate and diffuse before being reinforced.

Once the colony finishes collecting the closest food, the chemical trail to that food naturally disappears, freeing up ants to help collect the other food sources. The more distant food sources require a larger "critical number" of ants to form a stable trail.

The consumption of the food is shown in a plot.  The line colors in the plot match the colors of the food piles.

## EXTENDING THE MODEL

Try different placements for the food sources. What happens if two food sources are equidistant from the nest? When that happens in the real world, ant colonies typically exploit one source then the other (not at the same time).

In this project, the ants use a "trick" to find their way back to the nest: they follow the "nest scent." Real ants use a variety of different approaches to find their way back to the nest. Try to implement some alternative strategies.

The ants only respond to chemical levels between 0.05 and 2.  The lower limit is used so the ants aren't infinitely sensitive.  Try removing the upper limit.  What happens?  Why?

In the `uphill-chemical` procedure, the ant "follows the gradient" of the chemical. That is, it "sniffs" in three directions, then turns in the direction where the chemical is strongest. You might want to try variants of the `uphill-chemical` procedure, changing the number and placement of "ant sniffs."

## NETLOGO FEATURES

The built-in `diffuse` primitive lets us diffuse the chemical easily without complicated code.

The primitive `patch-right-and-ahead` is used to make the ants smell in different directions without actually turning.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo Ants model.  http://ccl.northwestern.edu/netlogo/models/Ants.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was developed at the MIT Media Lab using CM StarLogo.  See Resnick, M. (1994) "Turtles, Termites and Traffic Jams: Explorations in Massively Parallel Microworlds."  Cambridge, MA: MIT Press.  Adapted to StarLogoT, 1997, as part of the Connected Mathematics Project.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 1998.

<!-- 1997 1998 MIT -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

ant 2
true
0
Polygon -7500403 true true 150 19 120 30 120 45 130 66 144 81 127 96 129 113 144 134 136 185 121 195 114 217 120 255 135 270 165 270 180 255 188 218 181 195 165 184 157 134 170 115 173 95 156 81 171 66 181 42 180 30
Polygon -7500403 true true 150 167 159 185 190 182 225 212 255 257 240 212 200 170 154 172
Polygon -7500403 true true 161 167 201 150 237 149 281 182 245 140 202 137 158 154
Polygon -7500403 true true 155 135 185 120 230 105 275 75 233 115 201 124 155 150
Line -7500403 true 120 36 75 45
Line -7500403 true 75 45 90 15
Line -7500403 true 180 35 225 45
Line -7500403 true 225 45 210 15
Polygon -7500403 true true 145 135 115 120 70 105 25 75 67 115 99 124 145 150
Polygon -7500403 true true 139 167 99 150 63 149 19 182 55 140 98 137 142 154
Polygon -7500403 true true 150 167 141 185 110 182 75 212 45 257 60 212 100 170 146 172

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

computer workstation
false
0
Rectangle -7500403 true true 60 45 240 180
Polygon -7500403 true true 90 180 105 195 135 195 135 210 165 210 165 195 195 195 210 180
Rectangle -16777216 true false 75 60 225 165
Rectangle -7500403 true true 45 210 255 255
Rectangle -10899396 true false 249 223 237 217
Line -16777216 false 60 225 120 225

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

frog top
true
0
Polygon -7500403 true true 146 18 135 30 119 42 105 90 90 150 105 195 135 225 165 225 195 195 210 150 195 90 180 41 165 30 155 18
Polygon -7500403 true true 91 176 67 148 70 121 66 119 61 133 59 111 53 111 52 131 47 115 42 120 46 146 55 187 80 237 106 269 116 268 114 214 131 222
Polygon -7500403 true true 185 62 234 84 223 51 226 48 234 61 235 38 240 38 243 60 252 46 255 49 244 95 188 92
Polygon -7500403 true true 115 62 66 84 77 51 74 48 66 61 65 38 60 38 57 60 48 46 45 49 56 95 112 92
Polygon -7500403 true true 200 186 233 148 230 121 234 119 239 133 241 111 247 111 248 131 253 115 258 120 254 146 245 187 220 237 194 269 184 268 186 214 169 222
Circle -16777216 true false 157 38 18
Circle -16777216 true false 125 38 18

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

plant
false
5
Rectangle -7500403 true false 135 90 165 300
Polygon -7500403 true false 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true false 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true false 165 180 210 135 255 120 225 180 165 210
Polygon -7500403 true false 135 180 135 210 75 180 45 120 90 135
Polygon -7500403 true false 165 105 210 60 255 45 225 105 165 135
Polygon -7500403 true false 135 105 135 135 75 105 45 45 90 60
Polygon -7500403 true false 165 90 180 45 150 15 120 45 135 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
