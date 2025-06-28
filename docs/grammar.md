# YAML Grammar 
<!-- TODO : Maybe write a full EBNF? -->

schema        ::= traits? functions? attributes

traits        ::= "traits:" trait_line+
trait_line    ::= IDENT ":" PREDICATE_SCALAR

functions     ::= "functions:" function_block+
function_block::= IDENT ":" { "method:" IDENT
                              "arguments:" "[" ARG_SCALAR ("," ARG_SCALAR)* "]" }

attributes    ::= "attributes:" attr_line+
attr_line     ::= IDENT ":" (ORIGIN_SCALAR | decision_table)

decision_table_alt ::= "- traits:" trait_ref_list "\n"
                       "  resolver:" ORIGIN_SCALAR
                       ( "- traits:" trait_ref_list "\n"
                         "  resolver:" ORIGIN_SCALAR )+

trait_ref_list::= IDENT ("," IDENT)* |          # empty list  ⇒  default case
