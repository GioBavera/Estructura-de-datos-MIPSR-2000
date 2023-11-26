# TRABAJO 3 MIPS -- Giovani Bavera
		.macro read_int
		li $v0,5
		syscall
		.end_macro

		.macro print_label (%label)
		la $a0, %label
		li $v0, 4
		syscall
		.end_macro

		.macro done
		li $v0,10
		syscall
		.end_macro	

		.macro print_error (%error)
		print_label(error)
		li $a0, %error
		li $v0, 1
		syscall
		print_label(return)
		.end_macro

.data
slist:	.word 0 	
cclist: .word 0 	# Puntero a lista 
wclist: .word 0     # Puntero a actual elemento de lista
schedv: .space 32
noenc:.asciiz "notfound \n"
menu:	.ascii "Colecciones de objetos categorizados\n"
		.ascii "====================================\n"
		.ascii "1-Nueva categoria\n"
		.ascii "2-Siguiente categoria\n"
		.ascii "3-Categoria anterior\n"
		.ascii "4-Listar categorias\n"
		.ascii "5-Borrar categoria actual\n"
		.ascii "6-Anexar objeto a la categoria actual\n"
		.ascii "7-Listar objetos de la categoria\n"
		.ascii "8-Borrar objeto de la categoria\n"
		.ascii "0-Salir\n"
		.asciiz "Ingrese la opcion deseada: "
error:	.asciiz "Error: "
return:	.asciiz "\n"
catName:.asciiz "\nIngrese el nombre de una categoria: "
selCat:	.asciiz "\nSe ha seleccionado la categoria:"
idObj:	.asciiz "\nIngrese el ID del objeto a eliminar: "
objName:.asciiz "\nIngrese el nombre de un objeto: "
success:.asciiz "La operacion se realizo con exito\n\n"
spacio: .asciiz "  "
indicador: .asciiz "> "
puntoespacio: .ascii ". "

.text
main:
	# initialization scheduler vector
	la $t0, schedv
	la $t1, newcaterogy
	sw $t1, 0($t0)
	la $t1, nextcategory
	sw $t1, 4($t0)
	la $t1, prevcaterogy
	sw $t1, 8($t0)
	la $t1, listcategories
	sw $t1, 12($t0)
	la $t1, delcaterogy
	sw $t1, 16($t0)
	la $t1, newobject
	sw $t1, 20($t0)
	la $t1, listobjects
	sw $t1, 24($t0)
	la $t1, delobject
	sw $t1, 28($t0)
	jal main_loop			#salta al loop principal

#---------------- MAIN
main_loop:
	# show menu
	jal menu_display
	beqz $v0, main_end	    # Si la opcion es 0, termina el programa
	addi $v0, $v0, -1		# dec menu option
	move $t6, $v0			# Opcion elegida
	sll $v0, $v0, 2         # multiply menu option by 4
	la $t0, schedv			
	add $t0, $t0, $v0		
	lw $t1, ($t0)
    la $ra, main_ret 		# save return address
    jr $t1					# call menu subrutine

main_ret:
    j main_loop		
main_end:
	done

#---------------- MENU
menu_display:
	# write your code
	print_label(menu)
	read_int
	# test if invalid option go to L1
	bgt $v0, 8, menu_display_L1		# Si el valor ingresa es <0 o >8
	bltz $v0, menu_display_L1
	# else return
	jr $ra
	# print error 101 and try again
	# print_label(error101)
menu_display_L1:
	print_error(101)
	j menu_display
	
#---------------- CATEGORIAS
# Crea una categoria
newcaterogy:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)		# Preservo el $ra
	la $a0, catName		# input category name
	jal getblock
	move $a2, $v0		# $a2 = *char to category name
	la $a0, cclist		# $a0 = list
	li $a1, 0			# $a1 = NULL
	jal addnode
	lw $t0, wclist
	bnez $t0, newcategory_end
	sw $v0, wclist		# update working list if was NULL
