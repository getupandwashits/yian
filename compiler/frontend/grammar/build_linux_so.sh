#!/bin/sh
cd cmd/compiler/frontend/grammar
tree-sitter generate
tree-sitter build
# make
cp parser.so ../yian_lang_linux.so