NAME = ft_turing
BC = $(NAME).bc

OCAMLFIND = ocamlfind
PACKAGES = yojson

OPAM_EXEC = opam exec --
OCAMLC = ocamlc
OCAMLOPT = ocamlopt

# Los eventos de linea que necesita el depurador; vacio en el build normal.
DEBUG =

# El compilador empareja un .ml con su .mli SOLO si estan en el mismo directorio:
# con el contrato en inc/ compila el modulo SIN contrato y sin avisar. De ahi
# `-cmi-file` (OCaml >= 5.0) en cada compilacion del .ml.
SRC = $(shell $(OPAM_EXEC) ocamldep -sort -I src -I inc src/*.ml)
OBJ = $(patsubst src/%.ml, obj/%.cmo, $(SRC))
OBJ_NATIVE = $(patsubst src/%.ml, obj/%.cmx, $(SRC))

OBJ_DIR = obj/

CMI = $(patsubst inc/%.mli,obj/%.cmi,$(wildcard inc/*.mli))

# make -j no sabe que un .cmo necesita el .cmi de otro: esto lo serializa.
.NOTPARALLEL:

.PHONY: all
all: $(NAME)

$(NAME): deps $(OBJ)
	$(OPAM_EXEC) $(OCAMLFIND) $(OCAMLC) $(DEBUG) -package $(PACKAGES) -linkpkg $(OBJ) -o $(NAME)

obj/%.cmo: src/%.ml
	@mkdir -p $(@D)
	@if [ -f inc/$*.mli ]; then \
	  $(OPAM_EXEC) $(OCAMLFIND) $(OCAMLC) $(DEBUG) -package $(PACKAGES) -I $(OBJ_DIR) -c inc/$*.mli -o obj/$*.cmi && \
	  $(OPAM_EXEC) $(OCAMLFIND) $(OCAMLC) $(DEBUG) -package $(PACKAGES) -I $(OBJ_DIR) -cmi-file obj/$*.cmi -c $< -o $@; \
	else \
	  $(OPAM_EXEC) $(OCAMLFIND) $(OCAMLC) $(DEBUG) -package $(PACKAGES) -I $(OBJ_DIR) -c $< -o $@; \
	fi

# Editar un .mli tiene que reconstruir tambien su .cmo.
$(patsubst obj/%.cmi,obj/%.cmo,$(CMI)): obj/%.cmo: inc/%.mli

.PHONY: native
native: deps $(OBJ_NATIVE)
	$(OPAM_EXEC) $(OCAMLFIND) $(OCAMLOPT) -package $(PACKAGES) -linkpkg $(OBJ_NATIVE) -o $(NAME)

# El .cmi de un .mli lo produce la regla bytecode: sin compilarlo aqui, un
# `make native` desde limpio se queda sin el.
obj/%.cmx: src/%.ml
	@mkdir -p $(@D)
	@if [ -f inc/$*.mli ]; then \
	  $(OPAM_EXEC) $(OCAMLFIND) $(OCAMLC) $(DEBUG) -package $(PACKAGES) -I $(OBJ_DIR) -c inc/$*.mli -o obj/$*.cmi && \
	  $(OPAM_EXEC) $(OCAMLFIND) $(OCAMLOPT) -package $(PACKAGES) -I $(OBJ_DIR) -cmi-file obj/$*.cmi -c $< -o $@; \
	else \
	  $(OPAM_EXEC) $(OCAMLFIND) $(OCAMLOPT) -package $(PACKAGES) -I $(OBJ_DIR) -c $< -o $@; \
	fi

# Objetos con -g y bytecode aparte ($(BC)), que es lo que lanza el depurador.
.PHONY: debug
debug: fclean
	$(MAKE) DEBUG=-g all
	$(OPAM_EXEC) $(OCAMLFIND) $(OCAMLC) -g -package $(PACKAGES) -linkpkg $(OBJ) -o $(BC)

# -cmi-file necesita OCaml >= 5.0: si el compilador es mas viejo se le pide uno
# nuevo a OPAM (la letra no deja que el evaluador instale nada).
.PHONY: deps
deps:
	@if [ "$(MAKECMDGOALS)" = "native" ]; then \
		command -v ocamlopt >/dev/null 2>&1 || opam install ocaml --yes; \
	else \
		command -v ocamlc >/dev/null 2>&1 || opam install ocaml --yes; \
	fi
	@v=$$($(OPAM_EXEC) ocamlc -version | cut -d. -f1); \
	if [ "$$v" -lt 5 ]; then \
		echo "ocamlc $$v < 5.0: instalando un OCaml nuevo con OPAM (-cmi-file lo necesita)"; \
		opam install ocaml --yes; \
	fi
	opam install $(OCAMLFIND) $(PACKAGES) --yes

.PHONY: clean
clean:
	$(RM) -r obj

.PHONY: fclean
fclean: clean
	$(RM) $(NAME) $(BC)

.PHONY: re
re: fclean
	$(MAKE) all
