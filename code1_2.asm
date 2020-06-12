.586
DATA SEGMENT USE16
	EOF=065
	SHOW DB 0AH,0DH
     	 DB 17 DUP(' '),'sender',16 DUP(' '),'*',16 DUP(' '),'reciver',0AH,0DH,'$'
	WIN_LEFT DB 18,3,5,20,35
	WIN_RIGHT DB 13,3,43,15,73 
	WIN_LEFT_UP DB 1,3,5,20,35
	WIN_RIGHT_UP DB 1,3,43,15,73
	FILE_OUT_UP DB 1,17,43,22,73
	BUTTON DB 1,22,5,22,10
	FILE_TEXT DB 1,22,12,22,35
	FILE_OUT DB 6,17,43,22,73
	winnum DB 1
	OLD0B DD ?    ;�洢ϵͳ0BH�ж�����
	OLD74 DD ?
	FLAG DB 0      ;��־λ
	CONT DB 0
	CURSE_LEFT DB 3,5
	CURSE_RIGHT DB 3,43
	CURSE_BUTTON DB 22,6
	CURSE_TEXT DB 22,12
	CURSE_MOUSE DB 22,12
	CURSE_FILEOUT DB 17,43
	lx	db 3    ;win1��ǰ���λ��
	ly	db 5
	rx	db 3    ;win2��ǰ���λ��
	ry	db 43
	FX DB 17
	FY DB 43
	FILE DB 'file$'
	COLOR DB 0
	WIN_COLOR DB 3EH
	FILE_COLOR DB 63H
	;FILE_NAME DB 20 DUP(?)
	HANDLE DW ?
	FNAME  DB '2.txt',0;�ļ��� 
	ERROR1 DB 'File not found',07H,0,'$' ;��ʾ��Ϣ 
	ERROR2 DB 'Reading error',07H,0,'$' 
	BUFFER DB ?                  
	FILE_NAME DB 20
			  DB ?
			  DB 20 DUP(?)
DATA ENDS 
CODE SEGMENT USE16
	 ASSUME CS:CODE,DS:DATA
BEG: 
	MOV AX,DATA
	MOV DS,AX
	CALL UI_DESIGN
RESTART:
	CLI			;���ж�
	CALL I8250		;�����ڳ�ʼ��
	CALL I8259		;����8259A�������ж�
	CALL RD0B		;����0BH�ж�����
	CALL WR0B	    ;�û�0BH�ж�����
	CALL RD74
	CALL WR74
	STI			;���ж�
SCANT:
	CMP FLAG,-1    
	JE RETURN
	MOV DX,2FDH	;��ѯ���ͱ��ּĴ���
	IN AL,DX
	TEST AL,20H
	JZ SCANT
	MOV AH,1	;��ѯ���̻�����
	INT 16H
	JZ SCANT
	MOV AH,0	;��ȡ���̻����������� ASCII->AL
	INT 16H
	AND AL,7FH
	MOV DX,2F8H 
	OUT DX,AL
	CMP AL,1BH
	JNE SCANT
TWAIT:
	MOV DX,2FDH
	IN AL,DX
	TEST AL,40H   ;����һ֡�Ƿ�����
	JZ TWAIT
RETURN:            ;��һ֡��������ִ�н�������
	CALL RESET    ;�ָ�ϵͳ0BH��74H�ж�����
	MOV AH,4CH
	INT 21H

;�����жϷ����ӳ���
RECEIVE PROC
	PUSH AX
	PUSH DX
    PUSH DS
    MOV AX,DATA
    MOV DS,AX 
	MOV DX,2F8H  ;��ȡ���ջ�����������
    IN  AL,DX
	AND AL,7FH
    ;�ж��Ƿ���'esc'
	CMP AL,01  
	JE NEXT
	;���������display,������������ʾ�����Ҵ���
	CALL DISPLAY
	CALL Beep ;������Ϣ��ʾ��
	JMP EXIT
NEXT: MOV FLAG,-1
EXIT: 
	MOV AL,20H
	OUT 20H,AL
 	POP DS
	POP DX
	POP AX
	IRET    ;�жϷ���
RECEIVE ENDP

