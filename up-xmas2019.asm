hblnk = 0xe008
vblnk = 0xe002

SCREEN_WIDTH = 40
SCREEN_HEIGHT = 25

ROTOZOOM_WIDTH = 32
ROTOZOOM_HEIGHT = 25
ROTOZOOM_FRAMES = 480

org #1200

macro wait_vbl
    ; wait for vblank    
    ld hl, vblnk
    ld a, 0x7f
@wait0:
    cp (hl)
    jp nc, @wait0
@wait1:
    cp (hl)
    jp c, @wait1
endm

main:
    di
    im 1

    ld hl, buffer
    ld (hl), 0x00
    ld de, buffer+1
    ld bc, SCREEN_WIDTH*SCREEN_HEIGHT-1
    ldir

    ld hl, histogram.black
    ld (fill_color), hl
    call fill_screen

PRESS_SPACE_OFFSET = 11*SCREEN_WIDTH + SCREEN_WIDTH/2 - 6
    ld hl, press_space
    ld de, 0xd000+PRESS_SPACE_OFFSET
    ld bc, 12
    ldir

    ld hl, 0xd800+PRESS_SPACE_OFFSET
    ld (hl), 0x70
    ld de, 0xd801+PRESS_SPACE_OFFSET
    ld bc, 11
    ldir

wait_key:
    ld hl, 0xe000
    ld (hl), 0xf6 
    inc hl
    bit 4,(hl)
    jp nz, wait_key

    ; [todo] group names
    di

    ld hl, 0xd800
    ld (hl), 0x00
    ld de, 0xd801
    ld bc, SCREEN_WIDTH*SCREEN_HEIGHT - 1
    ldir

    ld hl, 640
    ld (frame), hl
    ld hl, gfx.000
    ld (display_bitmap.text), hl
    call display_bitmap

    ; start player
    ld hl, song
    xor a
    call PLY_LW_Init

    ld hl, _irq_vector
    ld (0x1039),hl

	ld hl, 0xe007               ;Counter 2.
	ld (hl), 0xb0
	dec hl
	ld (hl),1
	ld (hl),0

	ld hl, 0xe007               ;100 Hz (plays the music at 50hz).
	ld (hl), 0x74
	ld hl, 0xe005
ifdef EMU
    ld (hl), 156
else
	ld (hl), 110
endif
	ld (hl), 0

	ld hl, 0xe008 ;sound on
	ld (hl), 0x01

    ld hl, 0xd000
    ld (hl), 0x43
    ld de, 0xd001
    ld bc, SCREEN_WIDTH*SCREEN_HEIGHT - 1
    ldir

    ei

main_loop:

    ld hl, rotozoom.index
    ld  a, (hl)
    and 0x7
    add a, hi(rotozoom.gfx)
    inc (hl)
    ld h, a
    ld l, 0
    ld de, buffer
    ld bc, 256
    ldir

    call rotozoom

    jp main_loop

rotozoom:
    ld hl, frame
    ld a,(hl)
    and 7
    inc (hl)
    add a, a
    add a, lo(border)
    ld l, a
    adc a, hi(border)
    sub l
    ld h, a
    ld a, (hl)
    inc hl
    ld b, (hl)
    ld iyl, a
    ld iyh, b

    ld ix, 0xd800 + 40*25 - 40 + 8
    call border8_fill

    ld ix, 0xd000 + 40*25 - 40 + 8    
    call border8_fill

    exx
    ld de,ROTOZOOM_FRAMES
    exx
rotoloop:
    wait_vbl
    
@zoom equ $+1
    ld a,0x00
    ld l,a
    add a,a
    ld e,a
   
    ld h,hi(cos_table)
    ld a,(hl)
    add a,24
    ld iyl,a                 ; iyl = 24 + cos (i)

    neg
    rlca
    rlca
    rlca
    rlca
    ld c,a
    or 0xf0
    ld b,a
    ld a,c
    and 0xf0
    ld c,a                  ; bc = -c * 16
    push bc
    push bc
    
    ld l,e
    ld e,(hl)               ; e = cos(2*i)
    inc h
    ld a,(hl)               ; d = sin(2*i)
    ld (@s0),a
    
    ld a,iyl
    ld l,e
    call mul
    
    srl b
    rr c
    srl b
    rr c                    ; bc = z * cos(2*i) >> 2
    
    pop hl
    add hl,bc               ; hl += bc
    ld (@du),hl
   
    ld a,iyl
