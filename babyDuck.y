# This is a .y grammar file for my Baby Duck language parsing to ruby.

class BabyDuck
  #prechigh
    # nonassoc UMINUS
    # left '*' '/'
    # left '+' '-'
  #preclow
rule
  target: program

  # main program structure
  program: 'program' ID ';' vars funcs 'main' body 'end' { 
    puts "Codigo compilado correctamente"
    result = val[1]
    }

  # vars definition
  vars: varsdec | /* epsilon */
  varsdec: 'var' varlist
  varlist: varsids ':' type ';' varlist | /* epsilon */
  varsids: ID | ID ',' varsids
  type: 'int' | 'float'

  # functions definition
  funcs: funcsdec | /* epsilon */
  funcsdec: 'void' ID '(' funcvars ')' '[' vars body ']' ';' funcs
  funcvars: funcvarsdec | /* epsilon */
  funcvarsdec: ID ':' type funcvarsdeclist
  funcvarsdeclist: ',' funcvarsdec | /* epsilon */

  # body of the main program or function
  body: '{' statement '}'

  # statement list
  statement: statedec | /* epsilon */
  statedec: statevalues | statevalues statement
  statevalues: assign | condition | cycle | fcall | printstat

  # assignment statement
  assign: ID '=' expression ';'
  expression: exp | exp operator exp
  operator: '>' | '<' | '!='
  exp: term termlist
  termlist: termop exp | /* epsilon */
  termop: '+' | '-'
  term: factor factorlist
  factorlist: factorop term | /* epsilon */
  factorop: '*' | '/'
  factor: '(' expression ')' | factorids
  factorids: expop expids
  expop: termop | /* epsilon */
  expids: ID | const
  const: CTE_INT | CTE_FLOAT

  # condition statement
  condition: 'if' '(' expression ')' body optionalelse ';'
  optionalelse: 'else' body | /* epsilon */

  # cycle statement
  cycle: 'while' '(' expression ')' 'do' body ';'

  # function call statement
  fcall: ID '(' funccallexp ')' ';'
  funccallexp: funcexplist | /* epsilon */
  funcexplist: expression | expression ',' funccallexp

  #print statement
  printstat: 'print' '(' printexplist ')' ';'
  printexplist: printvalue | printvalue ',' printexplist
  printvalue: expression | CTE_STRING
  
end

# end of the grammar

---- header


# variables dictionary

#

---- inner
def parse(str)
  @q = []
  until str.empty?
    case str
    when /\A\s+/
      # Ignora los espacios en blanco
    when /\A(program|main|end|var|void|if|else|while|do|print|int|float)\b/
      # Palabras clave reservadas - devuelve el token como su propio nombre
      @q.push [$&, $&]
    when /\A[a-zA-Z][a-zA-Z0-9_]*/
      # Identificador
      @q.push [:ID, $&]
    when /\A[0-9]+\.[0-9]+/
      # Constante flotante
      @q.push [:CTE_FLOAT, $&.to_f]
    when /\A[0-9]+/
      # Constante entera
      @q.push [:CTE_INT, $&.to_i]
    when /\A\"[^\"]*\"/
      # Constante string (incluyendo las comillas)
      @q.push [:CTE_STRING, $&[1...-1]] # Eliminamos las comillas
    when /\A.|\n/o
      # Cualquier otro carácter (operadores, paréntesis, etc.)
      s = $&
      @q.push [s, s]
    end
    str = $'
  end
  @q.push [false, '$end']
  do_parse
end

def next_token
  @q.shift
end

---- footer

if $0 == __FILE__
  parser = BabyDuck.new
  # Código para probar tu parser

  if ARGV[0]
    input = File.read(ARGV[0])
    begin
      result = parser.parse(input)
      puts "Análisis exitoso: #{result}"
    rescue => e
      puts "Error: #{e.message}"
    end
  end
end