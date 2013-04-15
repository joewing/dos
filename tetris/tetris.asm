; Tetris v1.0 by Joe Wingbermuehle
; 19981226

bsize    equ   8     ; size of the blocks
width    equ   12    ; width of the board
height   equ   21    ; height of the board
boardx   equ   200   ; board x coordinate
boardy   equ   10    ; board y coordinate
titlex   equ   24
titley   equ   8
textx    equ   7
texty    equ   12
nextx    equ   88
nexty    equ   132


   BITS     16
   ORG      0x0100
   SECTION  .text

;---------= Setup Game =---------
   mov   ax,13h
   int   10h
   push  ds
   pop   es
   mov   cx,16+width*height
   xor   ax,ax
   mov   di,random
   rep   stosw
   xor   ah,ah
   int   1Ah
   mov   [random],dx
   mov   [speed],byte 15
   mov   cl,width*height
   mov   di,matrix
   rep   stosb
   mov   cl,height-1
   mov   di,matrix
   mov   al,15
setupLoop1:
   mov   [di],al
   add   di,width-1
   mov   [di],al
   inc   di
   loop  setupLoop1
   mov   di,matrix+width*height-width
   mov   cl,width
   rep   stosb
   call  startBlock

;---------= Draw Title =---------
   mov   si,title
   mov   dx,titley
   mov   cx,6
drawTitleLoop1:
   push  cx
   mov   bx,titlex
   mov   cx,10
drawTitleLoop2:
   pusha
   mov   cl,[si]
   shr   cl,4
   call  drawBlock
   popa
   add   bx,bsize
   pusha
   mov   cl,[si]
   and   cl,15
   call  drawBlock
   popa
   add   bx,bsize
   inc   si
   loop  drawTitleLoop2
   add   dx,bsize
   pop   cx
   loop  drawTitleLoop1
   mov   dx,0803h
   call  setCursor
   mov   cx,20
   mov   bp,name
   mov   bx,000Fh
   mov   ax,1300h
   int   10h
   mov   dx,1823h
   mov   bx,version
   call  putText
   mov   dx,texty*256+textx
   mov   bx,info1
   call  putText
   mov   dx,(texty+1)*256+textx
   mov   bx,info2
   call  putText
   mov   dx,(texty+2)*256+textx
   mov   bx,info3
   call  putText
   call  getNext
   call  startBlock

;---------= Main Game Loop =---------
resetTimer:
   call  scrollDown
   xor   ah,ah
   int   1Ah
   mov   [timer],dl
main:
   call  drawBoard
   xor   ah,ah
   int   1Ah
   sub   dl,[timer]
   cmp   dl,[speed]
   jge   resetTimer
   mov   ah,1
   int   16h
   jz   main
   xor   ah,ah
   int   16h
   cmp   ah,39h
   je    rotateBlock
   cmp   ah,4Bh
   je    near scrollLeft
   cmp   ah,4Dh
   je    scrollRight
   cmp   ah,50h
   je    fastDown
   dec   ah
   jne   main

;---------= Exit the Game =---------
   mov   ax,03h
   int   10h
   mov   ah,4Ch
   int   21h

;---------= Move the Block Down Quickly =----------
fastDown:
   push  word main
   jmp   scrollDown

;---------= Rotate the Block =---------
rotateBlock:
   mov   di,matrix2
   push  di
   mov   cx,width*height
   xor   al,al
   rep   stosb
   mov   al,[phase]
   inc   al
   and   al,3
   mov   [phase],al
   mov   bl,al
   mov   dl,[type]
   call  loadBlock
   pop   di
   xor   ah,ah
   mov   al,[yc]
   mov   dx,width
   imul  ax,dx
   add   di,ax
   xor   ah,ah
   mov   al,[xc]
   add   di,ax
   call  putPiece
   call  checkCollision
   je    rotateBlockS1
   mov   al,[phase]
   dec   al
   and   al,3
   mov   [phase],al
   jmp   main
rotateBlockS1:
   call  storeNew
   jmp   main

;---------= Scroll Right Blocks =---------
scrollRight:
   call  storeMoving
   mov   si,matrix2+width*height-1
   mov   di,matrix2+width*height
   mov   cx,width*height-1
   std
   rep   movsb
   cld
   call  checkCollision
   jne   scrollRightS1
   inc   byte [xc]
   call  storeNew
scrollRightS1:
   jmp   main

;---------= Scroll Blocks Left =---------
scrollLeft:
   call  storeMoving
   push  ds
   pop   es
   mov   si,matrix2+1
   mov   di,matrix2
   mov   cx,width*height-1
   rep   movsb
   call  checkCollision
   jne   scrollLeftS1
   dec   byte [xc]
   call  storeNew
scrollLeftS1:
   jmp   main

;---------= Scroll Down Blocks =---------
scrollDown:
   call  storeMoving
   mov   cx,width*height-width
   mov   si,matrix2+width*height-width
   mov   di,matrix2+width*height
   std
   rep   movsb
   cld
   mov   cl,width-2
   xor   al,al
   mov   di,matrix2+1
   rep   stosb
   call  checkCollision
   je    scrollDownS1
   jmp   startBlock
