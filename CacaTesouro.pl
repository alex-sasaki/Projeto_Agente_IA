% CAÇA AO TESOURO

:- dynamic(tamanho_grid/2).
:- dynamic(item_em/2).          % item_em(pos(X, Y), TipoItem)
:- dynamic(conteudo_dica/2).    % conteudo_dica(Id, direcao(Dir))

% 1. Operações Recursivas Básicas sobre Listas
pertence(X, [X|_]) :- !.
pertence(X, [_|Cauda]) :- pertence(X, Cauda).

remover_prefixo(0, Lista, [], Lista) :- !.
remover_prefixo(N, [X|Xs], [X|Escolhidos], Resto) :-
    N > 0,
    N1 is N - 1,
    remover_prefixo(N1, Xs, Escolhidos, Resto).

% 2. Geração Recursiva de Coordenadas do Grid
gerar_todas_posicoes(0, _, _, _, Res, Res) :- !.
gerar_todas_posicoes(X, 0, MaxY, PosIni, Acum, Res) :-
    !,
    XAnt is X - 1,
    gerar_todas_posicoes(XAnt, MaxY, MaxY, PosIni, Acum, Res).
gerar_todas_posicoes(X, Y, MaxY, PosIni, Acum, Res) :-
    Y > 0,
    PosAtual = pos(X, Y),
    YAnt is Y - 1,
    (   PosAtual \= PosIni ->
        gerar_todas_posicoes(X, YAnt, MaxY, PosIni, [PosAtual|Acum], Res)
    ;   gerar_todas_posicoes(X, YAnt, MaxY, PosIni, Acum, Res)
    ).

% 3. Dedução de Direção Qualitativa entre Coordenadas
calcular_dica(pos(X, Y1), pos(X, Y2), direcao(acima)) :- Y2 > Y1, !.
calcular_dica(pos(X, Y1), pos(X, Y2), direcao(abaixo))   :- Y2 < Y1, !.
calcular_dica(pos(X1, _), pos(X2, _), direcao(esquerda)) :- X2 < X1, !.
calcular_dica(pos(X1, _), pos(X2, _), direcao(direita)) :- X2 > X1, !.
calcular_dica(pos(X1, Y1), pos(X2, Y2), direcao(Dir)) :-
    DX is abs(X2 - X1),
    DY is abs(Y2 - Y1),
    (   DY >= DX ->
        ( Y2 > Y1 -> Dir = cima ; Dir = sul )
    ;   ( X2 < X1 -> Dir = esquerda ; Dir = direita )
    ).

% 4. Encadeamento Recursivo de Itens e Obstáculos
encadear_itens(Id, [PosAtual, ProxPos | Resto]) :-
    !,
    calcular_dica(PosAtual, ProxPos, Dica),
    assertz(item_em(PosAtual, pista(Id))),
    assertz(conteudo_dica(Id, Dica)),
    format('[CONFIG] Pista ~w em ~w -> Aponta: ~w~n', [Id, PosAtual, Dica]),
    ProxId is Id + 1,
    encadear_itens(ProxId, [ProxPos | Resto]).

encadear_itens(_, [PosTesouro]) :-
    assertz(item_em(PosTesouro, tesouro)),
    format('[CONFIG] Tesouro sorteado em ~w~n', [PosTesouro]).

posicionar_obstaculos([]) :- !.
posicionar_obstaculos([Pos|Resto]) :-
    assertz(item_em(Pos, obstaculo)),
    format('[CONFIG] Obstaculo alocado em ~w~n', [Pos]),
    posicionar_obstaculos(Resto).

% 5. Topologia do Grid e Navegação
direcoes_possiveis([pos(0, 1), pos(0, -1), pos(1, 0), pos(-1, 0)]).

dentro_limites(pos(X, Y)) :-
    tamanho_grid(MaxX, MaxY),
    X >= 1, X =< MaxX,
    Y >= 1, Y =< MaxY.

celula_livre(Pos) :-
    dentro_limites(Pos),
    \+ item_em(Pos, obstaculo).

satisfaz_dica(pos(_, Y1), pos(_, Y2), direcao(cima)) :- Y2 > Y1.
satisfaz_dica(pos(_, Y1), pos(_, Y2), direcao(sul))   :- Y2 < Y1.
satisfaz_dica(pos(X1, _), pos(X2, _), direcao(esquerda)) :- X2 < X1.
satisfaz_dica(pos(X1, _), pos(X2, _), direcao(direita)) :- X2 > X1.

% 6. Percepção Local de Obstáculos
% Percorre recursivamente as 4 direções ao redor da posição atual.
% Se encontrar um obstáculo ainda não registrado na memória, anuncia e adiciona.
perceber_obstaculos_locais(_, [], Conhecidos, Conhecidos).
perceber_obstaculos_locais(pos(X, Y), [pos(DX, DY)|Resto], Conhecidos, NovosConhecidos) :-
    NX is X + DX,
    NY is Y + DY,
    Viz = pos(NX, NY),
    dentro_limites(Viz),
    item_em(Viz, obstaculo),
    \+ pertence(Viz, Conhecidos),
    !,
    format('[PERCEPCAO] Encontrei um obstaculo em ~w! Desviando.~n', [Viz]),
    perceber_obstaculos_locais(pos(X, Y), Resto, [Viz|Conhecidos], NovosConhecidos).
