.data
# Punteros a listas y menu
slist:      .word 0               # Puntero a la lista de memoria liberada.
cclist:     .word 0               # Puntero a la lista de categorías.
wclist:     .word 0               # Puntero a la categoría seleccionada.
schedv:     .space 32             # Vector para las direcciones del menu.

# Mensajes de texto
menu:       .asciiz "Colecciones de objetos categorizados\n"
    	    .asciiz "====================================\n"
    	    .asciiz "1-Nueva categoria\n"
    	    .asciiz "2-Siguiente categoria\n"
    	    .asciiz "3-Categoria anterior\n"
    	    .asciiz "4-Listar categorias\n"
   	    .asciiz "5-Borrar categoria actual\n"
   	    .asciiz "6-Anexar objeto a la categoria actual\n"
   	    .asciiz "7-Listar objetos de la categoria\n"
   	    .asciiz "8-Borrar objeto de la categoria\n"
   	    .asciiz "0-Salir\n"
error:      .asciiz "Error: "
success:    .asciiz "La operacion se realizo con exito\n"
notfound:   .asciiz "No encontrado\n"
catName:    .asciiz "Ingrese el nombre de una categoria: "
idObj:      .asciiz "Ingrese el ID del objeto a eliminar: "
arrow:      .asciiz ">"  # Definir la cadena ">"

.text
.globl main

# Función: getblock (asigna memoria dinámica)
getblock:
    li   $v0, 9            # syscall: sbrk (solicitar memoria)
    li   $a0, 256          # Número de bytes a asignar (ajusta según sea necesario)
    syscall
    jr   $ra               # Regresar de la función

# Función: addnode (agregar un nodo a una lista enlazada)
addnode:
    # Entradas:
    # $a0 = Dirección del puntero al inicio de la lista
    # $a1 = Tipo de nodo (0: categoría, 1: objeto)
    # $a2 = Dirección de datos adicionales (nombre o contenido)

    lw    $t0, 0($a0)       # Cargar el inicio de la lista
    li    $v0, 9            # syscall sbrk para memoria dinámica
    li    $a0, 16           # Tamaño del nodo (4 palabras)
    syscall

    sw    $t0, 0($v0)       # Enlazar al nodo siguiente
    sw    $v0, 12($t0)      # Enlazar nodo anterior (si existe)
    sw    $a1, 4($v0)       # Guardar tipo de nodo
    sw    $a2, 8($v0)       # Guardar dirección de datos adicionales

    sw    $v0, 0($a0)       # Actualizar el puntero al inicio de la lista
    jr    $ra               # Regresar con la dirección del nodo en $v0

# Programa principal
main:
    # Inicialización del vector del menú
    la   $t0, schedv
    la   $t1, newcategory
    sw   $t1, 0($t0)
    la   $t1, nextcategory
    sw   $t1, 4($t0)
    la   $t1, prevcategory
    sw   $t1, 8($t0)
    la   $t1, listcategories
    sw   $t1, 12($t0)
    la   $t1, delcategory
    sw   $t1, 16($t0)
    la   $t1, newobject
    sw   $t1, 20($t0)
    la   $t1, listobjects
    sw   $t1, 24($t0)
    la   $t1, delobject
    sw   $t1, 28($t0)

menu_loop:
    # Mostrar el menu
    li   $v0, 4
    la   $a0, menu
    syscall

    # Leer la opción del usuario
    li   $v0, 5
    syscall

    # Redirigir a la función correspondiente
    la   $t0, schedv
    sll  $t1, $v0, 2           # Multiplicar por 4 para obtener desplazamiento
    add  $t1, $t1, $t0         # Dirección efectiva de la función
    lw   $t2, 0($t1)           # Cargar la dirección de la función
    jalr $t2                   # Llamar a la función correspondiente

    # Volver al menu principal
    j    menu_loop

# Funcion: Listar categorías
listcategories:
    lw    $t0, cclist
    beqz  $t0, error_301

    move  $t1, $t0
list_loop:
    lw    $t2, wclist
    bne   $t1, $t2, print_category

    # Mostrar el símbolo ">"
    la    $a0, arrow           # Cargar la dirección de ">"
    li    $v0, 4               # syscall: Imprimir cadena
    syscall

print_category:
    lw    $a0, 8($t1)
    li    $v0, 4
    syscall

    lw    $t1, 12($t1)
    bne   $t1, $t0, list_loop

    li    $v0, 0
    jr    $ra

error_301:
    li    $v0, 301
    jr    $ra

# Funcion: Crear una nueva categoría
newcategory:
    addiu $sp, $sp, -4
    sw    $ra, 4($sp)

    la    $a0, catName         # Mensaje: "Ingrese el nombre de una categoría"
    jal   getblock             # Obtener memoria para el string
    move  $a2, $v0             # Puntero al nombre en $a2

    la    $a0, cclist          # Dirección de la lista de categorías
    li    $a1, 0               # Indica que es categoría (no objeto)
    jal   addnode              # Crear el nodo y obtener su direccion

    lw    $t0, wclist
    bnez  $t0, newcategory_end # Si ya existe, no actualizar
    sw    $v0, wclist          # Actualizar wclist con la nueva categoría

newcategory_end:
    li    $v0, 0               # exito
    lw    $ra, 4($sp)
    addiu $sp, $sp, 4
    jr    $ra

# Función: Seleccionar categoría siguiente
nextcategory:
    lw    $t0, wclist
    beqz  $t0, error_201

    lw    $t1, 12($t0)
    beq   $t0, $t1, error_202

    sw    $t1, wclist          # Actualizar puntero de categoría actual
    li    $v0, 0               # exito
    jr    $ra