@s0 equ $+1
    ld l,0x00
    call mul

    srl b
    rr c                    ; bc = z * sin(2*i) >> 1
    
    pop hl
    add hl,bc               ; hl += bc
    ex de,hl
@du equ $+1
    ld bc,0x0000

    ld hl,de
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld (@u0),hl
    ld hl,bc
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld (@v0),hl

    exx    
    ld hl, 0xd800+(SCREEN_WIDTH*SCREEN_HEIGHT)
    ld bc,-SCREEN_WIDTH
    exx
    
    ex af,af'
    ld a,SCREEN_HEIGHT
        
.loop_y:
@u0 equ $+2
    ld ix,0x0000
@v0 equ $+2
    ld iy,0x0000

    di

    exx
    ld  (@sp_backup),sp
    ld sp,hl
    exx

    ex af,af'
repeat ROTOZOOM_WIDTH/2
        ld a, iyh
        and 0xf0
        ld l, a
        ld a, ixh
        rrca
        rrca
        rrca
        rrca
        and 0x0f
        or l
        ld l, a
        ld h, hi(buffer)
        ld a, (hl)
        ld (@rotozoom+1), a

        add ix, bc
        add iy, de
        
        ld a, iyh
        and 0xf0
        ld l, a
        ld a, ixh
        rrca
        rrca
        rrca
        rrca
        and 0x0f
        or l
        ld l, a
        ld h, hi(buffer)
        ld a, (hl)
        ld l, a
@rotozoom:
        ld h,0x00

        push hl
        
        add ix, bc
        add iy, de
rend
    exx
@sp_backup equ $+1
    ld  sp,0x0000
    add hl,bc
    exx

    ei

    ld hl,(@u0)
    scf
    ccf
    sbc hl,de
    ld (@u0),hl

    ld hl,(@v0)
    add hl,bc
    ld (@v0),hl

    ex af,af'
    dec a
    jp nz,.loop_y

    ld hl,@zoom
    inc (hl)    

    exx
    dec de
    ld a,d
    or e
    exx
    jp nz,rotoloop
    ret


mul:
    ld d, sqr2_lo>>8
    ld e,l
         
    ld b,0
    ld c,a

    ld h, sqr1_lo>>8
    add hl,bc

    ex de, hl

    xor 0xff
    ld c,a
    add hl,bc

    ld a,(de)
    inc d
    inc d
    ld c,(hl)
    inc h
    inc h
    
    sub c
    ld c,a

    ld a,(de)
    ld b,(hl)
    
    sbc b
    ld b,a
        
    ret

frame:
    defb 0
    defw 0

; clear screen animation -------------------------------------------------------
fill_screen:
    ld iy, SCREEN_HEIGHT
    ld ix, 0xd000+SCREEN_WIDTH

fill_screen.loop
    ld bc, 0
    
fill_line:

    ld hl, vblnk
    ld a, 0x7f
.wait_2:
    cp (hl)
    jp nc, .wait_2
.wait_3:
    cp (hl)
    jp c, .wait_3

    di

    ld (transition_sp_save), sp

    ld sp, ix
    
    ld hl, histogram.attr
    add hl, bc
    ld a, (hl)
    ld h, a
    ld l, a

    repeat SCREEN_WIDTH/2
    push hl
    rend
        
    ld hl, 0x800+SCREEN_WIDTH
    add hl, sp
    ld sp, hl
    
fill_color equ $+1
    ld hl, histogram.color
    add hl, bc
    ld a, (hl)
    ld h, a
    ld l, a
    repeat SCREEN_WIDTH/2
    push hl
    rend
    
transition_sp_save equ $+1
    ld sp, 0x0000

    ei
        
    inc c
    ld a, 7
    cp c
    jp nz, fill_line

    ld de,SCREEN_WIDTH
    add ix,de
    
    dec iyl
    jp nz, fill_screen.loop
    
    ret

histogram.color:
    defb 0x70,0x70,0x70,0x07,0x07,0x07,0x77
