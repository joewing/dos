; DStar v0.3 by Joe Wingbermuehle 04-24-1998
; http://joewing.net

; This file was written for use with NASM

   BITS   16
   ORG   0x0100
   SECTION   .text

number_of_levels equ   4
max_moves   equ   250

;-----> Setup
start:
   xor   ax,ax
   mov   [curlev],al
   dec   ax
   dec   ax
   mov   [moves],ax
   mov   ax,0013h
   int   10h   ; set graphics mode 13h (320x200 in 256 colors)
   inc   ah
   mov   cx,2000h
   int   10h   ; turn off the cursor

;-----> Draw Background
   mov   bx,backg
   mov   [sloc],bx
   mov   dx,200-8
bglp1:
   mov   [sy],dx
   mov   bx,320-8
bglp2:
   mov   [sx],bx
   call  sprite
   sub   bx,0008h
   jnc   bglp2
   sub   dx,0008h
   jnc   bglp1

;-----> Display Dialog
next:
   mov   dx,1*256+3
   mov   bp,title
   call  disptext2
   mov   dx,5*256+23
   mov   bp,dlev
   call  disptext2
   mov   bx,curlev
   inc   byte [bx]
   mov   cl,[bx]
   xor   ch,ch
   mov   dx,5*256+31
   call  setcur
   call  dispcx
   mov   dx,6*256+23
   mov   bp,dmovs
   call  disptext2
   mov   dx,8*256+23
   mov   bp,help1
   call  disptext2
   mov   dx,9*256+23
   mov   bp,help2
   call  disptext2
   mov   dx,10*256+23
   mov   bp,help3
   call  disptext2
   mov   dx,11*256+23
   mov   bp,help4
   call  disptext2

;-----> Draw a pretty window thingy
   mov   ax,4*256+23
   mov   [xc1],ax
   mov   ax,13*256+8
   mov   [xc2],ax
   call  window
   mov   dx,7*256+23
   call  setcur
   mov   al,195
   int   10h
   inc   dl
   call  setcur
   mov   al,196
   mov   cl,13
   int   10h
   mov   dl,23+13
   call  setcur
   mov   al,180
   mov   cl,1
   int   10h

;-----> Decompress/Load Level
   mov   di,level
   mov   cl,20
   mov   al,2
dcomp1:
   mov   [di],al
   inc   di
   loop  dcomp1
   xor   ah,ah
   mov   al,[curlev]
   dec   al
   mov   si,levels
   imul  ax,14*10+5
   add   si,ax
   mov   cl,14*10
dcomp2:
   mov   al,[si]
   mov   ah,al
   shr   al,4
   mov   [di],al
   inc   di
   and   ah,0Fh
   mov   [di],ah
   inc   si
   inc   di
   loop  dcomp2
   mov   cl,20
;   mov   ah,2   ; last block should have been a 2 so....
dcomp3:
   mov   [di],ah
   inc   di
   loop  dcomp3

;-----> Display the Level
   xor   ax,ax
   mov   [xc1],ax
   mov   cl,16
   mov   bx,level
displ1:
   push  cx
   mov   cl,20
displ2:
   mov   al,[bx]
   push  bx
   push  cx
   call  plot
   inc   byte [xc1]
   pop   cx
   pop   bx
   inc   bx
   loop  displ2
   mov   [xc1],cl
   inc   byte [yc1]
   pop   cx
   loop  displ1

;-----> Setup Variables
   mov   di,xc1
   mov   cl,05h   ; ch already is 00h
setvar:
   mov   al,[si]
   mov   [di],al
   inc   si
   inc   di
   loop  setvar

;-----> Display the Players
   call  swappieces
   call  swappieces

;-----> Main loop
main:
   mov   al,03h
   call  plot
   mov   dx,6*256+31
   call  setcur
   mov   cx,[moves]
   call  dispcx
   cmp   byte [score],0
   jnz   nowin
   jmp   winner
nowin:
   xor   ah,ah
   int   16h   ; wait for a key press
   cmp   ah,39h
   jnz   nomswap
   push  word main
   jmp   swappieces
nomswap:
   cmp   ah,4Dh
   jz    right
   cmp   ah,4Bh
   jz    left
   cmp   ah,50h
   jnz   nodown
   jmp   down
nodown:
   cmp   ah,48h
   jnz   noup
   jmp   up
noup:
   cmp   ah,31h
   jnz   nostart
   jmp   start
nostart:
   dec   ah   ; cmp   1
   jnz   main

;-----> Exit DStar
exit:
   mov   al,03h   ; ah already is 00h
   int   10h   ; clear screen
   mov   ah,4Ch
   int   20h   ; terminate