error_201:
    li    $v0, 201
    jr    $ra

error_202:
    li    $v0, 202
    jr    $ra

# Función: Seleccionar categoría anterior
prevcategory:
    lw    $t0, wclist
    beqz  $t0, error_201

    lw    $t1, 0($t0)
    beq   $t0, $t1, error_202

    sw    $t1, wclist
    li    $v0, 0
    jr    $ra

# Funcion: Borrar una categoría
delcategory:
    lw    $t0, wclist         # Obtener la categoría actual
    beqz  $t0, error_401      # Si no hay categoría, error 401

    lw    $t1, 12($t0)        # Dirección del siguiente nodo
    lw    $t2, 0($t0)         # Dirección del nodo anterior
    lw    $t3, 8($t0)         # Obtener lista de objetos

    # Si la lista de objetos no esta vacia, borrar objetos primero
    beqz  $t3, delete_category

    # Borrar todos los objetos de la categoria
delete_objects:
    lw    $t4, 0($t3)         # Dirección del objeto
    beqz  $t4, delete_category # Si no hay objetos, ir a borrar categoria
    jal   delobject           # Llamar a la función para borrar objeto
    lw    $t3, 12($t3)        # Avanzar al siguiente objeto
    j     delete_objects

delete_category:
    # Borrar la categoria de la lista
    beqz  $t2, delete_first_category
    sw    $t1, 12($t2)        # Actualizar el puntero del nodo anterior
    sw    $t1, 0($t0)         # Actualizar el puntero del nodo siguiente
    j     delete_end

delete_first_category:
    sw    $t1, cclist         # Si es el primer nodo, actualizar la lista de categorías
    j     delete_end

delete_end:
    li    $v0, 0              # exito
    jr    $ra

error_401:
    li    $v0, 401            # Error: No hay categorias
    jr    $ra

# Función: Anexar un objeto a la categoria actual
newobject:
    lw    $t0, wclist         # Obtener la categoria seleccionada
    beqz  $t0, error_501      # Si no hay categoria, error 501

    # Obtener el ultimo ID en la categoroa
    lw    $t1, 0($t0)         # Direccion de la lista de objetos
    li    $t2, 1              # ID inicial por defecto

    # Si hay objetos, obtener el último ID
    beqz  $t1, add_new_object
    lw    $t3, 4($t1)         # Obtener el ID del ultimo objeto
    addi  $t2, $t3, 1         # Incrementar el ID

add_new_object:
    # Crear nuevo objeto
    li    $v0, 9              # syscall sbrk para memoria dinamica
    li    $a0, 16             # Tamaño de un nodo (4 palabras)
    syscall

    sw    $t2, 0($v0)         # Guardar el ID en el objeto
    sw    $a2, 4($v0)         # Guardar el nombre en el objeto

    # Añadir objeto a la lista de objetos
    sw    $t1, 12($v0)        # Puntero al siguiente objeto (vacio por ahora)
    sw    $v0, 0($t1)         # Actualizar el puntero de la lista

    li    $v0, 0              # exito
    jr    $ra

error_501:
    li    $v0, 501            # Error: No hay categorías
    jr    $ra

# Funcion: Listar objetos de la categoria seleccionada
listobjects:
    lw    $t0, wclist         # Obtener la categoria seleccionada
    beqz  $t0, error_601      # Si no hay categorias, error 601

    lw    $t1, 0($t0)         # Obtener la lista de objetos
    beqz  $t1, error_602      # Si la lista de objetos esta vacia, error 602

    move  $t2, $t1            # Puntero al primer objeto
list_loop_objects:
    lw    $a0, 4($t2)         # Obtener el nombre del objeto
    li    $v0, 4              # syscall: imprimir string
    syscall

    lw    $t2, 12($t2)        # Avanzar al siguiente objeto
    bnez  $t2, list_loop_objects

    li    $v0, 0              # Exito
    jr    $ra

error_601:
    li    $v0, 601            # Error: No hay categorias
    jr    $ra

error_602:
    li    $v0, 602            # Error: No hay objetos
    jr    $ra

# Funcion: Borrar un objeto de la categoria seleccionada por ID
delobject:
    lw    $t0, wclist         # Obtener la categoria seleccionada
    beqz  $t0, error_701      # Si no hay categorias, error 701

    lw    $t1, 0($t0)         # Obtener la lista de objetos
    beqz  $t1, error_notfound # Si no hay objetos, error notFound

    lw    $t2, 0($t1)         # Obtener ID del primer objeto
    lw    $t3, 4($t1)         # Direccion del siguiente objeto

search_object:
    beq   $t2, $a0, delete_object # Si encontramos el objeto por ID, borrar
    lw    $t1, 12($t1)        # Avanzar al siguiente objeto
    beqz  $t1, error_notfound # Si no se encuentra, error
    lw    $t2, 0($t1)         # Obtener ID del siguiente objeto
    j     search_object

delete_object:
    lw    $t4, 12($t1)        # Obtener siguiente objeto
    sw    $t4, 12($t3)        # Conectar el objeto anterior con el siguiente

    li    $v0, 9              # syscall sbrk para liberar memoria
    li    $a0, 16             # Tamaño del nodo
    syscall

    li    $v0, 0              # Exito
    jr    $ra

error_701:
    li    $v0, 701            # Error: No hay categorias
    jr    $ra

error_notfound:
    li    $v0, 404            # Error: Objeto no encontrado
    jr    $ra

