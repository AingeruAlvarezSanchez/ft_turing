NAME = ft_turing

OCAMLFIND = ocamlfind
PACKAGES = yojson

OPAM_EXEC = opam exec --
OCAMLC = ocamlc
OCAMLOPT = ocamlopt

SRC = $(shell $(OPAM_EXEC) ocamldep -sort -I src src/*.ml)
OBJ = $(patsubst src/%.ml, obj/%.cmo, $(SRC))
OBJ_NATIVE = $(patsubst src/%.ml, obj/%.cmx, $(SRC))

OBJ_DIR = obj/

CMI = $(patsubst src/%.mli,obj/%.cmi,$(wildcard src/*.mli))

.PHONY: all
all: $(NAME)

$(NAME): deps $(OBJ)
	$(OPAM_EXEC) $(OCAMLFIND) $(OCAMLC) -package $(PACKAGES) -linkpkg $(OBJ) -o $(NAME)

obj/%.cmo: src/%.ml
	@mkdir -p $(@D)
	@if [ -f src/$*.mli ]; then \
	  $(OPAM_EXEC) $(OCAMLFIND) $(OCAMLC) -package $(PACKAGES) -I $(OBJ_DIR) -c src/$*.mli -o obj/$*.cmi; \
	fi
	$(OPAM_EXEC) $(OCAMLFIND) $(OCAMLC) -package $(PACKAGES) -I $(OBJ_DIR) -c $< -o $@

# Editar un .mli tambien tiene que reconstruir su .cmo: la receta de arriba no
# lo ve como cambio de $< (el .ml no ha cambiado), y sin esta linea te quedas
# con un .cmi nuevo y un .cmo viejo enlazados juntos.
$(patsubst src/%.mli,obj/%.cmo,$(CMI)): obj/%.cmo: src/%.mli

.PHONY: native
native: deps $(OBJ_NATIVE)
	$(OPAM_EXEC) $(OCAMLFIND) $(OCAMLOPT) -package $(PACKAGES) -linkpkg $(OBJ_NATIVE) -o $(NAME)

obj/%.cmx: src/%.ml
	mkdir -p $(@D)
	$(OPAM_EXEC) $(OCAMLFIND) $(OCAMLOPT) -package $(PACKAGES) -I $(OBJ_DIR) -c $< -o $@

.PHONY: deps
deps:
	@if [ "$(MAKECMDGOALS)" = "native" ]; then \
		command -v ocamlopt >/dev/null 2>&1 || opam install ocaml --yes; \
	else \
		command -v ocamlc >/dev/null 2>&1 || opam install ocaml --yes; \
	fi
	opam install $(OCAMLFIND) $(PACKAGES) --yes

.PHONY: clean
clean:
	$(RM) -r obj

.PHONY: fclean
fclean: clean
	$(RM) $(NAME)

.PHONY: re
re: fclean
	$(MAKE) all