;-----> Move right
right:
   call  malign
right2:
   call  plot
   inc   bx
   mov   al,[bx]
   dec   al   ; cmp 01
   jnz   rnodot
   push  word rydot
   jmp   getdot
rnodot:
   inc   al   ; cmp 00
   jnz   slmain
rydot:
   mov   ax,[xc1]
   mov   dx,ax
   inc   al
   mov   [xc1],ax
   push  word right2
   jmp   chkfor2

;-----> Move left
left:   call   malign
left2:   call   plot
   dec   bx
   mov   al,[bx]
   dec   al   ; cmp 1
   jnz   lnodot
   push  word lydot
   jmp   getdot
lnodot:
   inc   al   ; cmp 0
   jz   lydot
slmain:
   jmp   main   ; short branch to a long branch
lydot:
   mov   ax,[xc1]
   mov   dx,ax
   dec   al
   mov   [xc1],ax
   push  word left2
   jmp   chkfor2

;-----> Move down
down:
   call  malign
down2:
   call  plot
   lea   bx,[bx+20]
   mov   al,[bx]
   dec   al   ; cmp 1
   jnz   dnodot
   push  word dydot
   jmp   getdot
dnodot:
   inc   al   ; cmp 0
   jnz   slmain
dydot:
   mov   ax,[xc1]
   mov   dx,ax
   inc   ah
   mov   [xc1],ax
   push  word down2
   jmp   chkfor2

;-----> Move up
up:
   call  malign
up2:
   call  plot
   sub   bx,20
   mov   al,[bx]
   dec   al   ; cmp 1
   jnz   unodot
   push  word uydot
   jmp   getdot
unodot:
   inc   al   ; cmp 0
   jnz   slmain
uydot:   mov   ax,[xc1]
   mov   dx,ax
   dec   ah
   mov   [xc1],ax
   push   word up2
   jmp   chkfor2

;-----> Swap the pieces
swappieces:
   mov   al,04h
   call  plot
   mov   ax,[xc1]
   xchg  ax,[xc2]
   mov   [xc1],ax
   mov   al,03h
   push  word moremv
   jmp   plot

;-----> We have a winner!
winner:
   mov   ah,[curlev]
   cmp   ah,number_of_levels
   jz    win2
   jmp   next
win2:
   mov   bp,won
   jmp   over

;-----> We have a Losser
losser:
   mov   bp,lost
over:
   mov   dx,9*256+10
   call  disptext2
   mov   ax,8*256+10
   mov   [xc1],ax
   mov   ax,20*256+3
   mov   [xc2],ax
   call  window
   mov   dx,10*256+10
   mov   bp,again
   call  disptext2
overl:
   xor   ah,ah    ; mov ah,0
   int   16h      ; wait for a keypress
   cmp   ah,15h
   jnz   chkx
   jmp   start
chkx:
   sub   ah,31h
   jnz   overl
   jmp   exit

;-----> Check for the 2nd piece
chkfor2:
   mov   cx,[xc1]
   cmp   cx,[xc2]
   jz   chknogd
   xor   al,al
   ret
chknogd:
   pop   ax   ; don't return
   mov   [xc1],dx
   jmp   main

;-----> Pick up dot
getdot:
   mov   [bx],byte 00h
   dec   byte [score]
   ret

;-----> Plot
plot:
   xor   dh,dh
   mov   dl,[xc1]
   add   dl,dl
   add   dl,dl
   add   dl,dl
   add   dl,20
   mov   [sx],dx
   mov   dl,[yc1]
   add   dl,dl
   add   dl,dl
   add   dl,dl
   add   dl,8*3
   mov   [sy],dx
   xor   ah,ah
   imul   ax,68
   add   ax,nada
   mov   [sloc],ax
   jmp   sprite

;-----> Align bx to level(xc1,yc1) and add to moves
malign:
   mov   bx,level
   mov   al,[xc1]
   xor   ah,ah
   add   bx,ax
   mov   al,[yc1]
   imul  ax,20
   add   bx,ax
moremv:
   mov   dx,[moves]
   inc   dx
   mov   [moves],dx
   xor   al,al
   cmp   dx,max_moves+1
   jnz   artn
   pop   ax   ; not going to return
   jmp   losser

;-----> Set cursor position
setcur:   push   ax
   xor   bh,bh
   mov   ah,02h
   int   10h
   pop   ax
artn:
   ret

;-----> Display text at current cursor
; Text must be length prefixed.
disptext:
   mov   ah,03h
   xor   bh,bh
   int   10h
