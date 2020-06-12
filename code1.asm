.586
DATA SEGMENT USE16
WIN_LEFT DB 2,2,5,3,35
WIN_RIGHT DB 2,2,43,3,73 
WIN_LEFT_UP DB 1,2,5,3,35
WIN_RIGHT_UP DB 1,2,43,3,73
winnum DB 1
OLD0B DD ?    ;存储系统0BH中断向量
FLAG DB 0      ;标志位
CONT DB 0
CURSE_LEFT DB 2,5
CURSE_RIGHT DB 2,43
lx	db 2    ;win1当前光标位置
ly	db 5
rx	db 2    ;win2当前光标位置
ry	db 43

SHOW DB 0AH,0DH
     DB 17 DUP(' '),'sender',16 DUP(' '),'*',16 DUP(' '),'reciver',0AH,0DH,'$'
DATA ENDS 
CODE SEGMENT USE16
	 ASSUME CS:CODE,DS:DATA
BEG: MOV AX,DATA
	 MOV DS,AX
	 ;清屏
	 CALL CLEAR
	 LEA SI,SHOW
	 MOV DX,SI
	 MOV AH,09H
	 INT 21H
	 ;设置左窗口参数
	 MOV BX,OFFSET WIN_LEFT
	 CALL SCROLL
	 ;设置右窗口参数
	 MOV BX,OFFSET WIN_RIGHT
	 CALL SCROLL
	 MOV BX,OFFSET CURSE_LEFT
	 CALL POS_CURSE
	 CLI			;关中断
	 CALL I8250		;辅串口初始化
	 CALL I8259		;开放8259A辅串口中断
	 CALL RD0B		;保存0BH中断向量
	 CALL WR0B	    ;置换0BH中断向量
	 STI			;开中断
SCANT:
	 CMP FLAG,-1    
	 JE RETURN
	 MOV DX,2FDH	;查询发送保持寄存器
	 IN AL,DX
	 TEST AL,20H
	 JZ SCANT
	 MOV AH,1	;查询键盘缓冲区
	 INT 16H
	 JZ SCANT
	 MOV AH,0	;读取键盘缓冲区的内容 ASCII->AL
	 INT 16H
	 AND AL,7FH
	 MOV DX,2F8H 
	 OUT DX,AL
     CMP AL,1BH
     JNE SCANT
TWAIT:
	 MOV DX,2FDH
	 IN AL,DX
	 TEST AL,40H   ;测试一帧是否发送完
	 JZ TWAIT
RETURN:            ;当一帧发送完则执行结束程序
	 CALL RESET    ;恢复系统0BH中断向量
	 MOV AH,4CH
	 INT 21H

;接收中断服务子程序
RECEIVE PROC
	  PUSH AX
	  PUSH DX
	  PUSH DS
	  MOV AX,DATA
	  MOV DS,AX
	  MOV DX,2F8H  ;读取接收缓冲区的内容
	  IN  AL,DX
	  AND AL,7FH
	  ;检查是否为左键
	  CMP AL,4BH
	  JNE is_win_right
	  MOV BL,lx
	  MOV CURSE_LEFT[0],BL
	  MOV BL,ly
	  MOV CURSE_LEFT[1],BL
	  MOV BX,OFFSET CURSE_LEFT
	  CALL POS_CURSE
	  MOV winnum,1
	  JMP EXIT
is_win_right:
      ;检查是否为右键
      CMP AL,4DH
      JNE is_ESC
      MOV BL,rx
      MOV CURSE_RIGHT[0],BL
      MOV BL,ry
      MOV CURSE_RIGHT[1],BL
      MOV BX,OFFSET CURSE_RIGHT
      CALL POS_CURSE
      MOV winnum,2
      JMP EXIT
is_ESC:
      ;判断是否是'esc'
	  CMP AL,01  
	  JE NEXT
	  ;不是则调用display,将键盘输入显示在左右窗口
	  CALL DISPLAY 
	  CALL Beep ;接收信息提示音
	  JMP EXIT
NEXT: MOV FLAG,-1
EXIT: MOV AL,20H
 	  OUT 20H,AL
 	  POP DS
 	  POP DX
 	  POP AX
	  IRET    ;中断返回
RECEIVE ENDP

DISPLAY PROC
    CMP winnum,1
    JNE WINNUM2
    ;显示在左屏幕
	MOV AH,2	   ;不是"esc",显示字符在屏幕上
	MOV DL,AL
	INT 21H
	;显示在右屏幕
	MOV BL,ry
	MOV CURSE_RIGHT[1],BL
	MOV BL,rx
	MOV CURSE_RIGHT[0],BL
	MOV BX,OFFSET CURSE_RIGHT
	CALL POS_CURSE
	MOV AH,2	   ;不是"esc",显示字符在屏幕上
	MOV DL,AL
	INT 21H
	INC ry 
    CMP ry,73
	JLE change_ry
	MOV ry,43
	INC rx
	MOV BL,WIN_RIGHT[3]
	CMP rx,BL
	JLE change_rx
	MOV BX,OFFSET WIN_RIGHT_UP
	CALL SCROLL
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
    INC ly
    CMP ly,35
	JLE change_ly
	MOV ly,5
	INC lx
	MOV BL,WIN_LEFT[3]
	CMP lx,BL
	JLE change_lx
	MOV BX,OFFSET WIN_LEFT_UP
	CALL SCROLL
	MOV BL,WIN_LEFT[3]
	MOV lx,BL
change_lx:
    MOV BL,lx
    MOV CURSE_LEFT[0],BL
