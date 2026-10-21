:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_parameters)).
:- consult('CacaTesouro').

:- http_handler(root(.),        http_reply_from_files(public, []), [prefix]).
:- http_handler(root(api/caca), api_caca, []).

api_caca(Request) :-
    http_parameters(Request, [x(X, [integer, default(8)]),
                              y(Y, [integer, default(8)]),
                              pistas(P, [integer, default(3)]),
                              obstaculos(O, [integer, default(6)])]),
    with_output_to(string(Saida),
                   ( iniciar_caca(X, Y, P, O, pos(1, 1)) -> true ; true )),
    format('Content-type: text/plain; charset=utf-8~n~n~w', [Saida]).

:- initialization((http_server(http_dispatch, [port(8080)]),
                   format('Acesse http://localhost:8080~n'))).
