# This is a .y grammar file for my Baby Duck language parsing to ruby.

class BabyDuck
  prechigh
    # nonassoc UMINUS
    left '*' '/'
    left '+' '-'
    left '>' '<' '!='
  preclow
rule
  target: program

  # main program structure
  program: 'program' ID ';' {
      # Initialize the symbol tables
      @current_scope = 'global'
      @symbol_tables = { 'global' => {} }
      @current_function = nil
      generate_goto
    }
    vars funcs 'main' {
      @current_scope = 'main'
      @symbol_tables['main'] = {}
      mainStart = @jump_stack.pop
      # Fill the GOTO with the start of the main function
      fill_goto(mainStart, @cuadruples.length + 1)
    }
    body 'end' { 
      puts "Codigo compilado correctamente"
      result = val[1]
    }

  # vars definition
  vars: varsdec | /* opcional */
  varsdec: 'var' varlist
  varlist: varsids ':' type ';' {
      # Add all variables of this type to the current scope
      puts "Received type: #{@var_type}"
      @current_vars.each do |var_name|
        if @symbol_tables[@current_scope][var_name]
          raise SemanticError, "Variable decalration: Variable '#{var_name}' already declared in scope '#{@current_scope}'"
        else
          scope = @current_scope == 'global' ? 'global' : 'local'
          @symbol_tables[@current_scope][var_name] = {type: @var_type, offset: new_memory_offset(@var_type, scope)}
          puts "Added variable '#{var_name}' of type '#{@var_type}' to scope '#{@current_scope}'"
          if @current_function
            @symbol_tables[@current_function]['MetaData'][:resources][@resourceIndex[@var_type]] += 1
          end
        end
      end
    } 
    varlist | /* opcional */
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
  funcs: funcsdec | /* opcional */
  funcsdec: func_header '(' funcvars ')' '[' vars body ']' ';' {
    create_cuadruple('ENDFUNC', nil, nil, nil)
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
    # Initialize function symbol table
    @symbol_tables[@current_scope]['MetaData'] = {
      name: val[1],
      type: 'void',
      funcStart: @cuadruples.length + 1,
      params: 0,
      paramsOrder: [],
      resources: Array.new(@resourceIndex.keys.length, 0)
    }
    puts "Created new function scope: #{@current_scope}"
    
    # Return the function name for potential use in parent rule
    result = val[1]
  }
  funcvars: funcvarsdec | /* opcional */
  funcvarsdec: param_declaration funcvarsdeclist

  param_declaration: ID ':' type {
    
    var_name = val[0]
    
    if @symbol_tables[@current_scope][var_name]
      raise SemanticError, "Parameter declaration: Parameter '#{var_name}' already declared in function '#{@current_scope}'"
    else
      @symbol_tables[@current_scope][var_name] = {type: val[2], offset: new_memory_offset(val[2], 'local'), is_param: true}
      if @current_function
        @symbol_tables[@current_scope]['MetaData'][:paramsOrder].push(var_name)
        @symbol_tables[@current_scope]['MetaData'][:params] += 1
        @symbol_tables[@current_scope]['MetaData'][:resources][@resourceIndex[val[2]]] += 1
      end
      puts "Added parameter '#{var_name}' of type '#{val[2]}' to function '#{@current_scope}'"
    end
    
    # Return the parameter name for potential use in parent rule
    result = var_name
  }

  funcvarsdeclist: ',' funcvarsdec | /* opcional */

  # body of the main program or function
  body: '{' statement '}'

  # statement list
  statement: statedec | /* opcional */
  statedec: statevalues | statevalues statement
  statevalues: assign | condition | cycle | fcall | printstat

  # assignment statement
  assign: ID '=' expression ';' {
      var_name = val[0]
      # Check if variable exists in current scope or global scope
      if !variable_exists(var_name)
        raise SemanticError, "Assignment: Variable '#{var_name}' not declared before use"
      end
      puts "Assigned value to variable: #{val[0]}"
      var_offset = get_variable_data(var_name)[:offset]

      resultingType = evaluate_expression_types(get_variable_data(var_name)[:type], val[2][:type])
      if resultingType == 'error'
        raise SemanticError, "Assignment: Type mismatch in assignment to variable '#{var_name}'"
      end
      # create_cuadruple('=', val[2][:offset], var_offset, new_memory_offset(resultingType, 'temp'))
      create_cuadruple('=', val[2][:offset], nil, var_offset)
      # if @current_function
      #  @symbol_tables[@current_function]['MetaData'][:resources][@resourceIndex["temp#{resultingType}"]] += 1
      # end
    }

  # Expression hierarchy
  expression: exp { 
    result = val[0]  # Pass up the exp value
  } 
  | exp operator exp { 
    left = val[0]
    op = val[1]
    right = val[2]

    evaluation = create_cuadruple(op, left[:offset], right[:offset], new_memory_offset('bool', 'temp'))
    puts "DEBUG: Expression with operator: #{op}"

    result = { name: 'Evalresult', type: 'bool', offset: evaluation, op: op }
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
      puts "DEBUG: Exp with termlist operation"
      
      resultingType = evaluate_expression_types(term[:type], ops[:type])
        # Check if the types are compatible
        if resultingType == 'error'
          raise SemanticError, "Assignment: Type mismatch in expression"
        end

      # Create the cuadruple for the operation
      if @current_function
        @symbol_tables[@current_function]['MetaData'][:resources][@resourceIndex["temp#{resultingType}"]] += 1
      end
      evaluation = create_cuadruple(ops[:operator], term[:offset], ops[:offset], new_memory_offset(resultingType, 'temp'))

      result = { name: 'Evalresult', type: resultingType, offset: evaluation }
    end
  }

  termlist: termop exp { 
    result = { operator: val[0], name: val[1][:name], type: val[1][:type], offset: val[1][:offset] }
  } 
  | /* opcional */ { 
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
      puts "DEBUG: Term with factorlist operation"

      resultingType = evaluate_expression_types(factor[:type], ops[:type])
        # Check if the types are compatible
        if resultingType == 'error'
          raise SemanticError, "Assignment: Type mismatch in expression"
        end

      # Create the cuadruple for the operation
      if @current_function
        @symbol_tables[@current_function]['MetaData'][:resources][@resourceIndex["temp#{resultingType}"]] += 1
      end
      evaluation = create_cuadruple(ops[:operator], factor[:offset], ops[:offset], new_memory_offset(resultingType, 'temp'))

      result = { name: 'Evalresult', type: resultingType, offset: evaluation }
    end
  }

  factorlist: factorop term { 
    result = { operator: val[0], name: val[1][:name], type: val[1][:type], offset: val[1][:offset] }
  } 
  | /* opcional */ { 
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
      puts "DEBUG: Factorids with expop operation"
      result = { operator: op, offset: value[:offset] }
    end
  }

  expop: termop { 
    result = val[0]  # Pass up the termop value
  } 
  | /* opcional */ { 
    result = nil  # No operator
  }

  expids: ID {
    # Check if variable exists when used in expression
    var_name = val[0]
    if !variable_exists(var_name)
      raise SemanticError, "Expression: Variable '#{var_name}' not declared before use"
    end
    var_data = get_variable_data(var_name)
    var_offset = var_data[:offset]
    var_type = var_data[:type]
    result = { name: var_name, type: var_type, offset: var_offset }
  } 
  | const { 
    result = val[0]  # Pass up the const value
  }

  const: CTE_INT { 
    if @const_dict[val[0]] != nil
      memoryAddress = @const_dict[val[0]]
    else
      memoryAddress = new_memory_offset('int', 'const')
      @const_dict[val[0]] = memoryAddress
    end
    result = {name: 'int const', type: 'int', offset: memoryAddress }
  } 
  | CTE_FLOAT { 
    if @const_dict[val[0]] != nil
      memoryAddress = @const_dict[val[0]]
    else
      memoryAddress = new_memory_offset('float', 'const')
      @const_dict[val[0]] = memoryAddress
    end
    result = { name: 'float const', type: 'float', offset: memoryAddress }
  }

  # condition statement
  ifExpression: '(' expression ')' {
    if val[1][:op] == nil
      raise SemanticError, "Expression: The expression inside the if must evaluate a boolean"
    end
    # Create a false jump for the if condition
    @jump_stack.push(@cuadruples.length)
    create_cuadruple('GOTOF', val[1][:offset], nil, "pending")
  }
  condition: 'if' ifExpression body optionalelse ';' {
    false_jump_index = @jump_stack.pop
    
    # Fill the false jump with the exit point
    fill_goto(false_jump_index, @cuadruples.length+1)
  }
  elseKeyword: 'else' {
    false_jump_index = @jump_stack.pop
    
    # Fill the false jump with the exit point
    fill_goto(false_jump_index, @cuadruples.length+2)

    # Create a GOTO to skip the else body
    @jump_stack.push(@cuadruples.length)
    create_cuadruple('GOTO', nil, nil, "pending")
  }
  optionalelse: elseKeyword body | /* opcional */

  # while header
  whileHeader: 'while' {
    @jump_stack.push(@cuadruples.length)
  }

  whileExrpession: '(' expression ')' {
    # Create a false jump for the while condition
    @jump_stack.push(@cuadruples.length)
    create_cuadruple('GOTOF', val[1][:offset], nil, "pending")
  }

  # cycle statement
  cycle: whileHeader whileExrpession 'do' body ';' {

    false_jump_index = @jump_stack.pop
    start_quad = @jump_stack.pop
    
    # Generate return GOTO to beginning of while
    generate_goto
    # Fill the return GOTO with the start of the while
    fill_goto(@jump_stack.pop, start_quad + 1)
    
    # Fill the false jump with the exit point
    fill_goto(false_jump_index, @cuadruples.length+1)
    
  }

  # function call statement
  fcall: function_id '(' funccallexp ')' ';' {
    # check if number of parameters matches
    if @current_param_count != @symbol_tables[@calling_function]['MetaData'][:params]
      raise SemanticError, "Function call: Function '#{@calling_function}' expects #{@symbol_tables[@calling_function]['MetaData'][:params]} parameters, but received #{@current_param_count}"
    end
    create_cuadruple('GOSUB', nil, nil, @symbol_tables[@calling_function]['MetaData'][:funcStart])  # Call the function
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
    create_cuadruple('ERA', nil, nil, func_name)
    @current_param_count = 0
    @calling_function = func_name
    
    # Return the function name for use in parent rule
    result = func_name
  }
  funccallexp: funcexplist | /* opcional */

  funcexplist: single_param | single_param_comma funccallexp

  single_param: expression {
    param_name = @symbol_tables[@calling_function]['MetaData'][:paramsOrder][@current_param_count]
    param_data = get_variable_data(param_name, @calling_function)
    @current_param_count += 1
    create_cuadruple('PARAM', param_data[:offset], nil, val[0][:offset])
    result = val[0]  # Return the expression value
  }

  single_param_comma: expression ',' {
    param_name = @symbol_tables[@calling_function]['MetaData'][:paramsOrder][@current_param_count]
    param_data = get_variable_data(param_name, @calling_function)
    @current_param_count += 1
    create_cuadruple('PARAM', param_data[:offset], nil, val[0][:offset])
    result = val[0]  # Return the expression value
  }

  #print statement
  printstat: 'print' '(' printexplist ')' ';' { 
    create_cuadruple('NEWLINE', nil, nil, nil)
    result = val[2] 
    }
  printexplist: printvalue {
    result = val[0]
    }
  | printvalue ',' printexplist {
    result = val[2]
    }
  printvalue: expression {
    create_cuadruple('PRINT', nil, nil, val[0][:offset])
    result = val[0]
    }
  | CTE_STRING {
    create_cuadruple('PRINT', nil, nil, val[0])
    result = {name: 'string const', type: 'string'}
    } # Pass up the string value
  