scrollDownS1:
   inc   byte [yc]
   jmp   storeNew

;---------= Check for a Collision =---------
checkCollision:
   mov   si,matrix
   mov   di,matrix2
   mov   cx,width*height
checkCollisionLoop:
   mov   al,[di]
   test  al,al
   je    checkCollisionS1
   mov   al,[si]
   cmp   al,8
   jle   checkCollisionS1
   ret
checkCollisionS1:
   inc   si
   inc   di
   loop  checkCollisionLoop
   xor   al,al
   ret

;---------= Start a New Block =---------
startBlock:
   mov   [yc],byte 0
   mov   [xc],byte width/2-2
   mov   [phase],byte 0
   mov   al,[next]
   mov   [type],al
   call  getNext
   mov   si,matrix
   mov   cx,width*height-width
startBlockLoop1:
   mov   al,[si]
   test  al,al
   je   startBlockS1
   cmp  al,byte 8
   jg   startBlockS1
   add  [si],byte 16
startBlockS1:
   inc   si
   loop  startBlockLoop1
   mov   [temp],byte 0
checkLine:
   mov   si,matrix+width
   mov   cx,height-2
   xor   dx,dx
checkLineLoop1:
   inc   dx
   push  cx
   xor   ah,ah
   mov   cl,width
checkLineLoop2:
   cmp   [si],byte 0
   jne   checkLineS1
   inc   ah
checkLineS1:
   inc   si
   loop  checkLineLoop2
   test  ah,ah
   jne   checkLineS2
   pop   cx
   mov   cx,dx
   mov   di,si
   sub   si,width
checkLineLoop3:
   push  cx
   mov   cx,width-2
   sub   si,2
   sub   di,2
   std
   rep   movsb
   cld
   pop   cx
   loop  checkLineLoop3
   inc   byte [temp]
   jmp   checkLine
checkLineS2:
   pop   cx
   loop  checkLineLoop1
   mov   al,[temp]
   xor   ah,ah
   add   byte [clines],al
   add   word [lines],ax
   add   al,al
   add   al,al
   add   al,al
   add   [score],ax
   cmp   byte [clines],10
   jl    checkLineS3
   mov   [clines],byte 0
   inc   byte [level]
   dec   byte [speed]
checkLineS3:
   mov   dx,texty*256+textx+7
   mov   cx,[score]
   call  dispCX
   mov   dx,(texty+1)*256+textx+7
   mov   cl,[level]
   call  dispCX
   mov   dx,(texty+2)*256+textx+7
   mov   cl,[lines]
   call  dispCX
   call  storeMoving
   mov   bl,[phase]
   mov   dl,[type]
   call  loadBlock
   mov   di,matrix2+width/2-2
   call  putPiece
   inc   word [score]
   call  checkCollision
   je    storeNew
   dec   word [score]
   ret

;---------= Put a Piece in a Matrix =---------
putPiece:
   mov   cx,4
putPieceLoop:
   push  cx
   mov   cl,4
   rep   movsb
   pop   cx
   add   di,width-4
   loop  putPieceLoop
   ret

;---------= Get Next Block =---------
getNext:
   mov   dx,[random]
   rol   dx,3
   xor   dx,345
   mov   [random],dx
   and   dl,7
   je    getNext
   mov   [next],dl
   xor   bl,bl
   call  loadBlock
   mov   cx,4
   mov   dx,nexty
getNextLoop1:
   push  cx
   mov   cx,4
   mov   bx,nextx
getNextLoop2:
   pusha
   mov   cl,[si]
   cmp   cl,6
   jne   getNextS1
   mov   cl,14
getNextS1:
   call  drawBlock
   popa
   inc   si
   add   bx,bsize
   loop  getNextLoop2
   pop   cx
   add   dx,bsize
   loop  getNextLoop1
   ret

;---------= Store Moving Blocks =---------
storeMoving:
   mov   cx,width*height
   mov   si,matrix
   mov   di,matrix2
storeMovingLoop:
   mov   [di],byte 0
   mov   al,[si]
   cmp   al,8   
   jg    storeMovingS1
   mov   [di],al
storeMovingS1:
   inc   si
   inc   di
   loop  storeMovingLoop
   ret

;---------= Store Matrix2 to Matrix =---------
storeNew:
   mov   cx,width*height
   mov   si,matrix2
   mov   di,matrix
storeNewLoop:
   mov   al,[di]
   cmp   al,8
   jg    storeNewS1
   mov   al,[si]
   mov   [di],al
storeNewS1:
   inc   di
   inc   si
   loop  storeNewLoop
   ret

;---------= Decompress Block =---------
; dl=type,bl=phase
loadBlock:
   mov   si,blockData
   xor   dh,dh
   dec   dl
   mov   ax,4*2
   imul  ax,dx
   inc   dl
   add   si,ax
   xor   bh,bh
   add   bl,bl
   add   si,bx
   mov   di,blockBuffer
   mov   cx,2