disptext2:   ; enter here to set cursor
   push   cs
   pop   es
   mov   cl,[bp]
   inc   bp
   mov   ax,1300h
   xor   ch,ch
   mov   bx,000Fh
   int   10h
   ret

;-----> Display cx
dispcx:
   mov   ax,cx
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

;-----> Draw a window
; input: xc1=y, yc1=x, xc2=width, yc2=height
window:   mov   dx,[xc1]
   call  setcur
   mov   ax,9*256+218
   mov   cx,1
   mov   bl,15
   int   10h
   inc   dl
   call  setcur
   mov   al,196
   mov   cl,[yc2]
   int   10h
   mov   dl,[xc1]
   add   dl,[yc2]
   call   setcur
   mov   al,191
   mov   cl,1
   int   10h
   add   dh,[xc2]
   call  setcur
   mov   al,217
   int   10h
   mov   dl,[xc1]
   call  setcur
   mov   al,192
   int   10h
   inc   dl
   call  setcur
   mov   al,196
   mov   cl,[yc2]
   dec   cl
   int   10h
   ret

;-----> Draw a Sprite
sprite:
   pusha
   mov   di,0xA000
   mov   es,di
   mov   bx,[sx]
   mov   cx,[sy]
   mov   si,[sloc]
   mov   bp,si
   inc   si
   inc   si
   inc   si
   inc   si
sprlp:
   mov   ax,320
   imul  ax,cx
   add   ax,bx
   mov   di,ax
   mov   al,[si]
   mov   [es:di],al
   inc   bx
   inc   si
   mov   ax,[sx]
   add   ax,[bp]
   cmp   bx,ax
   jnz   sprlp
   mov   bx,[sx]
   inc   cx
   mov   ax,[sy]
   add   ax,[bp+2]
   cmp   cx,ax
   jnz   sprlp
   popa
   ret

;-----> Dialog
   SECTION   .data

title:   db   35,'- DStar v0.3 by Joe Wingbermuehle -'
dlev:   db   14,179,'Level:      ',179
dmovs:   db   14,179,'Moves:      ',179
help1:   db   14,179,18h,19h,1Bh,1Ah,' - Move ',179
help2:   db   14,179,'Space - Swap',179
help3:   db   14,179,'N - New Game',179
help4:   db   14,179,'ESC - Exit  ',179
won:   db   21,0B3h,'     You WON!!     ',0B3h
lost:   db   21,0B3h,'     You Lost.     ',0B3h
again:   db   21,0B3h,' Play again <Y/N>? ',0B3h

;-----> Sprites
backg:   dw   8,8
   db   01h,01h,00h,01h,01h,00h,01h,01h
   db   01h,00h,01h,01h,00h,01h,01h,00h
   db   00h,01h,01h,00h,01h,01h,00h,01h
   db   01h,01h,00h,01h,01h,00h,01h,01h
   db   01h,00h,01h,01h,00h,01h,01h,00h
   db   00h,01h,01h,00h,01h,01h,00h,01h
   db   01h,01h,00h,01h,01h,00h,01h,01h
   db   01h,00h,01h,01h,00h,01h,01h,00h
nada:   dw   8,8
   db   08h,00h,00h,00h,00h,00h,00h,08h
   db   00h,08h,00h,00h,00h,00h,08h,00h
   db   00h,00h,08h,00h,00h,08h,00h,00h
   db   00h,00h,00h,08h,08h,00h,00h,00h
   db   00h,00h,00h,08h,08h,00h,00h,00h
   db   00h,00h,08h,00h,00h,08h,00h,00h
   db   00h,08h,00h,00h,00h,00h,08h,00h
   db   08h,00h,00h,00h,00h,00h,00h,08h
ddot:   dw   8,8
   db   08h,00h,00h,00h,00h,00h,00h,08h
   db   00h,08h,00h,00h,00h,00h,08h,00h
   db   00h,00h,00h,0Eh,0Eh,00h,00h,00h
   db   00h,00h,0Eh,00h,00h,0Eh,00h,00h
   db   00h,00h,0Eh,00h,00h,0Eh,00h,00h
   db   00h,00h,00h,0Eh,0Eh,00h,00h,00h
   db   00h,08h,00h,00h,00h,00h,08h,00h
   db   08h,00h,00h,00h,00h,00h,00h,08h
wall:   dw   8,8
   db   0Ch,0Ch,0Ch,0Ch,04h,0Ch,0Ch,0Ch
   db   0Ch,0Ch,0Ch,0Ch,04h,0Ch,0Ch,0Ch
   db   0Ch,0Ch,0Ch,0Ch,04h,0Ch,0Ch,0Ch
   db   04h,04h,04h,04h,04h,04h,04h,04h
   db   0Ch,04h,0Ch,0Ch,0Ch,0Ch,0Ch,0Ch
   db   0Ch,04h,0Ch,0Ch,0Ch,0Ch,0Ch,0Ch
   db   0Ch,04h,0Ch,0Ch,0Ch,0Ch,0Ch,0Ch
   db   04h,04h,04h,04h,04h,04h,04h,04h