newcategory_end:
	li $v0, 0			# return success
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra

# Avanza una categoria
nextcategory:
	lw $t2, wclist
	beqz $t2, e201
	lw $t3, ($t2)
	lw $t4, 12($t2)
	beq $t3, $t4, e202
	lw $t0, wclist		# Puntero en la actual lista 
    lw $t1, 12($t0)		# Se mueve al final de la categoria (proxima categoria)
    sw $t1, wclist
	jr $ra

# Retrocede una categoria
prevcaterogy:
	lw $t3, wclist
	beqz $t3, e201
	lw $t3, ($t2)
	lw $t4, 12($t2)
	beq $t3, $t4, e202
	lw $t0, wclist
    lw $t0, ($t0)
    sw $t0, wclist
	jr $ra

# Lista Todas las Categorias
listcategories:
	lw $t3, wclist		# Puntero a la actual categoria
	lw $t1, cclist		
	lw $t2, cclist		# Punteros Iniciales	
	
	listloop:
	beqz $t3, e301		# Puntero = NULL? Entonces error 301
	beq $t1, $t3, actualNodo
	j nodoNoActual

	actualNodo:  	# Imprime "> "
	la $a0, indicador
	li $v0, 4 		# "> "
	syscall
	j listfinal

	nodoNoActual: 	# Imprime "  "
	la $a0, spacio
	li $v0, 4 		
	syscall
	j listfinal

	listfinal:
	lw $a0, 8($t1)
	li $v0, 4
	syscall
    lw $t1, 12($t1)
    beq $t2, $t1, main_loop
    j listloop

delcaterogy:
	addi $sp, $sp, -4
    sw $ra, 4($sp)
    lw $t1, wclist
    beqz $t1, e401    #busca que exista categoria

    lw $t1, 4($t1)

    loopdelate:
    beqz $t1, delcategory    #busca que exista un objeto
    lw $a0, wclist
    la $a1, 4($a0)
    lw $a0, 4($a0)

    jal delnode
    lw $t1, wclist
    lw $t1, 4($t1)
    j loopdelate

    delcategory:
    lw $a0, wclist
    la $a1, cclist

    jal delnode

    lw $t0, cclist
    sw $t0, wclist

    lw $ra, 4($sp)
    addi $sp, $sp, 4
    jr $ra
#---------------- OBJETOS
newobject:
	addi $sp, $sp, -4
	sw $ra, 4($sp)		# Guarda el $ra en la pila
	la $a0, objName 	# Imprime mensaje
	jal getblock 		# Llama getblock
	move $a2, $v0 		# $a2 = *char to category name
	
	lw $t6, wclist		
	move $a0, $t6 		# carga la direccion de memoria de la categoria donde se crea el objeto
	addi $a0, $a0, 4 	# Posicion en el bloque para poner el numero (ID)
	
	jal last_id			# Le paso la posicion del ID 
	jal addnode  		# Agrega el nodo

newobject_end:
	li $v0, 0 			# return success
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	j main

void_id: 
	li $a1, 0
	addi $a1, $a1, 1
	jr $ra

last_id:
	lw $a1, ($a0)
	beqz $a1, void_id	# Si esta vacia = 1.
	lw $a1, ($a1)
	lw $a1, 4($a1)
	addi $a1, $a1, 1
	jr $ra


listobjects:
	lw $t1, wclist		# Cargo el puntero del actual bloque
	beqz $t1, e601
	addi $t1, $t1, 4    # Muevo el puntero a la posicion de la direccion de los bloques
	beqz $t1, e602
	lw $t1, ($t1)	    # $a1 movil
	move $t2, $t1	    # $a2 fijo
	beqz $t1, e601		# Si no hay objetos, salta al error 601
	
	objectloop:
	lw $a0, 4($t1)				# Imprime la respectiva posicion (ID)
	li $v0, 1 	
	syscall
	la $a0, puntoespacio		# Imprime seguidamente ". "
	li $v0, 4 	
	syscall
	objfinal:
	lw $a0, 8($t1)				# Imprime el nombre del objeto
	li $v0, 4
	syscall

    lw $t1, 12($t1)				
    beq $t1, $t2, main_loop
    j objectloop

