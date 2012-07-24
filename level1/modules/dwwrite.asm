*******************************************************
*
* DWWrite
*    Send a packet to the DriveWire server.
*    Serial data format:  1-8-N-1
*    4/12/2009 by Darren Atkinson
*
* Entry:
*    X  = starting address of data to send
*    Y  = number of bytes to send
*
* Exit:
*    X  = address of last byte sent + 1
*    Y  = 0
*    All others preserved
*

          IFNE  atari
* Atari SIO Version
* Based on the hipatch source for the Atari and translated
* into 6809 assembly language by Boisy G. Pitre.
*
RMSEND    equ       %11101111
SKSEND    equ       %00100011
MSKSEND   equ       %00010000
IMSEND    equ       %00010000
IMSCPL    equ       $08
DWWrite
          andcc     #^$01               ; clear carry to assume no error
          pshs      d,cc
; setup pokey
          lda       #$28
          sta       AUDCTL
*          lda       #$A0
          lda       #$A8
          sta       AUDC4
* short delay before send
          clra
shortdelay@
          deca
          bne       shortdelay@
          orcc      #$50                ; mask interrupts
          lda	     #SKSEND        	; set pokey to transmit data mode
          sta	     SKCTL
          sta	     SKRES
          lda       D.IRQENSHDW
          ora       #MSKSEND
          sta       IRQEN
          lda       ,x+
          sta       SEROUT
          leay      -1,y
          beq       ex@
byteloop@
          lda       ,x+
          ldb       #IMSEND
* NOTE: Potential infinite loop here!
waitloop@
          bitb      IRQST
          bne       waitloop@
          ldb       #RMSEND
          stb       IRQEN
          ldb       D.IRQENSHDW
          orb       #MSKSEND
          stb       IRQEN
          sta       SEROUT
          leay      -1,y
          bne       byteloop@
ex@
          lda       #IMSCPL
wt        bita      IRQST	; wait until transmit complete
          bne       wt
          puls      cc,d,pc

          ELSE
          IFNE BECKER

DWWrite   pshs      d,cc              ; preserve registers
          orcc      #$50                ; mask interrupts
;          ldu       #BBOUT              ; point U to bit banger out register
;          lda       3,u                 ; read PIA 1-B control register
;          anda      #$f7                ; clear sound enable bit
;          sta       3,u                 ; disable sound output
;          fcb       $8c                 ; skip next instruction

txByte    
          lda       ,x+                
          sta       $FF42
          leay      -1,y                ; decrement byte counter
          bne       txByte              ; loop if more to send

          puls      cc,d,pc           ; restore registers and return


          ELSE
          IFNE H6309-1
*******************************************************
* 57600 (115200) bps using 6809 code and timimg
*******************************************************

DWWrite   pshs      dp,d,cc             ; preserve registers
          orcc      #$50                ; mask interrupts
          ldd       #$04ff              ; A = loop counter, B = $ff
          tfr       b,dp                ; set direct page to $FFxx
          setdp     $ff
          ldb       <$ff23              ; read PIA 1-B control register
          andb      #$f7                ; clear sound enable bit
          stb       <$ff23              ; disable sound output
          fcb       $8c                 ; skip next instruction

txByte    stb       <BBOUT              ; send stop bit
          ldb       ,x+                 ; get a byte to transmit
          nop
          lslb                          ; left rotate the byte two positions..
          rolb                          ; ..placing a zero (start bit) in bit 1
tx0020    stb       <BBOUT              ; send bit (start bit, d1, d3, d5)
          rorb                          ; move next bit into position
          exg       a,a
          nop
          stb       <BBOUT              ; send bit (d0, d2, d4, d6)
          rorb                          ; move next bit into position
          leau      ,u
          deca                          ; decrement loop counter
          bne       tx0020              ; loop until 7th data bit has been sent

          stb       <BBOUT              ; send bit 7
          ldd       #$0402              ; A = loop counter, B = MARK value
          leay      ,-y                 ; decrement byte counter
          bne       txByte              ; loop if more to send

          stb       <BBOUT              ; leave bit banger output at MARK
          puls      cc,d,dp,pc          ; restore registers and return
          setdp     $00

          ELSE
          IFNE BAUD38400
*******************************************************
* 38400 bps using 6809 code and timimg
*******************************************************