DISPLAY PROC
    CMP AL,0DH
    JZ NEXT_LINE
   ;��ʾ������Ļ
	MOV AH,2	   ;����"esc",��ʾ�ַ�����Ļ��
	MOV DL,AL
	INT 21H
	;��ʾ������Ļ
	MOV BL,ry
	MOV CURSE_RIGHT[1],BL
	MOV BL,rx
	MOV CURSE_RIGHT[0],BL
	MOV BX,OFFSET CURSE_RIGHT
	CALL POS_CURSE
	MOV AH,2
	MOV DL,AL
	INT 21H
	;���¹��y����Ϣ+1
	INC ry
	;����Ƿ���
    CMP ry,73
	JLE change_ry
	;����
	MOV ry,43
	INC rx
	;����Ƿ񴰿��Ͼ�
	MOV BL,WIN_RIGHT[3]
	CMP rx,BL
	JLE change_rx
	;�����Ͼ�
	MOV BX,OFFSET WIN_RIGHT_UP
	MOV CL,WIN_COLOR
	MOV COLOR,CL
	CALL SCROLL
	;��rxΪ���һ��
	MOV BL,WIN_RIGHT[3]
	MOV rx,BL
change_rx:
    MOV BL,rx
    MOV CURSE_RIGHT[0],BL
change_ry:
	MOV BL,ry
	MOV CURSE_RIGHT[1],BL
	MOV BX,OFFSET CURSE_RIGHT
	CALL POS_CURSE
	;�����������λ����Ϣ
    INC ly
    CMP ly,35
	JLE change_ly
	MOV ly,5
	INC lx
	MOV BL,WIN_LEFT[3]
	CMP lx,BL
	JLE change_lx
	MOV BX,OFFSET WIN_LEFT_UP
	MOV CL,WIN_COLOR
	MOV COLOR,CL
	CALL SCROLL
	MOV BL,WIN_LEFT[3]
	MOV lx,BL
change_lx:
    MOV BL,lx
    MOV CURSE_LEFT[0],BL
change_ly:
	MOV BL,ly
	MOV CURSE_LEFT[1],BL
	;�������������������ƶ���굽����
	MOV BX,OFFSET CURSE_LEFT
	CALL POS_CURSE
	JMP THE_END
NEXT_LINE:
    MOV ry,43
	INC rx
	;����Ƿ񴰿��Ͼ�
	MOV BL,WIN_RIGHT[3]
	CMP rx,BL
	JLE change_rx_1
	;�����Ͼ�
	MOV BX,OFFSET WIN_RIGHT_UP
	MOV CL,WIN_COLOR
	MOV COLOR,CL
	CALL SCROLL
	;��rxΪ���һ��
	MOV BL,WIN_RIGHT[3]
	MOV rx,BL
change_rx_1:
    MOV BL,rx
    MOV CURSE_RIGHT[0],BL
	MOV BL,ry
	MOV CURSE_RIGHT[1],BL
	MOV BX,OFFSET CURSE_RIGHT
	CALL POS_CURSE
	;�����������λ����Ϣ
	MOV ly,5
	INC lx
	MOV BL,WIN_LEFT[3]
	CMP lx,BL
	JLE change_lx_1
	MOV BX,OFFSET WIN_LEFT_UP
	MOV CL,WIN_COLOR
	MOV COLOR,CL
	CALL SCROLL
	MOV BL,WIN_LEFT[3]
	MOV lx,BL
change_lx_1:
    MOV BL,lx
    MOV CURSE_LEFT[0],BL
	MOV BL,ly
	MOV CURSE_LEFT[1],BL
	;�������������������ƶ���굽����
	MOV BX,OFFSET CURSE_LEFT
	CALL POS_CURSE
THE_END:
	RET
DISPLAY ENDP