perceber_obstaculos_locais(Pos, [_|Resto], Conhecidos, NovosConhecidos) :-
    perceber_obstaculos_locais(Pos, Resto, Conhecidos, NovosConhecidos).

% 7. Seleção de Ação
obter_vizinho(PosAtual, [pos(DX, DY)|_], Prox) :-
    PosAtual = pos(X, Y),
    NX is X + DX,
    NY is Y + DY,
    Prox = pos(NX, NY),
    celula_livre(Prox).
obter_vizinho(PosAtual, [_|RestoDirs], Prox) :-
    obter_vizinho(PosAtual, RestoDirs, Prox).

% Prioridade 1: Avançar para vizinho livre, não visitado e alinhado com a dica
decidir_passo(PosAtual, Dica, Visitados, _, avancar(Prox)) :-
    direcoes_possiveis(Dirs),
    obter_vizinho(PosAtual, Dirs, Prox),
    \+ pertence(Prox, Visitados),
    satisfaz_dica(PosAtual, Prox, Dica), !.

% Prioridade 2: Desvio lateral por qualquer vizinho livre não visitado
decidir_passo(PosAtual, _, Visitados, _, avancar(Prox)) :-
    direcoes_possiveis(Dirs),
    obter_vizinho(PosAtual, Dirs, Prox),
    \+ pertence(Prox, Visitados), !.

% Prioridade 3: Backtracking se não houver vizinhos livres inéditos
decidir_passo(_, _, _, [UltimaPos|_], recuar(UltimaPos)).

% 8. Ciclo de Execução Principal
iniciar_caca(MaxX, MaxY, NumPistas, NumObstaculos, PosInicial) :-
    retractall(tamanho_grid(_, _)),
    retractall(item_em(_, _)),
    retractall(conteudo_dica(_, _)),
    assertz(tamanho_grid(MaxX, MaxY)),

    Capacidade is (MaxX * MaxY) - 1,
    QtdPistasTesouro is NumPistas + 1,
    QtdTotalNecessaria is QtdPistasTesouro + NumObstaculos,
    (   QtdTotalNecessaria > Capacidade ->
        format('Erro: O grid nao comporta ~w itens.~n', [QtdTotalNecessaria]),
        fail
    ;   true
    ),

    gerar_todas_posicoes(MaxX, MaxY, MaxY, PosInicial, [], TodasPosicoes),
    random_permutation(TodasPosicoes, Embaralhadas),

    remover_prefixo(QtdPistasTesouro, Embaralhadas, LocaisItens, RestoDisponivel),
    remover_prefixo(NumObstaculos, RestoDisponivel, LocaisObstaculos, _),

    LocaisItens = [PrimeiraPista|_],
    calcular_dica(PosInicial, PrimeiraPista, DicaInicial),
    
    encadear_itens(1, LocaisItens),
    posicionar_obstaculos(LocaisObstaculos),

    format('~nGrid ~wx~w Inicializado com ~w Pista(s) e ~w Obstaculo(s)~n', 
           [MaxX, MaxY, NumPistas, NumObstaculos]),
    format('Agente em ~w com dica inicial: ~w~n~n', [PosInicial, DicaInicial]),
    % loop_agente(PosAtual, DicaAtual, Pilha, Visitados, ObstaculosConhecidos)
    loop_agente(PosInicial, DicaInicial, [], [PosInicial], []).

% Caso Base: Encontrou o tesouro
loop_agente(Pos, _, _, _, _) :-
    item_em(Pos, tesouro),
    !,
    format('Posicao atual: ~w~n', [Pos]),
    format('Sucesso! O tesouro foi localizado em ~w!~n', [Pos]).

% Passo Recursivo do Ciclo
loop_agente(PosAtual, DicaAtual, Pilha, Visitados, ObstaculosConhecidos) :-
    % 1. Percepção de Pista na célula atual
    (   item_em(PosAtual, pista(Id)), conteudo_dica(Id, NovaDica) ->
        format('[PERCEPCAO] Pista ~w em ~w! Nova dica: ~w~n', [Id, PosAtual, NovaDica]),
        DicaEfetiva = NovaDica
    ;   DicaEfetiva = DicaAtual
    ),

    % 2. Percepção de Obstáculos nos arredores imediatos
    direcoes_possiveis(Dirs),
    perceber_obstaculos_locais(PosAtual, Dirs, ObstaculosConhecidos, NovosObstaculosConhecidos),

    format('Posicao atual: ~w | Dica ativa: ~w~n', [PosAtual, DicaEfetiva]),

    % 3. Deliberação e Ação
    (   decidir_passo(PosAtual, DicaEfetiva, Visitados, Pilha, Acao) ->
        (   Acao = avancar(ProximaPos) ->
            format('Avanco: ~w -> ~w~n', [PosAtual, ProximaPos]),
            NovaPilha = [PosAtual|Pilha],
            NovosVisitados = [ProximaPos|Visitados],
            loop_agente(ProximaPos, DicaEfetiva, NovaPilha, NovosVisitados, NovosObstaculosConhecidos)
        ;   Acao = recuar(ProximaPos) ->
            format('Backtrack (recuo): ~w -> ~w~n', [PosAtual, ProximaPos]),
            Pilha = [_|RestoPilha],
            loop_agente(ProximaPos, DicaEfetiva, RestoPilha, Visitados, NovosObstaculosConhecidos)
        )
    ;   format('~nFim da exploracao: agente sem movimentos viaveis.~n')
    ).
