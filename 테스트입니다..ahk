; ==========================================================
; 현재 어댑터 자동 감지 + 기존 DNS/게이트웨이/서브넷 유지
; IP 주소만 변경하는 오토핫키 스크립트
; Made by ChatGPT
; ==========================================================

#Requires AutoHotkey v1.1+

; 관리자 권한으로 재실행
if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

; --- 어댑터 자동 감지 ---
; netsh 명령으로 IP가 있는 어댑터 중 첫 번째를 찾음
RunWait, %ComSpec% /C netsh interface ip show config > "%A_Temp%\netinfo.txt",, Hide
FileRead, NetInfo, %A_Temp%\netinfo.txt"

; 어댑터 이름 추출
RegExMatch(NetInfo, "인터페이스\s+(.+?)\r\n", name)
Adapter := RegExReplace(name1, "[\r\n]")

; 혹시 영어 윈도우라면 아래 줄로 대체 가능:
; RegExMatch(NetInfo, "Configuration for interface\s+""([^""]+)""", name)
; Adapter := name1

; --- GUI 생성 ---
Gui, Add, Text,, 감지된 어댑터 이름:
Gui, Add, Edit, vAdapterName w250, %Adapter%

Gui, Add, Text,, 새 IP 주소:
Gui, Add, Edit, vNewIP w200

Gui, Add, Button, gChangeIP w100, IP 변경
Gui, Show,, IP 변경 도우미
Return

; --- IP 변경 버튼 ---
ChangeIP:
Gui, Submit, NoHide

; --- 현재 설정 정보 가져오기 ---
RunWait, %ComSpec% /C netsh interface ip show config name="%AdapterName%" > "%A_Temp%\netcfg.txt",, Hide
FileRead, NetInfo, %A_Temp%\netcfg.txt"

; --- 기본값 초기화 ---
Gateway := ""
Subnet := ""
DNS1 := ""
DNS2 := ""

; --- 게이트웨이 추출 ---
RegExMatch(NetInfo, "기본 게이트웨이:\s+(\d+\.\d+\.\d+\.\d+)", gw)
Gateway := gw1

; --- 서브넷 추출 ---
RegExMatch(NetInfo, "서브넷 접두사:\s+\d+\.\d+\.\d+\.\d+/(\d+)", sm)
if (sm1)
{
    maskBits := sm1
    mask := ""
    Loop, 4
    {
        if (maskBits >= 8)
            octet := 255
        else if (maskBits > 0)
            octet := 256 - 2**(8 - maskBits)
        else
            octet := 0
        mask .= octet ((A_Index < 4) ? "." : "")
        maskBits -= 8
    }
    Subnet := mask
}

; --- DNS 추출 ---
; 정적 DNS가 설정된 경우
RegExMatch(NetInfo, "DNS 서버:\s+(\d+\.\d+\.\d+\.\d+)", d1)
RegExMatch(NetInfo, "DNS 서버:[\s\S