Beep PROC
	PUSH BX
	PUSH AX
	PUSH DX
	MOV AX,0  ;120000H������
	MOV DX,12H
	MOV BX,1048  
	DIV BX       ;����Ƶ��ֵ
	MOV BX,AX
	MOV AL,10110110B ;���ö�ʱ��������ʽ
    OUT 43H,AL
  
    MOV AX,BX            
    OUT 42H,AL   ;���ü�������8λ
  
    MOV AL,AH    ;���ü�������8λ
    OUT 42H,AL
  
    IN AL,61H     ;������
    OR AL,03H
    OUT 61H,AL
    CALL DELAY
    IN AL,61H     ;�ر�����
    AND AL,0FCH
    OUT 61H,AL
    POP DX
    POP AX
    POP BX
    RET
Beep ENDP

DELAY  PROC
  	PUSH CX
	MOV CX,05H;
DELAYLOOP1: 
  	PUSH CX
  	MOV CX,0FFFFH;
DELAYLOOP2:
  	LOOP DELAYLOOP2
  	POP CX
  	LOOP DELAYLOOP1
  	POP CX
  	RET
DELAY ENDP

SERVER PROC ;����ж��ӳ���
	PUSHA
	PUSH DS
	MOV AX,DATA
	MOV DS,AX
	MOV AX,0  ;��ʼ�����
    INT 33H
    MOV AX,1  ;��ʾ���
    INT 33H
  	MOV AX,03H  ;������������ȡ���λ�ü��䰴ť״̬
	INT 33H		;��ڲ�����AX��03H
				;���ڲ�����BX������״̬��λ0=1�����������
				;λ1=1���������Ҽ�
				;λ2=1���������м�
				;����λ�����������ڲ�ʹ��
				;CX��ˮƽλ��
				;DX����ֱλ��
	MOV BL,08H
	MOV AX,CX
	DIV BL
	MOV CL,AL ;��������Ϣ
	MOV AX,DX
	DIV BL
	MOV CH,AL ;��������Ϣ
	MOV BX,OFFSET CURSE_MOUSE ;POS_CURSE��FILE�������ı���
	CALL POS_CURSE  
  	;CMP DX,19   ;�������Ƿ��ڣ�19��12�������
  	;JNZ EXIT
  	;CMP CX,5
  	;JC EXIT
  	;CMP CX,10
  	;JA EXIT
  	;MOV BX,OFFSET CURSE_MOUSE
	;MOV [BX],CH
	;MOV [BX+1],CL
  	;CALL POS_CURSE
  	CALL GET_FILENAME
  	MOV BX,OFFSET CURSE_FILEOUT
	CALL POS_CURSE
  	CALL SHOW_IN_WIN_RIGHT
  	MOV BX,OFFSET CURSE_LEFT
	CALL POS_CURSE
	JMP RESTART
EXIT:
	MOV AL,20H  ;����8259Aд������
	OUT 20H,AL
	POP DS
	POPA
	IRET
SERVER ENDP

GET_FILENAME PROC
	MOV AX,DATA
	MOV DS,AX
	MOV AH,0AH
	MOV DX,OFFSET FILE_NAME
	INT 21H
	MOV BL,FILE_NAME+1
	MOV BH,0
	MOV SI,OFFSET FILE_NAME+2
	MOV BYTE PTR [BX+SI],'$'
	RET
GET_FILENAME ENDP

SHOW_IN_WIN_RIGHT PROC
	MOV AX,DATA
    MOV DS,AX                                                ;�����ݶμĴ��� 
    MOV DX,OFFSET FILE_NAME+2
    MOV AX,3D00H            ;��ָ���ļ� 
    INT 21H
    JNC OPEN_OK             ;�򿪳ɹ���ת 
    MOV SI,OFFSET ERROR1                        ;��ʾ�򿪲��ɹ���ʾ��Ϣ 
    CALL DMESS 
    JMP OVER
OPEN_OK:
	MOV HANDLE,AX                                        ;�����ļ���

READFILE:  
    MOV BX,HANDLE
    CALL READCH                                        ;���ļ��ж�һ���ַ� 
    JC READERR                                        ;���������ת 
    CMP AL,EOF                                        ;�����ļ��������� 
    JZ TYPE_OK                                       ;�ǣ�ת 
	MOV AH,09H
    CALL PUTCH                                        ;��ʾ�����ַ� 
    JMP READFILE                                                ;���� 
READERR:
	MOV SI,OFFSET ERROR2 
    CALL DMESS 
