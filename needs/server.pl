:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_cors)).
:- use_module(library(http/http_files)).

:- http_handler(root(.), http_reply_file('needs.html', []), [priority(10)]).
:- http_handler(root('needs.html'), http_reply_file('needs.html', []), [priority(10)]).
:- http_handler(root('needs.css'), http_reply_file('needs.css', []), [priority(20)]).
:- http_handler(root('needs.js'), http_reply_file('needs.js', []), [priority(20)]).
:- http_handler(root(api/test), handle_test, []).
:- http_handler(root(api/recommendations), handle_recommendations, [methods([post, options])]).
:- http_handler(root(api/places), handle_all_places, [methods([get, options])]).

% Places
place('paoay-church', 'Paoay Church', ['shaded', 'minimal-walking', 'wheelchair-friendly', 'step-free-access']).
place('sinking-bell-tower', 'Sinking Bell Tower', ['minimal-walking', 'shaded']).
place('malacanang-north', 'Malacanang of the North', ['wheelchair-friendly', 'minimal-walking', 'shaded', 'step-free-access', 'accessible-restrooms', 'handrails']).
place('bangui-windmills', 'Bangui Windmills', ['minimal-walking', 'shaded']).
place('museo-ilocos', 'Museo Ilocos Norte', ['wheelchair-friendly', 'minimal-walking', 'shaded', 'quiet-space', 'braille-paths', 'step-free-access', 'accessible-restrooms', 'handrails']).
place('laoag-city-hall', 'Laoag City Hall Area', ['minimal-walking', 'shaded', 'wheelchair-friendly', 'step-free-access', 'accessible-restrooms', 'handrails']).
place('currimao-lighthouse', 'Currimao Lighthouse', ['minimal-walking', 'shaded']).
place('paraiso-ni-anton', 'Paraiso ni Anton', ['minimal-walking', 'shaded']).
place('saud-beach', 'Saud Beach', ['wheelchair-friendly', 'minimal-walking', 'shaded', 'step-free-access']).
place('pagudpud-rest-area', 'Pagudpud Tourist Rest Area', ['wheelchair-friendly', 'shaded', 'minimal-walking', 'step-free-access', 'accessible-restrooms']).
place('laoag-cathedral', 'Laoag Cathedral', ['minimal-walking', 'shaded', 'wheelchair-friendly', 'step-free-access']).
place('st-williams-cathedral', 'St. William\'s Cathedral Area', ['wheelchair-friendly', 'minimal-walking', 'shaded', 'step-free-access']).
place('paoay-lake-viewpoint', 'Paoay Lake Viewpoint', ['minimal-walking', 'shaded']).
place('badoc-gateway', 'Badoc Gateway', ['wheelchair-friendly', 'shaded', 'minimal-walking', 'step-free-access']).
place('pasuquin-salt-farms', 'Pasuquin Salt Farms Viewpoint', ['minimal-walking', 'shaded']).
place('blue-lagoon', 'Blue Lagoon Pagudpud', ['wheelchair-friendly', 'minimal-walking', 'shaded', 'step-free-access']).
place('casa-consuelo', 'Casa Consuelo Resort', ['wheelchair-friendly', 'shaded', 'minimal-walking', 'step-free-access', 'accessible-restrooms']).
place('nueva-era-eco-park', 'Nueva Era Eco Park', ['wheelchair-friendly', 'shaded', 'minimal-walking', 'step-free-access', 'accessible-restrooms']).
place('juan-luna-shrine', 'Juan Luna Shrine', ['minimal-walking', 'shaded']).
place('fort-ilocandia', 'Fort Ilocandia', ['wheelchair-friendly', 'shaded', 'minimal-walking', 'step-free-access', 'accessible-restrooms']).
place('patapat-viaduct', 'Patapat Viaduct (viewpoint)', ['minimal-walking', 'shaded']).
place('dmmsu-glass-garden', 'DMMSU Glass Garden', ['wheelchair-friendly', 'shaded', 'minimal-walking', 'step-free-access', 'accessible-restrooms']).
place('fantasy-world', 'Fantasy World Indoor Playground', ['wheelchair-friendly', 'shaded', 'minimal-walking', 'step-free-access', 'accessible-restrooms']).
place('batac-riverside', 'Batac Riverside Park', ['shaded', 'minimal-walking']).
place('marcos-museum', 'Marcos Museum and Mausoleum', ['wheelchair-friendly', 'minimal-walking', 'shaded', 'quiet-space', 'braille-paths', 'step-free-access', 'accessible-restrooms', 'handrails']).
place('capitol-grounds', 'Ilocos Norte Capitol Grounds', ['minimal-walking', 'shaded', 'wheelchair-friendly', 'step-free-access', 'accessible-restrooms']).
place('baluarte-chavit', 'Baluarte ni Chavit (nearby access)', ['wheelchair-friendly', 'shaded', 'step-free-access']).
place('hannahs-beach', 'Hannah\'s Beach Resort', ['wheelchair-friendly', 'minimal-walking', 'shaded', 'step-free-access', 'accessible-restrooms']).
place('laoag-sand-dunes', 'Laoag Sand Dunes (edge viewpoint)', ['minimal-walking', 'shaded']).
place('suso-beach', 'Suso Beach', ['minimal-walking', 'shaded']).

% Convert needs to atoms
to_atom(X, X) :- atom(X), !.
to_atom(X, A) :- string(X), !, atom_string(A, X).
to_atom(X, X).

% Find recommendations - ONLY complete matches
find_recommendations(NeedsIn, Results) :-
    maplist(to_atom, NeedsIn, Needs),
    length(Needs, RequiredMatches),
    findall(
        place_result(ID, Name, Tags, M),
        (
            place(ID, Name, Tags),
            count_matches(Needs, Tags, M),
            M =:= RequiredMatches
        ),
        Results
    ),
    sort(4, @>=, Results, _).

% Count matches
count_matches([], _, 0).
count_matches([H|T], Tags, N) :-
    count_matches(T, Tags, N1),
    (member(H, Tags) -> N is N1 + 1 ; N = N1).

% Get all places
get_all_places(Places) :-
    findall(place_result(ID, Name, Tags, 0), place(ID, Name, Tags), Places).

% Test handler
handle_test(_) :-
    reply_json(json([status='ok', message='Working!', places=30])).

% Recommendations handler
handle_recommendations(Req) :-
    cors_enable(Req, [methods([post, options])]),
    (   memberchk(method(options), Req)
    ->  true
    ;   http_read_json_dict(Req, Q, []),
        Needs = Q.get(needs),
        find_recommendations(Needs, Recs),
        length(Recs, C),
        maplist(place_to_json, Recs, RecJson),
        reply_json(json([success=true, count=C, needs=Needs, recommendations=RecJson]))
    ).

% Convert place result to JSON
place_to_json(place_result(ID, Name, Tags, Matches), 
              json([id=ID, name=Name, tags=Tags, matches=Matches])).

% All places handler
handle_all_places(Req) :-
    cors_enable(Req, [methods([get, options])]),
    (   memberchk(method(options), Req)
    ->  true
    ;   get_all_places(P),
        length(P, C),
        maplist(place_to_json, P, PlacesJson),
        reply_json(json([success=true, count=C, places=PlacesJson]))
    ).

% Start server
start :-
    http_server(http_dispatch, [port(8080)]),
    format('~n====================================~n'),
    format('SERVER RUNNING ON PORT 8080~n'),
    format('http://localhost:8080~n'),
    format('30 places loaded~n'),
    format('====================================~n~n'),
    thread_get_message(_).

:- initialization(start).