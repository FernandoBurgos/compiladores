# This is a .y grammar file for my Baby Duck language parsing to ruby.

class BabyDuck
  prechigh
    # nonassoc UMINUS
    left '*' '/'
    left '+' '-'
  preclow
rule
  target: program

  # main program structure
  program: 'program' ID ';' {
      # Initialize the symbol tables
      @current_scope = 'global'
      @symbol_tables = { 'global' => {} }
      @current_function = nil
    }
    vars funcs 'main' {
      @current_scope = 'main'
      @symbol_tables['main'] = {}
    }
    body 'end' { 
      puts "Codigo compilado correctamente"
      result = val[1]
    }

  # vars definition
  vars: varsdec | /* epsilon */
  varsdec: 'var' varlist
  varlist: varsids ':' type ';' {
      # Add all variables of this type to the current scope
      puts "Received type: #{@var_type}"
      @current_vars.each do |var_name|
        if @symbol_tables[@current_scope][var_name]
          raise SemanticError, "Variable decalration: Variable '#{var_name}' already declared in scope '#{@current_scope}'"
        else
          @symbol_tables[@current_scope][var_name] = {type: @var_type, value: nil}
          puts "Added variable '#{var_name}' of type '#{@var_type}' to scope '#{@current_scope}'"
        end
      end
    } 
    varlist | /* epsilon */
  varsids: ID {
      @current_vars = [val[0]]
    } 
    | ID ',' {
      @current_vars = [val[0]]
    } 
    varsids {
      @current_vars.unshift(val[0])
    }
  type: 'int' { 
    @var_type = 'int'
    result = 'int'
  } 
  | 'float' { 
    @var_type = 'float'
    result = 'float'
  }

  # functions definition
  funcs: funcsdec | /* epsilon */
  funcsdec: func_header '(' funcvars ')' '[' vars body ']' ';' {
    # Return to global scope after function definition
    @current_scope = 'global'
    @current_function = nil
  } 
  funcs

  func_header: 'void' ID {    
    # Store function name
    @current_function = val[1]
    @current_scope = val[1]
    @symbol_tables[@current_scope] = {}
    puts "Created new function scope: #{@current_scope}"
    
    # Return the function name for potential use in parent rule
    result = val[1]
  }
  funcvars: funcvarsdec | /* epsilon */
  funcvarsdec: param_declaration funcvarsdeclist

  param_declaration: ID ':' type {
    
    var_name = val[0]
    
    if @symbol_tables[@current_scope][var_name]
      raise SemanticError, "Parameter declaration: Parameter '#{var_name}' already declared in function '#{@current_scope}'"
    else
      @symbol_tables[@current_scope][var_name] = {type: val[2], is_param: true, position: @current_param_count}
      @current_param_count += 1
      puts "Added parameter '#{var_name}' of type '#{val[2]}' to function '#{@current_scope}'"
    end
    
    # Return the parameter name for potential use in parent rule
    result = var_name
  }

  funcvarsdeclist: ',' funcvarsdec | /* epsilon */

  # body of the main program or function
  body: '{' statement '}'

  # statement list
  statement: statedec | /* epsilon */
  statedec: statevalues | statevalues statement
  statevalues: assign | condition | cycle | fcall | printstat

  # assignment statement
  assign: ID '=' expression ';' {
      puts "Assigned value: #{val[2]} to variable: #{val[0]}"
      # Check if variable exists in current scope or global scope
      var_name = val[0]
      if !variable_exists(var_name)
        raise SemanticError, "Assignment: Variable '#{var_name}' not declared before use"
      end
      resultingType = val[2][:type]
      # Check if the types are compatible
      if evaluate_expression_types(get_variable_type(var_name), resultingType) == 'error'
        raise SemanticError, "Assignment: Type mismatch in assignment to variable '#{var_name}'"
      end
      # Set the variable value
      set_variable_value(var_name, val[2][:value])
    }

  # Expression hierarchy
  expression: exp { 
    result = val[0]  # Pass up the exp value
  } 
  | exp operator exp { 
    left = val[0]
    op = val[1]
    right = val[2]
    puts "DEBUG: Expression with operator: left: #{left} op: #{op} right: #{right}"
    # Here you might evaluate the expression or build a node
    result = { left: left, operator: op, right: right }
  }

  operator: '>' { result = '>' } 
  | '<' { result = '<' } 
  | '!=' { result = '!=' }

  exp: term termlist { 
    if val[1].nil? || val[1].empty?  # No operations in termlist
      result = val[0]  # Just pass up the term value
    else
      # Handle operations from termlist
      term = val[0]
      ops = val[1]
      puts "DEBUG: Exp with termlist: #{term} #{ops}"
      
      resultingType = evaluate_expression_types(term[:type], ops[:type])
        # Check if the types are compatible
        if resultingType == 'error'
          raise SemanticError, "Assignment: Type mismatch in assignment to variable '#{var_name}'"
        end

      result = { name: 'Evalresult', type: resultingType, value: evaluate_operation(term[:value], ops[:operator], ops[:value]) }
    end
  }

  termlist: termop exp { 
    result = { operator: val[0], name: val[1][:name], type: val[1][:type], value: val[1][:value] }
  } 
  | /* epsilon */ { 
    result = nil  # No operations
  }

  termop: '+' { result = '+' } 
  | '-' { result = '-' }

  term: factor factorlist { 
    if val[1].nil? || val[1].empty?  # No operations in factorlist
      result = val[0]  # Just pass up the factor value
    else
      # Handle operations from factorlist
      factor = val[0]
      ops = val[1]
      puts "DEBUG: Term with factorlist: #{factor} #{ops}"

      resultingType = evaluate_expression_types(factor[:type], ops[:type])
        # Check if the types are compatible
        if resultingType == 'error'
          raise SemanticError, "Assignment: Type mismatch in assignment to variable '#{var_name}'"
        end

      result = { name: 'Evalresult', type: resultingType, value: evaluate_operation(factor[:value], ops[:operator], ops[:value]) }
    end
  }

  factorlist: factorop term { 
    result = { operator: val[0], name: val[1][:name], type: val[1][:type], value: val[1][:value] }
  } 
  | /* epsilon */ { 
    result = nil  # No operations
  }

  factorop: '*' { result = '*' } 
  | '/' { result = '/' }

  factor: '(' expression ')' { 
    result = val[1]  # Return the expression inside parentheses
  } 
  | factorids { 
    result = val[0]  # Pass up the factorids value
  }

  factorids: expop expids { 
    if val[0].nil? || val[0].empty?  # No operator
      result = val[1]  # Just pass up the expids value
    else
      # Apply unary operator
      op = val[0]
      value = val[1]
      puts "DEBUG: Factorids with expop: #{op} #{value}"
      result = { operator: op, value: value }
    end
  }

  expop: termop { 
    result = val[0]  # Pass up the termop value
  } 
  | /* epsilon */ { 
    result = nil  # No operator
  }

  expids: ID {
    # Check if variable exists when used in expression
    var_name = val[0]
    if !variable_exists(var_name)
      raise SemanticError, "Expression: Variable '#{var_name}' not declared before use"
    end
    var_type = get_variable_type(var_name)
    var_value = get_variable_value(var_name)
    result = { name: var_name, type: var_type, value: var_value }
  } 
  | const { 
    result = val[0]  # Pass up the const value
  }

  const: CTE_INT { 
    result = {name: 'int const', value: val[0], type: 'int' }
  } 
  | CTE_FLOAT { 
    result = { name: 'float const', value: val[0], type: 'float' }
  }

  # condition statement
  condition: 'if' '(' expression ')' body optionalelse ';'
  optionalelse: 'else' body | /* epsilon */

  # cycle statement
  cycle: 'while' '(' expression ')' 'do' body ';'

  # function call statement
  fcall: function_id '(' funccallexp ')' ';' {
    # Reset function calling state
    @calling_function = nil
    result = val[0]  # Return the function ID from function_id rule
  }

  function_id: ID {
    func_name = val[0]
    
    # Check if function exists
    if !@symbol_tables[func_name]
      raise SemanticError, "Function call: Function '#{func_name}' not declared before use"
    end
    
    # Set up function call state
    @current_param_count = 0
    @calling_function = func_name
    
    # Return the function name for use in parent rule
    result = func_name
  }
  funccallexp: funcexplist | /* epsilon */

  funcexplist: single_param | single_param_comma funccallexp

  single_param: expression {
    @current_param_count += 1
    result = val[0]  # Return the expression value
  }

  single_param_comma: expression ',' {
    @current_param_count += 1
    result = val[0]  # Return the expression value
  }

  #print statement
  printstat: 'print' '(' printexplist ')' ';' { result = val[2]; puts "printed #{val[2]}" }
  printexplist: printvalue { result = val[0] } | printvalue { result = val[0] } ',' printexplist
  printvalue: expression { result = val[0] } | CTE_STRING { result = val[0] } # Pass up the string value
  