TYPE_OK:
	MOV AH,3EH 
	INT 21H 
OVER:   
	RET
SHOW_IN_WIN_RIGHT ENDP

READCH   PROC 
	MOV CX,1 
	MOV DX,OFFSET BUFFER                ;�û�������ַ 
	MOV AH,3FH                                        ;�ù��ܵ��ú� 
	INT 21H                                                ;�� 
	JC READCH2                                        ;������ת 
	CMP AX,CX                                        ;���ļ��Ƿ���� 
	MOV AL,EOF                                        ;���ļ��Ѿ�����,���ļ�������     
	JB READCH1                                        ;�ļ�ȷ�ѽ�����ת 
	MOV AL,BUFFER                                ;�ļ�δ������ȡ�����ַ�
	MOV DX,3F8H;���̻������ַ��浽8259A���ͱ��ּĴ���
	OUT DX,AL 
READCH1:CLC 
READCH2:RET 
READCH ENDP

DMESS PROC 
DMESS1:
	MOV DL,[SI] 
	INC SI 
	OR DL,DL 
	JZ DMESS2 
	MOV AH,2 
	INT 21H
	INC FY
    CMP FY,73
	JLE change_FY
	MOV FY,43
	INC FX
	MOV BL,FILE_OUT[3]
	CMP FX,BL
	JLE change_FX
	MOV BX,OFFSET FILE_OUT_UP
	MOV CL,FILE_COLOR
	MOV COLOR,CL
	CALL SCROLL
	MOV BL,FILE_OUT[3]
	MOV FX,BL
change_FX:
    MOV BL,FX
    MOV CURSE_FILEOUT[0],BL
change_FY:
	MOV BL,FY
	MOV CURSE_FILEOUT[1],BL
	MOV BX,OFFSET CURSE_FILEOUT
	CALL POS_CURSE 
	JMP DMESS1 
DMESS2:
		RET 
DMESS ENDP

PUTCH PROC
    PUSH DX
    ;MOV DX,3F8H;��ȡ���ջ�����8259A���ջ���Ĵ���������
    ;IN AL,DX
    ;MOV DL,AL 
    ;MOV AH,2
    ;INT 21H
    INC FY
    CMP FY,73
	JLE change_FY
	MOV FY,43
	INC FX
	MOV BL,FILE_OUT[3]
	CMP FX,BL
	JLE change_FX
	MOV BX,OFFSET FILE_OUT_UP
	MOV CL,FILE_COLOR
	MOV COLOR,CL
	CALL SCROLL
	MOV BL,FILE_OUT[3]
	MOV FX,BL
change_FX:
    MOV BL,FX
    MOV CURSE_FILEOUT[0],BL
change_FY:
	MOV BL,FY
	MOV CURSE_FILEOUT[1],BL
	MOV BX,OFFSET CURSE_FILEOUT
	CALL POS_CURSE
    POP DX
    RET 
PUTCH ENDP 

;��ʼ��8250
I8250 PROC
	MOV DX,2FBH    ;ѰַΪ��1
	MOV AL,80H
	OUT DX,AL
	MOV DX,2F9H	 ;д�����Ĵ�����8λ
	MOV AL,0
	OUT DX,AL
	MOV DX,2F8H	 ;д�����Ĵ�����8λ,������Ϊ1200
	MOV AL,60H
	OUT DX,AL
	MOV DX,2FBH  	 ;д֡���ݸ�ʽ:8����Ϊ,1ֹͣλ,��У��λ	 
	MOV AL,03H
	OUT DX,AL
	MOV DX,2F9H 	 ;����8250�ڲ�����ж�	
	MOV AL,01H
	OUT DX,AL
	MOV DX,2FCH
	MOV AL,00011000B  ;D4=1�ڻ��Լ�, D3=1�����ж�, D4=0����ͨ��
	OUT DX,AL
	RET     ;���ڷ���
I8250 ENDP

