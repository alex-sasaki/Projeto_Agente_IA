% CAÇA AO TESOURO POR DICAS

:- dynamic(tamanho_grid/2).
:- dynamic(item_em/2).          % item_em(pos(X, Y), TipoItem)
:- dynamic(conteudo_dica/2).    % conteudo_dica(Id, direcao(Dir))

% 1. Dedução de Direção Qualitativa entre Dois Pontos
% Calcula qual direção cardinal básica aponta da PosOrigem para a PosDestino
calcular_dica(pos(X, Y1), pos(X, Y2), direcao(norte)) :- Y2 > Y1, !.
calcular_dica(pos(X, Y1), pos(X, Y2), direcao(sul))   :- Y2 < Y1, !.
calcular_dica(pos(X1, _), pos(X2, _), direcao(leste)) :- X2 > X1, !.
calcular_dica(pos(X1, _), pos(X2, _), direcao(oeste)) :- X2 < X1, !.
% Para nós em diagonal, prioriza a maior diferença ortogonal:
calcular_dica(pos(X1, Y1), pos(X2, Y2), direcao(Dir)) :-
    DX is abs(X2 - X1),
    DY is abs(Y2 - Y1),
    (   DY >= DX ->
        ( Y2 > Y1 -> Dir = norte ; Dir = sul )
    ;   ( X2 > X1 -> Dir = leste ; Dir = oeste )
    ).

% 2. Geração Aleatória do Cenário e Encadeamento de Pistas
% gerar_cenario_aleatorio(+MaxX, +MaxY, +NumPistas, +PosInicial, -DicaInicial)
gerar_cenario_aleatorio(MaxX, MaxY, NumPistas, PosInicial, DicaInicial) :-
    retractall(tamanho_grid(_, _)),
    retractall(item_em(_, _)),
    retractall(conteudo_dica(_, _)),
    
    assertz(tamanho_grid(MaxX, MaxY)),

    % Gera todas as células do grid exceto a posição inicial
    findall(pos(X, Y),
        ( between(1, MaxX, X),
          between(1, MaxY, Y),
          pos(X, Y) \= PosInicial ),
        TodasPosicoes),
    
    % Embaralha a lista aleatoriamente
    random_permutation(TodasPosicoes, Embaralhadas),
    
    % Seleciona N posições para as pistas e 1 para o tesouro
    QtdTotal is NumPistas + 1,
    length(LocaisEscolhidos, QtdTotal),
    append(LocaisEscolhidos, _, Embaralhadas),
    
    LocaisEscolhidos = [PrimeiraPista|_],
    % A dica de início do agente deve apontar coerentemente para a 1ª pista
    calcular_dica(PosInicial, PrimeiraPista, DicaInicial),
    
    % Encadeia recursivamente as pistas e o tesouro final
    encadear_itens(1, LocaisEscolhidos).

% Caso recursivo: Pista atual aponta para a próxima localização
encadear_itens(Id, [PosAtual, ProxPos | Resto]) :-
    !,
    calcular_dica(PosAtual, ProxPos, Dica),
    assertz(item_em(PosAtual, pista(Id))),
    assertz(conteudo_dica(Id, Dica)),
    format('[CONFIG] Pista ~w sorteada em ~w -> Aponta para: ~w~n', [Id, PosAtual, Dica]),
    ProxId is Id + 1,
    encadear_itens(ProxId, [ProxPos | Resto]).

% Caso base: O último item da lista é o Tesouro
encadear_itens(_, [PosTesouro]) :-
    assertz(item_em(PosTesouro, tesouro)),
    format('[CONFIG] Tesouro sorteado em ~w~n~n', [PosTesouro]).


% 3. Topologia do Grid (Movimentos Ortogonais)
deslocamentos([pos(0, 1), pos(0, -1), pos(1, 0), pos(-1, 0)]).

vizinho_valido(pos(X, Y), pos(NX, NY)) :-
    deslocamentos(Offsets),
    member(pos(DX, DY), Offsets),
    NX is X + DX,
    NY is Y + DY,
    tamanho_grid(MaxX, MaxY),
    NX >= 1, NX =< MaxX,
    NY >= 1, NY =< MaxY.


% 4. Sensores
perceber_tesouro(Pos) :- item_em(Pos, tesouro).
perceber_pista(Pos, Id, Dica) :- item_em(Pos, pista(Id)), conteudo_dica(Id, Dica).


% 5. Orientação Qualitativa
satisfaz_dica(pos(_, Y1), pos(_, Y2), direcao(norte)) :- Y2 > Y1.
satisfaz_dica(pos(_, Y1), pos(_, Y2), direcao(sul))   :- Y2 < Y1.
satisfaz_dica(pos(X1, _), pos(X2, _), direcao(leste)) :- X2 > X1.
satisfaz_dica(pos(X1, _), pos(X2, _), direcao(oeste)) :- X2 < X1.


