# Implementación de una clase de pila (stack) en Ruby
class Stack
    def initialize
        @stack = []
    end
  
    def push(element)
        @stack.push(element) # Agregar un elemento a la pila
    end
  
    def pop
        @stack.pop # Obtener y eliminar el último elemento
    end
  
    def last
        @stack.last # Leer el último elemento sin eliminarlo
    end
  
    def empty?
        @stack.empty?
    end
  
    def size
        @stack.size
    end
end