end

# end of the grammar

---- header

require 'json'
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
  @memory = {
    'global' => {
      'int' => {BP: 0, OF: 0},
      'float' => {BP: 1000, OF: 0},
    },
    'local' => {
      'int' => {BP: 2000, OF: 0},
      'float' => {BP: 3000, OF: 0},
    },
    'const' => {
      'int' => {BP: 4000, OF: 0},
      'float' => {BP: 5000, OF: 0},
    },
    'temp' => {
      'int' => {BP: 6000, OF: 0},
      'float' => {BP: 7000, OF: 0},
      'bool' => {BP: 8000, OF: 0},
    }
  }
  @cuadruples = []
  @quad_counter = 0
  @jump_stack = []
  @const_dict = {}
  @resourceIndex = {
    'int' => 0,
    'float' => 1,
    'tempint' => 2,
    'tempfloat' => 3,
    'tempbool' => 4
  }

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
    },
    'bool' => {
      'int' => 'error',
      'float' => 'error',
      'string' => 'error'
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
    when /\A(!=|<|>)/o
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

# Helper function to create a new memory offset
def new_memory_offset(type, scope = 'global')
  # Check if the type exists in the memory map
  if @memory[scope][type]
    basePointer = @memory[scope][type][:BP]
    offset = @memory[scope][type][:OF]
    @memory[scope][type][:OF] += 1
    return basePointer + offset
  else
    raise SemanticError, "Memory allocation: Type '#{type}' not found in memory map for scope '#{scope}'"
  end
end

# Helper function to create cuadruples
def create_cuadruple(op, arg1, arg2, result)
  newCuadruple =  [ op, arg1, arg2, result ]
  @cuadruples.push(newCuadruple)
  puts "Cuadruple #{@cuadruples.length}: #{op} #{arg1} #{arg2} -> #{result}"
  return newCuadruple[3]
end

# Helper function to get variable data
def get_variable_data(var_name, scope = @current_scope)
  # Check current scope first
  if @symbol_tables[scope] && @symbol_tables[scope][var_name]
    return @symbol_tables[scope][var_name]
  end
  
  # Check global scope if we're not already in it
  if scope != 'global' && @symbol_tables['global'][var_name]
    return @symbol_tables['global'][var_name]
  end
  
  # Variable not found
  nil
end

# Helper function to print the symbol table (for debugging)
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

# Helper function to print the cuadruples (for debugging)
def print_cuadruples
  puts "\n==== CUADRUPLES ===="
  @cuadruples.each_with_index do |cuadruple, index|
    puts "Cuadruple #{index + 1}: #{cuadruple[0]} #{cuadruple[1]} #{cuadruple[2]} -> #{cuadruple[3]}"
  end
  puts "======================="
end

# Helper function to print const table (for debugging)
def print_const_table
  puts "\n==== CONST TABLE ===="
  @const_dict.each do |const_value, address|
    puts "Const #{const_value}: Address #{address}"
  end
  puts "======================="
end

# Helper to evaluate expression types
def evaluate_expression_types(type1, type2)
  if @semantic_Cube[type1] && @semantic_Cube[type1][type2]
    return @semantic_Cube[type1][type2]
  end
  return 'error'
end

def generate_goto
  # Generate a GOTO quadruple with a pending jump
  @jump_stack.push(@cuadruples.length)
  quad = create_cuadruple('GOTO', nil, nil, 'pending')
  return quad
end

def fill_goto(quad_index, jump_destination)
  # Fill in the pending GOTO with actual destination
  @cuadruples[quad_index][3] = jump_destination
end

# Helper function to export the symbol tables, cuadruples, and const table
def export_data
  full_data = {
    symbol_tables: @symbol_tables,
    cuadruples: @cuadruples,
    const_dict: @const_dict,
    resourceIndex: @resourceIndex
  }
  File.open("baby_duck_output.json", "w") do |file|
    file.write(JSON.pretty_generate(full_data))
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
      parser.print_cuadruples
      parser.print_const_table
      puts "Análisis exitoso: #{result}"
      parser.export_data
    rescue SemanticError => e
      puts "Semantic Error: #{e.message}"
    end
  end
end