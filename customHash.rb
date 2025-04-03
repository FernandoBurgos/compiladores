class CustomHash
    def initialize
        @hash = {}
    end

    def set(key, value)
        @hash[key] = value # Asignar un valor a una llave
    end

    def get(key)
        @hash[key] # Obtener el valor de una llave
    end

    def delete(key)
        @hash.delete(key) # Eliminar una llave y su valor
    end

    def keys
        @hash.keys # Obtener todas las llaves
    end

    def values
        @hash.values # Obtener todos los valores
    end

    def empty?
        @hash.empty?
    end

    def size
        @hash.size
    end
end

# puts testHash.respond_to?("include?") # => true