delobject:
    lw $a1, wclist		   # Categoria Actual		
    beqz $a1, e701
    la $a0, idObj		   # Ingrese la ID
	li $v0, 4
	syscall
	read_int
	move $t3, $v0		   # Opcion elegida ID guardada
    lw $a0, 4($a1)	
    la $a1, 4($a1)
	move  $t2, $a0 		   # Copia de esta direccion

	
	doloop:
		lw $t4, 4($t2)			   # Carga la ID del bloque en $t8
    	beq $t3, $t4, encontrada   # Si encuentra la ID, salta y elimina
    	lw $t2, 12($t2)			   # Avanza al siguiente bloque
    	beq $a0, $t2, notenc 	   # Si dio toda la vuelta y no encontro, da error y vuelve a main
    	j doloop

	encontrada: 
		move $a0, $t2
		jal delnode
		print_label(success)
		j main_loop

	notenc: 
		print_label(noenc)
		j main_loop

#---------------- NODOS
# a0: list address (pointer to the list) | clist o wlist
# a1: NULL if category or ID if an object  | 4(list)
# a2: address return by getblock
# v0: node address added
addnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	jal smalloc
	sw $a1, 4($v0) # set node content
	sw $a2, 8($v0)
	lw $a0, 4($sp)
	lw $t0, ($a0) # first node address
	beqz $t0, addnode_empty_list
addnode_to_end:
	lw $t1, ($t0) # last node address
 	# update prev and next pointers of new node
	sw $t1, 0($v0)
	sw $t0, 12($v0)
	# update prev and first node to new node
	sw $v0, 12($t1)
	sw $v0, 0($t0)
	j addnode_exit
addnode_empty_list:
	sw $v0, ($a0)
	sw $v0, 0($v0)
	sw $v0, 12($v0)
addnode_exit:
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra

# Elimina un NODO
# a0: node address to delete
# a1: list address where node is deleted
delnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	lw $a0, 8($a0) # get block address
	jal sfree # free block
	lw $a0, 4($sp) # restore argument a0
	lw $t0, 12($a0) # get address to next node of a0 node
	beq $a0, $t0, delnode_point_self
	lw $t1, 0($a0) # get address to prev node
	sw $t1, 0($t0)
	sw $t0, 12($t1)
	lw $t1, 0($a1) # get address to first node again
	bne $a0, $t1, delnode_exit
	sw $t0, ($a1) # list point to next node
	j delnode_exit
delnode_point_self:
	sw $zero, ($a1) # only one node
delnode_exit:
	jal sfree
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra

 # a0: msg to ask
 # v0: block address allocated with string
 # punte previo - puntero a otro lista - nombre - puntero prox
getblock:
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	li $v0, 4
	syscall
	jal smalloc
	move $a0, $v0
	li $a1, 16
	li $v0, 8
	syscall
	move $v0, $a0
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra

#---------------- UTILIDADES
smalloc:
	lw $t0, slist
	beqz $t0, sbrk
	move $v0, $t0
	lw $t0, 12($t0)
	sw $t0, slist
	jr $ra
sbrk:
	li $a0, 16 # node size fixed 4 words
	li $v0, 9
	syscall # return node address in v0
	jr $ra
sfree:
	lw $t0, slist
	sw $t0, 12($a0)
	sw $a0, slist # $a0 node address in unused list
	jr $ra

#-------------------- ERRORES
e202: 
	print_error(202)
	j main_loop

e201: 
	print_error(201)
	j main_loop

e301: 
	print_error(301)
	j main_loop		 

e401: 
	print_error(401)
	j main_loop

e601:
	print_error(601)
	j main_loop

e602:
	print_error(602)
	j main_loop

e701:
	print_error(701)
	j main_loop