loadBlockLoop1:
   push   cx
   mov   cl,8
   mov   bl,[si]
loadBlockLoop2:
   rol   bl,1
   mov   al,bl
   and   al,1
   imul  ax,dx
   mov   [di],al
   inc   di
   loop  loadBlockLoop2
   inc   si
   pop   cx
   loop  loadBlockLoop1
   mov   si,blockBuffer
   ret

;---------= Draw Board =---------
drawBoard:
   mov   dx,boardy
   mov   si,matrix
   mov   cx,height
drawBoardLoop1:
   push  cx
   mov   cx,width
   mov   bx,boardx
drawBoardLoop2:
   pusha
   mov   cl,[si]
   and   cl,15
   cmp   cl,6
   jne   drawBoardS1
   mov   cl,14
drawBoardS1:
   call  drawBlock
   popa
   inc   si
   add   bx,bsize
   loop  drawBoardLoop2
   pop   cx
   add   dx,bsize
   loop  drawBoardLoop1
   ret

;---------= Draw Block =---------
; Input: bx,dx=coordinates, cl=color
drawBlock:
   mov   di,0xA000
   mov   es,di
   mov   ax,320
   imul  ax,dx
   mov   di,ax
   add   di,bx
   mov   al,cl
   mov   cx,bsize-1
drawBlockLoop1:
   push  cx
   mov   cx,bsize-1
   rep   stosb
   pop   cx
   add   di,320-bsize+1
   loop  drawBlockLoop1
   push  ds
   pop   es
   ret

;---------= Put Text BX at DX
putText:
   push  bx
   call  setCursor
   pop   dx
   mov   ah,9
   int   21h
   ret

;---------= Move Cursor to DX =---------
setCursor:
   xor   bh,bh
   mov   ah,02h
   int   10h
   ret

;---------= Display CX at DX =---------
dispCX:
   push  cx
   call  setCursor
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

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   SECTION   .data

; Dialog
name:    db   "by Joe Wingbermuehle"
version:
         db   "v1.0$"
info1:   db   "Score:$"
info2:   db   "Level:$"
info3:   db   "Lines:$"

; Graphic 6x10 (6x20 uncompressed)
title:   db   11h,10h,00h,00h,00h,00h,00h,00h,00h,00h
   db   01h,00h,00h,00h,40h,00h,00h,70h,05h,50h
   db   01h,00h,33h,04h,44h,02h,00h,00h,50h,00h
   db   01h,03h,33h,30h,40h,02h,20h,70h,05h,50h
   db   01h,03h,00h,00h,40h,02h,00h,70h,00h,05h
   db   01h,00h,33h,00h,40h,02h,00h,70h,05h,50h

;---------= Rotation Data for the Blocks =---------
blockData:
   db   00000110b   ; block 1
   db   01100000b
   db   00000110b
   db   01100000b
   db   00000110b
   db   01100000b
   db   00000110b
   db   01100000b
   db   00001111b   ; block 2
   db   00000000b
   db   01000100b
   db   01000100b
   db   00001111b
   db   00000000b
   db   01000100b
   db   01000100b
   db   00001100b   ; block 3
   db   01100000b
   db   00100110b
   db   01000000b
   db   00001100b
   db   01100000b
   db   00100110b
   db   01000000b
   db   00000110b   ; block 4
   db   11000000b
   db   01000110b
   db   00100000b
   db   00000110b
   db   11000000b
   db   01000110b
   db   00100000b
   db   00001110b   ; block 5
   db   00100000b
   db   00100010b
   db   01100000b
   db   00000100b
   db   01110000b
   db   00000110b
   db   01000100b
   db   00000111b   ; block 6
   db   01000000b
   db   00000110b
   db   00100010b
   db   00000010b
   db   11100000b
   db   01000100b
   db   01100000b
   db   11100100b   ; block 7
   db   00000000b
   db   00100110b
   db   00100000b
   db   00000100b
   db   11100000b
   db   10001100b
   db   10000000b

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   SECTION   .bss

random:  resb   2      ; Variable for random number generation
next:    resb   1      ; Next Block
lines:   resb   2      ; Number of lines dropped
score:   resb   2      ; Score
level:   resb   1      ; Current level
clines:  resb   1      ; Number of lines dropped since last level change
speed:   resb   1      ; Speed of the blocks
temp:    resb   1      ; Temporary variable for calculating the score
timer:   resb   1      ; Variable for delay
xc:      resb   1      ; x coordinate of the current block
yc:      resb   1      ; y coordinate of the current block
phase:   resb   1      ; Phase of rotation for the current block
type:    resb   1      ; Type of block currently moving
blockBuffer:
         resb   16      ; Buffer for block data decompression
matrix:  resb   width*height   ; Board Matrix
matrix2:
         resb   width*height   ; Matrix for testing moves

; END OF SOURCE