change_ly:
	MOV BL,ly
	MOV CURSE_LEFT[1],BL
	MOV BX,OFFSET CURSE_LEFT
	CALL POS_CURSE
	JMP THE_END
WINNUM2:
	;显示在右屏幕
	MOV AH,2	   ;不是"esc",显示字符在屏幕上
	MOV DL,AL
	INT 21H
	INC ly 
    CMP ly,35
	JLE change_ly_2
	MOV ly,5
	INC lx
	MOV BL,WIN_LEFT[3]
	CMP lx,BL
	JLE change_lx_2
	MOV BX,OFFSET WIN_LEFT_UP
	CALL SCROLL
	MOV BL,WIN_LEFT[3]
	MOV lx,BL
change_lx_2:
    MOV BL,lx
    MOV CURSE_LEFT[0],BL
change_ly_2:
	MOV BL,ly
	MOV CURSE_LEFT[1],BL
	MOV BX,OFFSET CURSE_LEFT
	CALL POS_CURSE
	;显示在左屏幕
	MOV AH,2	   ;不是"esc",显示字符在屏幕上
	MOV DL,AL
	INT 21H
    INC ry
    CMP ry,73
	JLE change_ry_2
	MOV ry,43
	INC rx
	MOV BL,WIN_RIGHT[3]
	CMP rx,BL
	JLE change_rx_2
	MOV BX,OFFSET WIN_RIGHT_UP
	CALL SCROLL
	MOV BL,WIN_RIGHT[3]
	MOV rx,BL
change_rx_2:
    MOV BL,rx
    MOV CURSE_RIGHT[0],BL
change_ry_2:
	MOV BL,ry
	MOV CURSE_RIGHT[1],BL
	MOV BX,OFFSET CURSE_RIGHT
	CALL POS_CURSE
THE_END:
	RET
DISPLAY ENDP

Beep PROC
	PUSH BX
	PUSH AX
	PUSH DX
	MOV AX,0  ;120000H被除数
	MOV DX,12H
	MOV BX,1048  
	DIV BX       ;计算频率值
	MOV BX,AX
	MOV AL,10110110B ;设置定时器工作方式
    OUT 43H,AL
  
    MOV AX,BX            
    OUT 42H,AL   ;设置计数器低8位
  
    MOV AL,AH    ;设置计数器高8位
    OUT 42H,AL
  
    IN AL,61H     ;打开与门
    OR AL,03H
    OUT 61H,AL
    CALL DELAY
    IN AL,61H     ;关闭与门
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

;初始化8250
I8250 PROC
	  MOV DX,2FBH    ;寻址为置1
	  MOV AL,80H
	  OUT DX,AL
	  MOV DX,2F9H	 ;写除数寄存器高8位
	  MOV AL,0
	  OUT DX,AL
	  MOV DX,2F8H	 ;写除数寄存器低8位,波特率为1200
	  MOV AL,60H
	  OUT DX,AL
	  MOV DX,2FBH  	 ;写帧数据格式:8数据为,1停止位,无校验位	 
	  MOV AL,03H
	  OUT DX,AL
	  MOV DX,2F9H 	 ;允许8250内部提出中断	
	  MOV AL,01H
	  OUT DX,AL
	  MOV DX,2FCH
	  MOV AL,00011000B  ;D4=1内环自检,   D3=1开放中断, D4=0正常通信
	  OUT DX,AL
	  RET     ;段内返回
I8250 ENDP

;开放主8259辅串口中断  D3位
I8259 PROC
	  IN AL,21H
	  AND AL,11110111B
	  OUT 21H,AL
	  RET     ;段内返回
I8259 ENDP

RD0B PROC
	  MOV AX,350BH
	  INT 21H
	  MOV WORD PTR OLD0B,BX
	  MOV WORD PTR OLD0B+2,ES
	  RET   ;段内返回
RD0B ENDP

WR0B PROC
	  PUSH DS
	  MOV AX,CODE
	  MOV DS,AX
	  MOV DX,OFFSET RECEIVE
	  MOV AX,250BH
	  INT 21H
	  POP DS
	  RET	;段内返回
WR0B ENDP
	 
	 
RESET PROC
	  IN AL,21H
	  OR AL,00001000B    ;将中断屏蔽寄存器的辅串口中断屏蔽字置1，关闭8259辅串口中断
	  OUT 21H,AL
	  MOV AX,250BH
	  MOV DX,WORD PTR OLD0B
	  MOV DS,WORD PTR OLD0B+2
	  INT 21H
	  RET	;段内返回
RESET ENDP

CLEAR PROC ;清屏
	MOV AH,6
	MOV AL,0
	MOV BH,7
	MOV CH,0
	MOV CL,0
    MOV DH,24
	MOV DL,79
	INT 10H
	RET	;段内返回
CLEAR ENDP

SCROLL PROC ;显示窗口
	  MOV AH,6 ;向上滚动窗口
	  MOV AL,[BX]  ;上卷行数
	  MOV CH,[BX + 1] ;左上角行号
	  MOV CL,[BX + 2] ;左上角列号
	  MOV DH,[BX + 3] ;右上角行号
	  MOV DL,[BX + 4] ;右上角列号
	  MOV BH,3EH  ;背景颜色和字符颜色
	  INT 10H
	  RET	;段内返回
SCROLL ENDP

POS_CURSE PROC
	MOV DH,[BX]
	MOV DL,[BX+1]
	MOV BH,0
	MOV AH,2
	INT 10H
	RET  ;段内返回
POS_CURSE ENDP

CODE ENDS
	 END BEG