% 6. BFS Recursiva para Explorar Células Inexploradas
busca_fronteira(Origem, TipoMeta, VisitadosMundo, Caminho) :-
    bfs_fila([[Origem]], [Origem], TipoMeta, VisitadosMundo, CaminhoRev),
    reverse(CaminhoRev, Caminho).

bfs_fila([[Atual|Trajeto]|_], _, TipoMeta, VisitadosMundo, [Atual|Trajeto]) :-
    Trajeto \= [],
    meta_alcancada(Atual, TipoMeta, VisitadosMundo), !.

bfs_fila([[Atual|Trajeto]|RestoFila], VisitadosBFS, TipoMeta, VisitadosMundo, Solucao) :-
    findall(Viz,
        ( vizinho_valido(Atual, Viz),
          \+ member(Viz, VisitadosBFS) ),
        VizinhosValidos),
    append(VisitadosBFS, VizinhosValidos, NovosVisitadosBFS),
    gerar_extensoes(VizinhosValidos, [Atual|Trajeto], NovosCaminhos),
    append(RestoFila, NovosCaminhos, FilaAtualizada),
    bfs_fila(FilaAtualizada, NovosVisitadosBFS, TipoMeta, VisitadosMundo, Solucao).

gerar_extensoes([], _, []).
gerar_extensoes([V|Vs], Trajeto, [[V|Trajeto]|Resto]) :-
    gerar_extensoes(Vs, Trajeto, Resto).

meta_alcancada(Pos, com_dica(Origem, Dica), VisitadosMundo) :-
    \+ member(Pos, VisitadosMundo),
    satisfaz_dica(Origem, Pos, Dica).

meta_alcancada(Pos, qualquer_inexplorada, VisitadosMundo) :-
    \+ member(Pos, VisitadosMundo).


% 7. Decisão de Ação
decidir_proximo_passo(PosAtual, Dica, VisitadosMundo, Prox) :-
    vizinho_valido(PosAtual, Prox),
    \+ member(Prox, VisitadosMundo),
    satisfaz_dica(PosAtual, Prox, Dica), !.

decidir_proximo_passo(PosAtual, Dica, VisitadosMundo, Prox) :-
    busca_fronteira(PosAtual, com_dica(PosAtual, Dica), VisitadosMundo, [PosAtual, Prox|_]), !.

decidir_proximo_passo(PosAtual, _, VisitadosMundo, Prox) :-
    busca_fronteira(PosAtual, qualquer_inexplorada, VisitadosMundo, [PosAtual, Prox|_]), !.


% 8. Ciclo de Execução Principal
% iniciar_caca(+MaxX, +MaxY, +NumPistas, +PosInicial)
iniciar_caca(MaxX, MaxY, NumPistas, PosInicial) :-
    % Validação de segurança do tamanho do mapa
    Capacidade is (MaxX * MaxY) - 1,
    (   NumPistas + 1 > Capacidade ->
        format('Erro: O grid ~wx~w nao suporta ~w pistas + tesouro.~n', [MaxX, MaxY, NumPistas]),
        fail
    ;   true
    ),
    gerar_cenario_aleatorio(MaxX, MaxY, NumPistas, PosInicial, DicaInicial),
    format('--- Grid ~wx~w Inicializado com ~w Pistas Aleatorias ---~n', [MaxX, MaxY, NumPistas]),
    format('Agente iniciando em ~w orientado para: ~w~n~n', [PosInicial, DicaInicial]),
    loop_agente(PosInicial, DicaInicial, []).

% Encerramento: Tesouro encontrado
loop_agente(Pos, _, _) :-
    perceber_tesouro(Pos),
    !,
    format('Posicao atual: ~w~n', [Pos]),
    format('Sucesso! O tesouro foi localizado em ~w!~n', [Pos]).

% Ciclo iterativo recursivo
loop_agente(PosAtual, DicaAtual, Visitados) :-
    (   perceber_pista(PosAtual, Id, NovaDica) ->
        format('>> [PERCEPCAO] Pista ~w encontrada em ~w! Nova dica: ~w~n', [Id, PosAtual, NovaDica]),
        DicaEfetiva = NovaDica
    ;   DicaEfetiva = DicaAtual
    ),
    
    format('Posicao atual: ~w | Dica ativa: ~w~n', [PosAtual, DicaEfetiva]),
    NovoHistorico = [PosAtual|Visitados],

    (   decidir_proximo_passo(PosAtual, DicaEfetiva, NovoHistorico, ProximaPos) ->
        format('Movimento: ~w -> ~w~n', [PosAtual, ProximaPos]),
        loop_agente(ProximaPos, DicaEfetiva, NovoHistorico)
    ;   format('~nFim da exploracao: todas as celulas acessiveis foram visitadas.~n')
    ).