DWWrite   pshs      u,d,cc              ; preserve registers
          orcc      #$50                ; mask interrupts
          ldu       #BBOUT              ; point U to bit banger out register
          lda       3,u                 ; read PIA 1-B control register
          anda      #$f7                ; clear sound enable bit
          sta       3,u                 ; disable sound output
          fcb       $8c                 ; skip next instruction

txByte    stb       ,--u                ; send stop bit
          leau      ,u+
          lda       #8                  ; counter for start bit and 7 data bits
          ldb       ,x+                 ; get a byte to transmit
          lslb                          ; left rotate the byte two positions..
          rolb                          ; ..placing a zero (start bit) in bit 1
tx0010    stb       ,u++                ; send bit
          tst       ,--u
          rorb                          ; move next bit into position
          deca                          ; decrement loop counter
          bne       tx0010              ; loop until 7th data bit has been sent
          leau      ,u
          stb       ,u                  ; send bit 7
          lda       ,u++                
          ldb       #$02                ; value for stop bit (MARK)
          leay      -1,y                ; decrement byte counter
          bne       txByte              ; loop if more to send

          stb       ,--u                ; leave bit banger output at MARK
          puls      cc,d,u,pc           ; restore registers and return


          ELSE
          IFNE H6309-1
*******************************************************
* 57600 (115200) bps using 6809 code and timimg
*******************************************************

DWWrite   pshs      dp,d,cc             ; preserve registers
          orcc      #$50                ; mask interrupts
          ldd       #$04ff              ; A = loop counter, B = $ff
          tfr       b,dp                ; set direct page to $FFxx
          setdp     $ff
          ldb       <$ff23              ; read PIA 1-B control register
          andb      #$f7                ; clear sound enable bit
          stb       <$ff23              ; disable sound output
          fcb       $8c                 ; skip next instruction

txByte    stb       <BBOUT              ; send stop bit
          ldb       ,x+                 ; get a byte to transmit
          nop
          lslb                          ; left rotate the byte two positions..
          rolb                          ; ..placing a zero (start bit) in bit 1
tx0020    stb       <BBOUT              ; send bit (start bit, d1, d3, d5)
          rorb                          ; move next bit into position
          exg       a,a
          nop
          stb       <BBOUT              ; send bit (d0, d2, d4, d6)
          rorb                          ; move next bit into position
          leau      ,u
          deca                          ; decrement loop counter
          bne       tx0020              ; loop until 7th data bit has been sent

          stb       <BBOUT              ; send bit 7
          ldd       #$0402              ; A = loop counter, B = MARK value
          leay      ,-y                 ; decrement byte counter
          bne       txByte              ; loop if more to send

          stb       <BBOUT              ; leave bit banger output at MARK
          puls      cc,d,dp,pc          ; restore registers and return
          setdp     $00


          ELSE
*******************************************************
* 57600 (115200) bps using 6309 native mode
*******************************************************

DWWrite   pshs      u,d,cc              ; preserve registers
          orcc      #$50                ; mask interrupts
*         ldmd      #1                  ; requires 6309 native mode
          ldu       #BBOUT+1            ; point U to bit banger out register +1
          aim       #$f7,2,u            ; disable sound output
          lda       #8                  ; counter for start bit and 7 data bits
          fcb       $8c                 ; skip next instruction

txByte    stb       -1,u                ; send stop bit
tx0010    ldb       ,x+                 ; get a byte to transmit
          lslb                          ; left rotate the byte two positions..
          rolb                          ; ..placing a zero (start bit) in bit 1
          bra       tx0030

tx0020    bita      #1                  ; even or odd bit number ?
          beq       tx0040              ; branch if even (15 cycles)
tx0030    nop                           ; extra (16th) cycle
tx0040    stb       -1,u                ; send bit
          rorb                          ; move next bit into position
          deca                          ; decrement loop counter
          bne       tx0020              ; loop until 7th data bit has been sent
          leau      ,u+
          stb       -1,u                ; send bit 7
          ldd       #$0802              ; A = loop counter, B = MARK value
          leay      -1,y                ; decrement byte counter
          bne       txByte              ; loop if more to send

          stb       -1,u                ; final stop bit
          puls      cc,d,u,pc           ; restore registers and return


          ENDC
          ENDC
          ENDC
          ENDC
          ENDC
