; Lights Out v0.1 by Joe Wingbermuehle 04-28-1998
; http://joewing.net

	BITS	16
	ORG	0x0100
	SECTION	.text

maxsize	equ	10
maxtime	equ	30
maxmoves equ	5000
xstart	equ	32
ystart	equ	30

;-----> Beginning of Lights Out!
	cld
	mov	ax,0013h
	int	10h
	xor	ax,ax
	int	33h
	or	ax,ax
	jnz	mousefound
	jmp	quit
mousefound:
start:	xor	cx,cx
	mov	[level],cx
	mov	[count],cx
	mov	[score],cx
	mov	[moves],word maxmoves+1
	inc	cx
	mov	[size],cx

;-----> Draw Background
next:	mov	dx,[size]
	mov	ax,[level]
	cmp	dx,maxsize-1
	jg	next2
	inc	ax
	inc	dx
next2:	imul	ax,maxtime
	mov	[size],dx
	inc	ax
	mov	[time],ax
	inc	word [level]
	mov	di,0xA000
	mov	es,di
	mov	ah,10011010b
	xor	di,di
	mov	dl,200
bglp1:	mov	bx,320
bglp2:	mov	dh,ah
	and	dh,00011001b
	mov	[es:di],dh
	ror	ah,1
	inc	di
	dec	bx
	jnz	bglp2
	rol	ah,3
	dec	dl
	jnz	bglp1

;-----> Fill matrix
	xor	ah,ah
	int	1Ah
	mov	ax,[size]
	imul	ax,word [size]
	mov	cx,ax
	mov	di,matrix
dblp0:	xor	ax,ax
	add	ax,dx
	shl	dx,2
	add	ax,dx
	shl	dx,2
	add	ax,dx
	inc	ax
	mov	dx,ax
	shr	al,7
	mov	[di],al
	inc	di
	loop	dblp0

;-----> Draw Board
	mov	dx,[size]
	mov	ax,dx
	dec	dx
	imul	ax,word [size]
	dec	ax
	mov	di,ax
	add	di,matrix
dbl1:	mov	cx,[size]
	dec	cx
dbl2:	mov	al,[di]
	dec	di
	push	cx
	push	dx
	call	plot
	pop	dx
	pop	cx
	dec	cx
	cmp	cx,-1
	jnz	dbl2
	dec	dx
	cmp	dx,-1
	jnz	dbl1
	mov	ax,[size]
	imul	ax,10
	add	ax,ystart+10
	imul	ax,320
	mov	di,ax
	add	di,xstart+10
	mov	ax,ystart+10
	imul	ax,320
	mov	bp,ax
	add	bp,xstart+10
	mov	ax,word [size]
	imul	ax,10
	add	bp,ax
	mov	cx,ax
	inc	cx
dbl3:	mov	[es:di],byte 0Fh
	mov	[es:bp],byte 0Fh
	inc	di
	add	bp,320
	loop	dbl3

;-----> Draw the title etc.
	mov	dx,2
	call	setcur
	mov	ah,09h
	mov	dx,title
	int	21h
	mov	dx,1*256+2
	call	setcur
	mov	ah,09h
	mov	dx,exittext
	int	21h
	mov	di,320*8-1
	mov	al,1Bh
dbl4:	mov	ah,[es:di]
	and	ah,00000100b
	shl	ah,1
	xor	ah,$17
	mov	[es:di],ah
	dec	di
	cmp	di,-1
	jnz	dbl4
	mov	di,320*8
	mov	cx,8*320
dbl5:	mov	ah,[es:di]
	or	ah,al
	mov	[es:di],ah
	inc	di
	loop	dbl5
	mov	dx,6*256+21
	mov	bp,info0
	mov	cx,6
dbl6:	call	disp
	add	bp,15
	inc	dh
	loop	dbl6
	call	addmov
	mov	dx,7*256+22+7
	mov	cx,[level]
	call	dispcx
	mov	cx,[score]
	mov	dx,8*256+29
	call	dispcx

;-----> Game stuff
	mov	ax,1
	int	33h
pmain:	mov	ax,3
	int	33h
	or	bx,bx
	jnz	pmain
main:	xor	ah,ah
	int	1Ah
	mov	ax,dx
	sub	dx,[count]
	cmp	dx,19
	jc	chkms
	mov	[count],ax
	dec	word [time]
	cmp	word [time],word 0000h
	jg	timecnt
	dec	word [level]
	dec	word [size]
	mov	ax,2
	int	33h
	jmp	next
timecnt:
	mov	cx,[time]
	mov	dx,10*256+29
	call	dispcx
chkms:	mov	ax,3
	int	33h
	or	bx,bx
	jz	main

;-----> Check Mouse
	mov	bx,0
divlp:	inc	bx
	sub	cx,2
	jnc	divlp
	mov	cx,bx

;-----> Check for exit/new game
	mov	ax,8+8-1
exlp1:	cmp	ax,dx
	jnz	cont1
	push	ax
	mov	ax,8*2+8*11+8*4-1
exlp2:	cmp	ax,cx
	jnz	cont2
	pop	ax
	jmp	quit
cont2:	dec	ax
	cmp	ax,8*2+8*11-1
	jnz	exlp2
	mov	ax,8*2+8*8-1
exlp3:	cmp	ax,cx
	jnz	cont3
	pop	ax
	mov	ax,2
	int	33h
	jmp	start
cont3:	dec	ax
	cmp	ax,8*2-1
	jnz	exlp3
	pop	ax
cont1:	dec	ax
	cmp	ax,8*1-1
	jnz	exlp1