end

# end of the grammar

---- header

class SemanticError < StandardError; end

---- inner
def parse(str)
  # Initialize semantic analysis variables
  @symbol_tables = {}
  @current_scope = nil
  @current_function = nil
  @current_vars = []
  @current_position = 0
  @var_type = nil
  @calling_function = nil
  @current_param_count = 0

  @semantic_Cube = {
    'int' => {
      'int' => 'int',
      'float' => 'float',
      'string' => 'error'
    },
    'float' => {
      'int' => 'float',
      'float' => 'float',
      'string' => 'error'
    },
    'string' => {
      'int' => 'error',
      'float' => 'error',
      'string' => 'string'
    }
  }

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
    when /\A(==|!=|<=|>=|<|>)/o
      #operadores de comparación
      @q.push [$&, $&]
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

# Helper function to check if a variable exists in current scope or global scope
def variable_exists(var_name)
  # Check current scope first
  return true if @symbol_tables[@current_scope] && @symbol_tables[@current_scope][var_name]
  
  # Check global scope if we're not already in it
  return true if @current_scope != 'global' && @symbol_tables['global'][var_name]
  
  # Variable not found
  false
end

# Helper function to get variable type
def get_variable_type(var_name)
  # Check current scope first
  if @symbol_tables[@current_scope] && @symbol_tables[@current_scope][var_name]
    return @symbol_tables[@current_scope][var_name][:type]
  end
  
  # Check global scope if we're not already in it
  if @current_scope != 'global' && @symbol_tables['global'][var_name]
    return @symbol_tables['global'][var_name][:type]
  end
  
  # Variable not found
  nil
