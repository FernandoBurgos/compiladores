require 'json'

class VirtualMachine
    attr_accessor :symbol_tables, :cuadruples, :const_dict, :resourceIndex, :memory, :instruction_pointer, :execution_stack

    # Optional: Initialize the virtual machine with empty structures
    def initialize
        @symbol_tables = {}
        @cuadruples = []
        @const_dict = {}
        @resourceIndex = {}
        @memory = Array.new(9) { [] } # [[globalInt], [globalFloat], [localInt], [localFloat], [constInt], [constFloat], [tempInt],  [tempFloat], [tempBool]]
        @instruction_pointer = 0
    end

    # Main load method to load the virtual machine state from a file
    def load_from_file(filename)
        file_content = File.read(filename)
        data = JSON.parse(file_content)
        @symbol_tables = data["symbol_tables"]
        @cuadruples = data["cuadruples"]
        @const_dict = data["const_dict"]
        # @resourceIndex = data["resourceIndex"]
        @memory = Array.new(9) { [] }
        @instruction_pointer = 0

        @const_dict.each do |key, value|
            # puts "Loading constant: #{key} with value: #{value}"
            memorySection = (value / 1000).floor
            offset = value % 1000
            # puts "Memory Section: #{memorySection}, Offset: #{offset}"
            @memory[memorySection][offset] = memorySection == 4 ? key.to_i : key.to_f
        end
    end

    def solve_expression(operator, left, right, offset)
        leftValue = @memory[(left / 1000).floor][left % 1000]
        rightValue = @memory[(right / 1000).floor][right % 1000]
        puts "Solving expression: #{leftValue} #{operator} #{rightValue} at offset #{offset}"
        memorySection = (offset / 1000).floor
        targetOffset = offset % 1000
        result = nil
        case operator
        when '+'
            result = leftValue + rightValue
        when '-'
            result = leftValue - rightValue
        when '*'
            result = leftValue * rightValue
        when '/'
            result = leftValue / rightValue
        when '<'
            result = leftValue < rightValue ? 1 : 0
        when '>'
            result = leftValue > rightValue ? 1 : 0
        when '=='
            result = leftValue == rightValue ? 1 : 0
        when '!='
            result = leftValue != rightValue ? 1 : 0
        when '<='
            result = leftValue <= rightValue ? 1 : 0
        when '>='
            result = leftValue >= rightValue ? 1 : 0
        else
            raise "Unknown operator: #{operator}"
        end
        puts "Result of expression: #{result} stored at memory section #{memorySection}, offset #{targetOffset}"
        # Save the result in memory
        @memory[memorySection][targetOffset] = result
        @instruction_pointer += 1
    end

    def assign_variable(offset, offsetTarget)
        # Assuming variable is a symbol or string that represents the variable name
        memorySection = (offset / 1000).floor
        targetMemorySection = (offsetTarget / 1000).floor
        valueOffset = offset % 1000
        offsetTarget = offsetTarget % 1000
        value = @memory[memorySection][valueOffset]
        @memory[targetMemorySection][offsetTarget] = value
        @instruction_pointer += 1
    end

    def go_to(target)
        # Assuming target is an integer representing the instruction pointer
        @instruction_pointer = target
    end

    def go_to_f(condition, target)
        conditionValue = @memory[(condition / 1000).floor][condition % 1000]
        puts "Checking condition for GOTOF: #{conditionValue}"
        # Assuming condition is a boolean or an integer representing a condition
        if conditionValue == 0
            @instruction_pointer = target
        else
            @instruction_pointer += 1
        end
    end

    def go_to_t(condition, target)
        conditionValue = @memory[(condition / 1000).floor][condition % 1000]
        puts "Checking condition for GOTOT: #{conditionValue}"
        # Assuming condition is a boolean or an integer representing a condition
        if conditionValue == 1
            @instruction_pointer = target
        else
            @instruction_pointer += 1
        end
    end

    def print(value)
        if value.is_a?(String)
            puts value
        else
            value = @memory[(value / 1000).floor][value % 1000]
            puts value
        end
        @instruction_pointer += 1
    end

    # Method to execute the loaded cuadruples
    def execute
        # Placeholder for execution logic
        puts "Executing #{@cuadruples.length} cuadruples..."

        # Here you would implement the logic to execute each cuadruple
        while @instruction_pointer < @cuadruples.length
            puts "Executing instruction at pointer #{@instruction_pointer + 1}"
            puts "cuadruple: #{@cuadruples[@instruction_pointer]}"
            cuadruple = @cuadruples[@instruction_pointer]
            case cuadruple[0]
            when '+', '-', '*', '/', '<', '>', '==', '!=', '<=', '>='
                solve_expression(cuadruple[0], cuadruple[1], cuadruple[2], cuadruple[3])
            when '='
                assign_variable(cuadruple[1], cuadruple[3])
            when 'GOTO'
                go_to(cuadruple[3] - 1)
            when 'GOTOF'
                go_to_f(cuadruple[1], cuadruple[3] - 1)
            when 'GOTOT'
                go_to_t(cuadruple[1], cuadruple[3] - 1)
            when 'PRINT'
                print(cuadruple[3])
            end
        end
        # For example, iterating through @cuadruples and performing operations
    end

    def print_state
        puts "Symbol Tables: #{@symbol_tables}"
        puts "Cuadruples: #{@cuadruples}"
        puts "Constant Dictionary: #{@const_dict}"
        puts "Memory: #{@memory.inspect}"
    end
end

vm = VirtualMachine.new
vm.load_from_file('baby_duck_output.json')
vm.print_state
vm.execute
vm.print_state
