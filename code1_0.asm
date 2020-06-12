.586
DATA SEGMENT USE16
WIN_LEFT DB 17,2,5,18,35
WIN_RIGHT DB 17,2,43,18,73 
WIN_LEFT_UP DB 1,2,5,18,35
WIN_RIGHT_UP DB 1,2,43,18,73
winnum DB 0
OLD0B DD ?    ;�洢ϵͳ0BH�ж�����
FLAG DB 0      ;��־λ
CONT DB 0
CURSE_LEFT DB 2,5
CURSE_RIGHT DB 2,42
lx	db 2    ;win1��ǰ���λ��
ly	db 5
rx	db 2    ;win2��ǰ���λ��
ry	db 42
DATA ENDS

CODE SEGMENT USE16
	 ASSUME CS:CODE,DS:DATA
BEG: MOV AX,DATA
	 MOV DS,AX
	 ;����
	 ;CALL CLEAR
	 ;�����󴰿ڲ���
	 MOV BX,OFFSET WIN_LEFT
	 CALL SCROLL
	 ;�����Ҵ��ڲ���
	 MOV BX,OFFSET WIN_RIGHT
	 CALL SCROLL
	 MOV BX,OFFSET CURSE_LEFT
	 CALL POS_CURSE
	 CLI			;���ж�
	 CALL I8250		;�����ڳ�ʼ��
	 CALL I8259		;����8259A�������ж�
	 CALL RD0B		;����0BH�ж�����
	 CALL WR0B	    ;�û�0BH�ж�����
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
	 CALL RESET    ;�ָ�ϵͳ0BH�ж�����
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
	  CMP AL,01  
	  JE NEXT
	  ;���������display,������������ʾ�����Ҵ���
	  ;CALL DISPLAY1
	  CALL DISPLAY 
	  CALL Beep ;������Ϣ��ʾ��
	  JMP EXIT
NEXT: MOV FLAG,-1
EXIT: MOV AL,20H
 	  OUT 20H,AL
 	  POP DS
 	  POP DX
 	  POP AX
	  IRET    ;�жϷ���
RECEIVE ENDP

DISPLAY1 PROC
	MOV AH,2	   ;����"esc",��ʾ�ַ�����Ļ��
	MOV DL,AL
	INT 21H
	RET
DISPLAY1 ENDP

DISPLAY PROC
    ;��ʾ������Ļ
	MOV AH,2	   ;����"esc",��ʾ�ַ�����Ļ��
	MOV DL,AL
	INT 21H
	INC ry 
    CMP ry,73
	JLE change_ry
change_line_r:
	MOV ry,43
	INC rx
	CMP rx,18
	JLE change_rx
	MOV BX,OFFSET WIN_RIGHT_UP
	CALL SCROLL
	MOV rx,18
change_rx:
    MOV BL,rx
    MOV CURSE_RIGHT[0],BL
change_ry:
	MOV BL,ry
	MOV CURSE_RIGHT[1],BL
	MOV BX,OFFSET CURSE_RIGHT
	CALL POS_CURSE
	;��ʾ������Ļ
display_right:
	MOV AH,2	   ;����"esc",��ʾ�ַ�����Ļ��
	MOV DL,AL
	INT 21H
    INC ly
    CMP ly,35
	JLE change_ly
change_line_l:	
	MOV ly,5
	INC lx
	CMP lx,18
	JLE change_lx
	MOV BX,OFFSET WIN_LEFT_UP
	CALL SCROLL
	MOV lx,18
change_lx:
    MOV BL,lx
    MOV CURSE_LEFT[0],BL
change_ly:
	MOV BL,ly
	MOV CURSE_LEFT[1],BL
	MOV BX,OFFSET CURSE_LEFT
	CALL POS_CURSE
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
	  MOV AL,00011000B  ;D4=1�ڻ��Լ�,   D3=1�����ж�, D4=0����ͨ��
	  OUT DX,AL
	  RET     ;���ڷ���
I8250 ENDP

;������8259�������ж�  D3λ
I8259 PROC
	  IN AL,21H
	  AND AL,11110111B
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
	 
	 
RESET PROC
	  IN AL,21H
	  OR AL,00001000B    ;���ж����μĴ����ĸ������ж���������1���ر�8259�������ж�
	  OUT 21H,AL
	  MOV AX,250BH
	  MOV DX,WORD PTR OLD0B
	  MOV DS,WORD PTR OLD0B+2
	  INT 21H
	  RET	;���ڷ���
RESET ENDP

CLEAR PROC ;����
	MOV AH,6
	MOV AL,0
	MOV BH,7
	MOV CH,0
	MOV CL,0
    MOV DH,24
	MOV DL,79
	INT 10H
	RET	;���ڷ���
CLEAR ENDP

SCROLL PROC ;��ʾ����
	  MOV AH,6
	  MOV AL,[BX]  ;�Ͼ�����
	  MOV CH,[BX + 1] ;���Ͻ��к�
	  MOV CL,[BX + 2] ;���Ͻ��к�
	  MOV DH,[BX + 3] ;���Ͻ��к�
	  MOV DL,[BX + 4] ;���Ͻ��к�
	  MOV BH,14H
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