end

def get_variable_value(var_name)
  # Check current scope first
  if @symbol_tables[@current_scope] && @symbol_tables[@current_scope][var_name]
    return @symbol_tables[@current_scope][var_name][:value]
  end
  
  # Check global scope if we're not already in it
  if @current_scope != 'global' && @symbol_tables['global'][var_name]
    return @symbol_tables['global'][var_name][:value]
  end
  
  # Variable not found
  nil
end

def set_variable_value(var_name, value)
  # Check current scope first
  if @symbol_tables[@current_scope] && @symbol_tables[@current_scope][var_name]
    @symbol_tables[@current_scope][var_name][:value] = value
  end
  
  # Check global scope if we're not already in it
  if @current_scope != 'global' && @symbol_tables['global'][var_name]
    @symbol_tables['global'][var_name][:value] = value
  end
  
  # Variable not found
  nil
end

# Helper to print the symbol table (for debugging)
def print_symbol_tables
  puts "\n==== SYMBOL TABLES ===="
  @symbol_tables.each do |scope, vars|
    puts "SCOPE: #{scope}"
    vars.each do |var_name, details|
      puts "  #{var_name}: #{details}"
    end
    puts ""
  end
  puts "======================="
end

# Helper to evaluate expressions
def evaluate_expression_types(type1, type2)
  if @semantic_Cube[type1] && @semantic_Cube[type1][type2]
    return @semantic_Cube[type1][type2]
  end
  return 'error'
end

def evaluate_operation(left, op, right)
  puts "DEBUG: Evaluating operation: #{left} #{op} #{right}"
  case op
  when '+'
    return left + right
  when '-'
    return left - right
  when '*'
    return left * right
  when '/'
    return left / right
  when '>'
    return left > right ? 1 : 0
  when '<'
    return left < right ? 1 : 0
  when '!='
    return left != right ? 1 : 0
  end
end

---- footer

if $0 == __FILE__
  parser = BabyDuck.new
  # Código para probar tu parser

  if ARGV[0]
    input = File.read(ARGV[0])
    begin
      result = parser.parse(input)
      # Print symbol tables for debugging
      parser.print_symbol_tables
      puts "Análisis exitoso: #{result}"
    rescue SemanticError => e
      puts "Error: #{e.message}"
    end
  end
end