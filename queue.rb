# Implementación de una fila en Ruby
class Queue
    def initialize
        @queue = []
    end
  
    def enqueue(element)
        @queue.push(element) # Agregar al final de la fila
    end
  
    def dequeue
        @queue.shift # Obtener y eliminar el primer elemento
    end
  
    def front
        @queue.first # Leer el primer elemento sin eliminarlo
    end
  
    def empty?
        @queue.empty?
    end
  
    def size
        @queue.size
    end
end