;������8259�������ж�  D3λ
I8259 PROC
	IN AL,0A1H  
	AND AL,11101111B	;��8259AIR4��0 ���Ŵ�8259A�ı����ж�IR4
	OUT 0A1H,AL
	IN AL,21H  
	AND AL,11110011B  ;��8259AIR2��IR3��0 ���Ÿ������ж�IR3�����Դ�8259A���ж�IR2
	OUT 21H,AL
	RET     ;���ڷ���
I8259 ENDP

RD0B PROC
	MOV AX,350BH
	INT 21H
	MOV WORD PTR OLD0B,BX
	MOV WORD PTR OLD0B+2,ES
	RET   ;���ڷ���
RD0B ENDP

WR0B PROC
	PUSH DS
	MOV AX,CODE
	MOV DS,AX
	MOV DX,OFFSET RECEIVE
	MOV AX,250BH
	INT 21H
	POP DS
	RET	;���ڷ���
WR0B ENDP

RD74 PROC
	MOV AX,3574H
	INT 21H
	MOV WORD PTR OLD74,BX
	MOV WORD PTR OLD74,ES
	RET
RD74 ENDP

WR74 PROC
	PUSH DS
	MOV AX,CODE
	MOV DS,AX
	MOV DX,OFFSET SERVER
	MOV AX,2574H
	INT 21H
	POP DS
	RET
WR74 ENDP

RESET PROC
	IN AL,21H
	OR AL,00001100B    ;���ж����μĴ����ĸ������ж���������1���ر�8259�������жϺ�IMR2��8259A
	OUT 21H,AL
	MOV AX,250BH
	MOV DX,WORD PTR OLD0B
	MOV DS,WORD PTR OLD0B+2
	INT 21H
	MOV DX,WORD PTR OLD74
	MOV DS,WORD PTR OLD74+2
	INT 21H
	RET	;���ڷ���
RESET ENDP

CLEAR PROC ;����
	MOV AH,6 ;���Ϲ�������
	MOV AL,0 ;
	MOV BH,7 ;������ɫ��������ɫ
	MOV CH,0 ;������
	MOV CL,0 ;������
    MOV DH,24 ;������
	MOV DL,79 ;������
	INT 10H 
	RET	;���ڷ���
CLEAR ENDP

UI_DESIGN PROC
	;����
	CALL CLEAR
	LEA SI,SHOW
	MOV DX,SI
	MOV AH,09H
	INT 21H
	;�����󴰿ڲ���
	MOV BX,OFFSET WIN_LEFT
	MOV CL,WIN_COLOR
	MOV COLOR,CL
	CALL SCROLL
	;�����Ҵ��ڲ���
	MOV BX,OFFSET WIN_RIGHT
	CALL SCROLL
	;���ð�ť����
	MOV BX,OFFSET BUTTON
	MOV CL,FILE_COLOR
	MOV COLOR,CL
	CALL SCROLL
	;����fileBUTTONs
	MOV BX,OFFSET CURSE_BUTTON
	CALL POS_CURSE
	MOV DX,OFFSET FILE
	MOV AH,9
	INT 21H
	;����file_text
	MOV BX,OFFSET FILE_TEXT
	CALL SCROLL
	;�����ļ���ʾ��
	MOV BX,OFFSET FILE_OUT
	CALL SCROLL
	;���ó�ʼ���λ��
	MOV BX,OFFSET CURSE_LEFT
	CALL POS_CURSE
	RET
UI_DESIGN ENDP

SCROLL PROC ;��ʾ����
	MOV AH,6 ;���Ϲ�������
	MOV AL,[BX]  ;�Ͼ�����
	MOV CH,[BX + 1] ;���Ͻ��к�
	MOV CL,[BX + 2] ;���Ͻ��к�
	MOV DH,[BX + 3] ;���Ͻ��к�
	MOV DL,[BX + 4] ;���Ͻ��к�
	MOV BH,COLOR;������ɫ���ַ���ɫ ��ɫ�����ͻ�ɫ����
	INT 10H
	RET	;���ڷ���
SCROLL ENDP

POS_CURSE PROC
	MOV DH,[BX]
	MOV DL,[BX+1]
	MOV BH,0
	MOV AH,2
	INT 10H
	RET  ;���ڷ���
POS_CURSE ENDP

CODE ENDS
	 END BEG

















