macro raster_update    
    ld sp, ix
    pop bc
    pop de
    pop hl
    exx
    pop bc
    pop de
    pop hl
    
    ld sp, iy
    push hl
    push de
    push bc
    exx
    push hl
    push de
    push bc
    
    ld bc, 12
    add ix, bc
mend

display_bitmap:
    ld (.sp_save), sp

    ld iy, 0xd000+27
    ld  bc, 40

    ld a, att_height
@draw_attributes:
    ld sp, iy

    ld hl, 0x3b3b
    push hl
    push hl
    push hl
    push hl
    push hl
    push hl

    add iy, bc

	dec a
	jp nz, @draw_attributes

.run:
    ld hl, vblnk
    ld a, 0x7f
@waitb:
    cp (hl)
    jp nc, @waita
@waita:
    cp (hl)
    jp c, @waitb

    xor a
@loop:
    ld iy, 0xd800+27
.text equ $+2
    ld ix, 0x0000

    raster_update
    
    ld hl, vblnk
    ld a, 0x7f
@wait0:
    cp (hl)
    jp nc, @wait0

    ld a, 25
    jp @line01
    
@line00:
    raster_update
@line01:
    raster_update
@line02:
    raster_update
@line03:
    raster_update
@line04:
    raster_update
@line05:
    raster_update
@line06:
    raster_update
@line07:
    raster_update   

    ld  c, 40
    add iy, bc

	dec a
	jp nz, @line00
    
    ld iy, 0xd800+27

    raster_update
    
    ld hl, vblnk
    ld a, 0x7f
@wait1:
    cp (hl)
    jp nc, @wait1

    ld a, 25
    jp @line11
    
@line10:
    raster_update
@line11:
    raster_update
@line12:
    raster_update
@line13:
    raster_update
@line14:
    raster_update
@line15:
    raster_update
@line16:
    raster_update
@line17:
    raster_update   

    ld  c, 40
    add iy, bc

	dec a
	jp nz, @line10

    ld hl, frame
    dec (hl)
    jp nz, @loop

    inc hl
    dec (hl)
    jp nz, @loop
   
.sp_save equ $+1
    ld sp, 0x0000

    ret
    
txt_width = 12
txt_height = 200

att_width = 12
att_height = 25