p1:   dw   8,8
   db   08h,00h,00h,00h,00h,00h,00h,08h
   db   00h,08h,00h,0Fh,0Fh,00h,08h,00h
   db   00h,00h,00h,07h,07h,00h,00h,00h
   db   00h,0Fh,07h,08h,08h,07h,0Fh,00h
   db   00h,0Fh,07h,08h,08h,07h,0Fh,00h
   db   00h,00h,00h,07h,07h,00h,00h,00h
   db   00h,08h,00h,0Fh,0Fh,00h,08h,00h
   db   08h,00h,00h,00h,00h,00h,00h,08h
p2:   dw   8,8
   db   08h,00h,00h,00h,00h,00h,00h,08h
   db   00h,0Eh,00h,00h,00h,00h,0Eh,00h
   db   00h,00h,07h,07h,07h,07h,00h,00h
   db   00h,00h,07h,0Fh,0Fh,07h,00h,00h
   db   00h,00h,07h,0Fh,0Fh,07h,00h,00h
   db   00h,00h,07h,07h,07h,07h,00h,00h
   db   00h,0Eh,00h,00h,00h,00h,0Eh,00h
   db   08h,00h,00h,00h,00h,00h,00h,08h

;-----> Variables
xc1:     db   00h       ; x-position of #1
yc1:     db   00h       ; y-position of #1
xc2:     db   00h       ; x-position of #2
yc2:     db   00h       ; y-position of #2
score:   db   00h       ; number of dots left
moves:   db   00h,00h   ; number of moves
curlev:  db   00h       ; current level

sx:      dw   0000h
sy:      dw   0000h
sloc:    dw   0000h

;-----> Level Data
; 00=nothing, 01=dot, 02=wall
; levels are 16*20+5 (startx, starty, p2x, p2y, #of dots)
levels:
; level 1
   db   20h,00h,00h,00h,00h,00h,00h,00h,21h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,20h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,20h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,20h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,01h,20h,00h,00h,00h,20h,21h,22h,02h
   db   22h,12h,02h,00h,00h,00h,02h,02h,10h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,20h,00h,00h,00h,00h,02h,00h,02h
   db   05h,0Eh,07h,0Eh,05h
; level 2
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,01h,10h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,01h,00h,00h,00h,02h
   db   20h,00h,01h,00h,10h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   22h,00h,00h,00h,01h,00h,00h,00h,00h,02h
   db   20h,01h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,01h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   01h,01h,03h,01h,08h
; level 3
   db   20h,00h,00h,00h,00h,00h,00h,02h,22h,22h
   db   20h,00h,00h,00h,00h,00h,00h,02h,01h,02h
   db   20h,00h,00h,00h,00h,00h,00h,02h,02h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,02h,20h,00h,00h,00h,02h
   db   20h,00h,00h,00h,02h,10h,00h,00h,00h,02h
   db   20h,00h,22h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,12h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,12h,00h,00h,02h
   db   20h,00h,00h,00h,12h,00h,22h,00h,00h,02h
   db   20h,02h,10h,00h,22h,00h,00h,00h,00h,02h
   db   20h,02h,20h,00h,00h,00h,00h,00h,00h,02h
   db   0Bh,0Eh,0Dh,0Eh,06h
; level 4
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,02h,22h,22h,22h,00h,00h,00h,00h,02h
   db   20h,00h,01h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,10h,00h,00h,00h,00h,00h,00h,02h
   db   20h,01h,00h,22h,22h,22h,22h,11h,00h,02h
   db   20h,02h,00h,00h,01h,00h,00h,00h,00h,02h
   db   20h,02h,00h,00h,10h,00h,00h,00h,00h,02h
   db   20h,02h,00h,01h,00h,22h,22h,22h,22h,02h
   db   20h,02h,00h,10h,00h,00h,00h,00h,00h,02h
   db   20h,02h,00h,00h,00h,00h,00h,00h,00h,02h
   db   20h,01h,00h,22h,22h,22h,22h,11h,00h,02h
   db   20h,00h,10h,00h,00h,00h,00h,00h,00h,02h
   db   20h,00h,01h,00h,00h,00h,00h,00h,00h,02h
   db   0Bh,0Eh,0Dh,0Eh,0Eh

;-----> Current level matrix
   SECTION   .bss

level:   resb   16*20