;-----> Swap appropriate pieces
	mov	ax,[size]
	imul	ax,10
	mov	bx,ax
	sub	cx,xstart+10
	jl	main2
	cmp	cx,bx
	jge	main2
	mov	ax,cx
	mov	ch,10
	idiv	ch
	xor	ah,ah
	mov	cx,ax
	sub	dx,ystart+10
	jl	main2
	cmp	dx,bx
	jl	swap1
main2:	jmp	main
swap1:	mov	ax,dx
	mov	dh,10
	idiv	dh
	xor	ah,ah
	mov	dx,ax
	call	elem
	xor	al,1
	mov	[bp],al
	call	plot
	inc	bp
	inc	cx
	cmp	cx,[size]
	jz	nplot1
	call	switch
nplot1:	sub	bp,2
	sub	cx,2
	jc	nplot2
	call	switch
nplot2:	inc	cx
	inc	dx
	add	bp,[size]
	inc	bp
	cmp	dx,[size]
	jz	nplot3
	call	switch
nplot3:	sub	bp,[size]
	sub	bp,[size]
	sub	dx,2
	jc	nplot4
	call	switch
nplot4:	call	addmov

;-----> Check for a winner
	mov	di,matrix
	mov	ax,[size]
	imul	ax,word [size]
	mov	cx,ax
winlp:	cmp	byte [di],0
	jnz	nowin
	inc	di
	loop	winlp
	mov	ax,2
	int	33h
	mov	ax,[time]
	mov	bx,[score]
	add	ax,bx
	mov	[score],ax
	jmp	next
nowin:	jmp	pmain

;-----> Exit
quit:	mov	ax,2
	int	33h
	mov	ax,0003h
	int	10h
exit:	mov	ah,4Ch
	int	21h

;-----> Swap light
switch:	mov	al,[bp]
	xor	al,1
	mov	[bp],al
	jmp	plot

;-----> Set Cursor Position
setcur:	xor	bh,bh
	mov	ah,02h
	int	10h
	ret

;-----> Display [bp] at dx
disp:	push	dx
	call	setcur
	mov	dx,bp
	mov	ah,09h
	int	21h
	pop	dx
	ret

;----->	Plot
plot:	xor	ah,ah
	imul	ax,100
	add	ax,blank
	mov	[sloc],ax
	mov	ax,cx
	imul	ax,10
	add	ax,xstart+10
	mov	[sx],ax
	mov	ax,dx
	imul	ax,10
	add	ax,ystart+10
	mov	[sy],ax
	mov	ax,2
	int	33h
	pusha
	mov	di,0xA000
	mov	es,di
	mov	di,cs
	mov	ds,di
	mov	bx,[sy]
	mov	si,[sloc]
	mov	cx,10
	mov	dx,10
	mov	ax,320
	imul	ax,bx
	add	ax,[sx]
	mov	bx,ax
sprlp:	push	cx
	mov	di,bx
	rep movsb
	add	bx,320
	pop	cx
	dec	dx
	jnz	sprlp
	popa
	mov	ax,1
	int	33h
	ret

;-----> Add to moves
addmov:	mov	dx,9*256+22+7
	dec	word [moves]
	jnz	addmvc
	pop	ax
	mov	ax,2
	int	33h
	mov	dx,8*256+5
	call	setcur
	mov	dx,gover
	mov	ah,09h
	int	21h
	mov	ax,1
	int	33h
gover1:	mov	ax,3
	int	33h
	or	bx,bx
	jnz	gover1
gover2:	mov	ah,01h
	int	10h
	jnz	gover3
	mov	ax,3
	int	33h
	or	bx,bx
	jz	gover2
gover3:	jmp	start
addmvc:	mov	cx,[moves]
	jmp	dispcx

;-----> Get Matrix element
elem:	mov	ax,dx
	imul	ax,[size]
	add	ax,cx
	add	ax,matrix
	mov	bp,ax
	mov	al,[bp]
	ret

;-----> Display cx
dispcx:
   push  cx
   call  setcur
   pop   ax
   mov   bx,decimal+4
   mov   cx,10
dispCXLoop:
   xor   dx,dx
   div   cx
   add   dl,30h
   mov   [bx],dl
   dec   bx
   cmp   bx,decimal      
   jge   dispCXLoop
   mov   dx,decimal
   mov   ah,09h
   int   21h
   ret
decimal:
   db   '00000$'

;-----> Variables
	SECTION	.data
sx:	dw	0000h
sy:	dw	0000h
sloc:	dw	0000h
moves:	dw	0000h
level:	dw	0000h
time:	dw	0000h
count:	dw	0000h
score:	dw	0000h
size:	dw	0000h

;-----> Dialog
exittext:
	db	'New Game   Exit$'
title:	db	'Lights Out v0.1 by Joe Wingbermuehle$'
info0:	db	218,196,196,196,196,196,196,196,196,196,196,196,196,191,36
info1:	db	179,'Level:      ',179,36
info2:	db	179,'Score:      ',179,36
info3:	db	179,'Moves:      ',179,36
info4:	db	179,'Time:       ',179,36
info5:	db	192,196,196,196,196,196,196,196,196,196,196,196,196,217,36
gover:	db	'- GAME OVER! -',36

;-----> Sprites
blank:	db	0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh
	db	0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h
light:	db	0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh,0Fh
	db	0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0Fh,00h,00h,00h,0Eh,0Eh,0Eh,00h,00h,00h
	db	0Fh,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h
	db	0Fh,00h,0Eh,0Eh,0Eh,0Eh,0Fh,0Eh,0Eh,00h
	db	0Fh,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Fh,0Eh,00h
	db	0Fh,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h
	db	0Fh,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h
	db	0Fh,00h,00h,00h,0Eh,0Eh,0Eh,00h,00h,00h
	db	0Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h

;-----> Level Matrix
	SECTION	.bss
matrix	resb	maxsize*maxsize