histogram.attr:
    defb 0x70,0x36,0x7a,0x7e,0x3e,0x3c,0x7a
histogram.white:
    defb 0x71,0x71,0x71,0x17,0x17,0x17,0x77
histogram.red:
    defb 0x21,0x21,0x21,0x12,0x12,0x12,0x22
histogram.blue:
    defb 0x01,0x01,0x01,0x10,0x10,0x10,0x00
histogram.black:
    defb 0x01,0x01,0x01,0x10,0x10,0x10,0x00

press_space:
    defb 0x10,0x12,0x05,0x13,0x13,0x00,0x00,0x13,0x10,0x01,0x03,0x05

gfx_fill:
    ld a, 25
.l0:
    ld l, 4
.l1:
    ld (@gfx_fill.save), sp
    di
    
    ld sp, ix
    ld bc, 10
    add ix, bc
    
    pop bc  
    pop de
    exx
    pop hl
    pop bc
    pop de
    
    ld sp, iy
    push de
    push bc
    push hl
    exx
    push de
    push bc

    ld bc,  10
    add iy, bc

@gfx_fill.save equ $+1
    ld sp, 0x0000
    ei
    
    dec l
    jp nz, .l1

    ld bc, -80
    add iy, bc
    
    dec a
    jp nz, .l0

    ret

border8_fill:
    
    ld a, 25
.loop:
    ld (@b8sp_save), sp
    di
    
    ld sp, iy
    ld bc, 8
    add iy, bc   

    pop bc
    pop de
    
    exx
    pop bc
    pop de
    
    ld sp, ix
    push de
    push bc
    
    exx
    push de
    push bc

@b8sp_save equ $+1
    ld sp, 0x0000
    ei

    ld bc, -40
    add ix, bc
        
    dec a
    jp nz, .loop

    ret

player: include "PlayerLightweight_SHARPMZ700.asm"
song: include "data/music.asm"

_irq_vector:
    di

    push af
    push hl
    push bc
    push de
    push ix
    push iy
    exx
    push af
    push hl
    push bc
    push de
    push ix
    push iy
    
    ld hl, 0xe006
    ld a,1
    ld (hl), a
    xor a
    ld (hl), a
    
    call PLY_LW_Play        
    
    pop iy
    pop ix
    pop de
    pop bc
    pop hl
    pop af
    exx
    pop iy
    pop ix
    pop de
    pop bc
    pop hl
    pop af

    ei
    reti

rotozoom.index defb 0

align 256
cos_table:
repeat 256, i
    defb 63 * cos(i * 360 / 256) + 63
rend

sin_table:
repeat 256, i
    defb 63 * sin(i * 360 / 256) + 63
rend

sqr1_lo:
i = 0
while i<512
    m = (i*i) / 4
    defb lo(m)
    i = i+1
wend

sqr1_hi:
i = 0
while i<512
    m = (i*i) / 4
    defb hi(m)
    i = i+1
wend

sqr2_lo:
i = 0
while i<512
    m = ((255 - i) * (255 - i)) / 4;
    defb lo(m)
    i = i+1
wend

sqr2_hi:
i = 0
while i<512
    m = ((255 - i) * (255 - i)) / 4;
    defb hi(m)
    i = i+1
wend

border00:
    incbin "./data/border00.bin"
border01:
    incbin "./data/border01.bin"
border02:
    incbin "./data/border02.bin"
border03:
    incbin "./data/border03.bin"
border04:
    incbin "./data/border04.bin"
border05:
    incbin "./data/border05.bin"
border06:
    incbin "./data/border06.bin"
border07:
    incbin "./data/border07.bin"

border:
    defw border00, border01, border02, border03
    defw border04, border05, border06, border07 

gfx.000:
    incbin "data/gfx00.bin"
    include "bitmap.asm"

align 256
rotozoom.gfx:
    incbin "data/star.bin", 0, 256
    incbin "data/santa.bin", 0, 256
    incbin "data/frost.bin", 0, 256
    incbin "data/socks.bin", 0, 256
    incbin "data/gifts.bin", 0, 256
    incbin "data/homealone.bin", 0, 256
    incbin "data/grinch.bin", 0, 256
    incbin "data/bozo.bin", 0, 256

; put buffer at the end (we don't need to transfer empty space)
buffer:
