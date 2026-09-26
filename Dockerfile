FROM ocaml/opam:ubuntu-22.04-ocaml-5.5
WORKDIR /workspace
RUN opam install ocamlfind yojson --yes && opam clean --yes
